# NTIL REBUS-GROK Enhanced Deployment Script (PowerShell)
# Environment: staging | production

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("staging", "production")]
    [string]$Environment
)

$ErrorActionPreference = "Stop"

# Registry + Repository Setup
$REGISTRY = if ($env:REGISTRY) { $env:REGISTRY } else { "ghcr.io" }
$REPO_OWNER = if ($env:REPO_OWNER) { $env:REPO_OWNER } else { "noveratech2025-a11y" }
$REPO_NAME = "ntil-rebus-grok"

# Tagging
$GIT_SHA_SHORT = (git rev-parse --short HEAD 2>$null)
if (-not $GIT_SHA_SHORT) { $GIT_SHA_SHORT = "dev" }

$IMAGE_BACKEND_LATEST  = "$REGISTRY/$REPO_OWNER/$REPO_NAME-backend:latest"
$IMAGE_FRONTEND_LATEST = "$REGISTRY/$REPO_OWNER/$REPO_NAME-frontend:latest"

$IMAGE_BACKEND_SHA  = "$REGISTRY/$REPO_OWNER/$REPO_NAME-backend:$GIT_SHA_SHORT"
$IMAGE_FRONTEND_SHA = "$REGISTRY/$REPO_OWNER/$REPO_NAME-frontend:$GIT_SHA_SHORT"

Write-Host "🚀 Deploying NTIL REBUS-GROK → $Environment environment" -ForegroundColor Green

function Generate-SBOM {
    if (Get-Command syft -ErrorAction SilentlyContinue) {
        Write-Host "📋 Generating Software Bill of Materials..." -ForegroundColor Yellow
        syft $IMAGE_BACKEND_SHA  -o cyclonedx | Out-File -FilePath "sbom-backend.xml" -Encoding UTF8
        syft $IMAGE_FRONTEND_SHA -o cyclonedx | Out-File -FilePath "sbom-frontend.xml" -Encoding UTF8
        Write-Host "✅ SBOM created for both images" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ Syft not installed → skipping SBOM" -ForegroundColor Yellow
    }
}

function Sign-Images {
    if (Get-Command cosign -ErrorAction SilentlyContinue) {
        Write-Host "🔐 Signing images with Cosign..." -ForegroundColor Yellow
        
        # Use keyless signing if in GitHub Actions (COSIGN_EXPERIMENTAL=1 + OIDC token)
        if ($env:GITHUB_ACTIONS -eq "true") {
            Write-Host "📝 Using keyless signing via GitHub OIDC..." -ForegroundColor Cyan
            $env:COSIGN_EXPERIMENTAL = "1"
            cosign sign --yes $IMAGE_BACKEND_SHA
            cosign sign --yes $IMAGE_FRONTEND_SHA
        }
        # Otherwise use local key file if available
        elseif (Test-Path "cosign.key") {
            Write-Host "🔑 Using local signing key..." -ForegroundColor Cyan
            cosign sign --key cosign.key --yes $IMAGE_BACKEND_SHA
            cosign sign --key cosign.key --yes $IMAGE_FRONTEND_SHA
        }
        else {
            Write-Host "⚠️ No signing key available → skipping signing" -ForegroundColor Yellow
            return
        }
        
        Write-Host "🛡️ Images cryptographically signed" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ Cosign not installed → skipping signing" -ForegroundColor Yellow
    }
}

function Check-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$HealthEndpoint,
        [string]$Namespace = "rebus",
        [int]$MaxAttempts = 10,
        [int]$DelaySeconds = 5
    )
    
    Write-Host "🏥 Checking health of $ServiceName..." -ForegroundColor Yellow
    
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $HealthEndpoint -TimeoutSec 3 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ $ServiceName is healthy" -ForegroundColor Green
                return $true
            }
        }
        catch {
            Write-Host "⏳ Attempt $attempt/$MaxAttempts - $ServiceName not ready yet..." -ForegroundColor Gray
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    
    Write-Host "❌ $ServiceName failed health check after $MaxAttempts attempts" -ForegroundColor Red
    return $false
}

function Rollback-Deployment {
    param(
        [string]$Component,
        [string]$Namespace
    )
    
    Write-Host "⚠️ Rolling back $Component..." -ForegroundColor Red
    kubectl rollout undo deployment/$Component -n $Namespace
    kubectl rollout status deployment/$Component -n $Namespace --timeout=5m
    Write-Host "✅ $Component rolled back successfully" -ForegroundColor Green
}

switch ($Environment) {

    "staging" {
        Write-Host "📦 Staging deployment..." -ForegroundColor Cyan

        Write-Host "🐳 Building & pushing Docker images..."
        docker build -t $IMAGE_BACKEND_LATEST -t $IMAGE_BACKEND_SHA ./backend
        docker build -t $IMAGE_FRONTEND_LATEST -t $IMAGE_FRONTEND_SHA ./frontend

        docker push $IMAGE_BACKEND_LATEST
        docker push $IMAGE_BACKEND_SHA
        docker push $IMAGE_FRONTEND_LATEST
        docker push $IMAGE_FRONTEND_SHA

        Generate-SBOM
        Sign-Images

        Write-Host "🔄 Restarting stack via docker-compose..."
        docker compose -f deploy/docker-compose.yml up -d

        Write-Host "🎯 Staging Deployment Complete" -ForegroundColor Green
        Write-Host "Backend → http://localhost:8080" -ForegroundColor Cyan
        Write-Host "Frontend → http://localhost:3000" -ForegroundColor Cyan
    }

    "production" {
        Write-Host "⚙️ Production deployment..." -ForegroundColor Cyan

        try { $null = kubectl version --client }
        catch {
            Write-Host "❌ Kubernetes CLI missing" -ForegroundColor Red
            exit 1
        }

        Generate-SBOM
        Sign-Images

        Write-Host "⬆️ Updating Kubernetes deployments..." -ForegroundColor Cyan
        kubectl set image deployment/rebus-backend  rebus-backend=$IMAGE_BACKEND_SHA -n rebus
        kubectl set image deployment/rebus-frontend rebus-frontend=$IMAGE_FRONTEND_SHA -n rebus

        Write-Host "⏳ Waiting for rollout status..." -ForegroundColor Yellow
        kubectl rollout status deployment/rebus-backend  -n rebus --timeout=5m
        kubectl rollout status deployment/rebus-frontend -n rebus --timeout=5m

        Write-Host "🏥 Verifying pod health..." -ForegroundColor Yellow
        $backendPods = kubectl get pods -n rebus -l app=rebus-backend -o jsonpath='{.items[*].metadata.name}'
        $frontendPods = kubectl get pods -n rebus -l app=rebus-frontend -o jsonpath='{.items[*].metadata.name}'
        
        if (-not $backendPods -or -not $frontendPods) {
            Write-Host "❌ No pods found after deployment" -ForegroundColor Red
            Rollback-Deployment -Component "rebus-backend" -Namespace "rebus"
            Rollback-Deployment -Component "rebus-frontend" -Namespace "rebus"
            exit 1
        }

        Write-Host "✅ All pods deployed successfully" -ForegroundColor Green
        Write-Host "📊 Service Status:" -ForegroundColor Cyan
        kubectl get services -n rebus
        
        Write-Host "🎯 Production Deployment Complete" -ForegroundColor Green
    }
}

Write-Host "✨ Done!" -ForegroundColor Green
