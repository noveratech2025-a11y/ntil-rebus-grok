#!/bin/bash
# NTIL REBUS-GROK Deployment Script

set -e

ENVIRONMENT=$1
REGISTRY="ghcr.io"
REPO_OWNER="YOUR_USERNAME"  # Change to your GitHub username
REPO_NAME="ntil-rebus-grok"
IMAGE_BACKEND="$REGISTRY/$REPO_OWNER/$REPO_NAME/backend:latest"
IMAGE_FRONTEND="$REGISTRY/$REPO_OWNER/$REPO_NAME/frontend:latest"

echo "🚀 Deploying NTIL REBUS-GROK to $ENVIRONMENT..."

case $ENVIRONMENT in
  staging)
    echo "📦 Deploying to Staging..."
    
    # Pull latest images
    docker pull $IMAGE_BACKEND
    docker pull $IMAGE_FRONTEND
    
    # Generate SBOM with Syft
    echo "📋 Generating Software Bill of Materials..."
    syft "$IMAGE_BACKEND" -o cyclonedx > sbom-backend.xml
    syft "$IMAGE_FRONTEND" -o cyclonedx > sbom-frontend.xml
    echo "✅ SBOM generated: sbom-backend.xml, sbom-frontend.xml"
    
    # Sign images with Cosign
    echo "🔐 Signing container images..."
    cosign sign --key cosign.key "$IMAGE_BACKEND"
    cosign sign --key cosign.key "$IMAGE_FRONTEND"
    echo "✅ Container images signed"
    
    # Update services using docker-compose
    docker compose -f deploy/docker-compose.yml up -d
    
    echo "✅ Staging deployment complete"
    echo "Backend: http://localhost:8080"
    echo "Frontend: http://localhost:3000"
    ;;
    
  production)
    echo "📦 Deploying to Production..."
    
    # Verify critical services are running
    echo "Checking prerequisites..."
    if ! command -v kubectl &> /dev/null; then
      echo "❌ kubectl not found. Install Kubernetes CLI tools."
      exit 1
    fi
    
    # Generate SBOM with Syft
    echo "📋 Generating Software Bill of Materials..."
    syft "$IMAGE_BACKEND" -o cyclonedx > sbom-backend.xml
    syft "$IMAGE_FRONTEND" -o cyclonedx > sbom-frontend.xml
    echo "✅ SBOM generated: sbom-backend.xml, sbom-frontend.xml"
    
    # Sign images with Cosign
    echo "🔐 Signing container images..."
    cosign sign --key cosign.key "$IMAGE_BACKEND"
    cosign sign --key cosign.key "$IMAGE_FRONTEND"
    echo "✅ Container images signed"
    
    # Apply Kubernetes manifests
    echo "Applying Kubernetes manifests..."
    kubectl apply -f deploy/kubernetes/
    
    # Wait for rollout
    echo "Waiting for deployment to complete..."
    kubectl rollout status deployment/rebus-backend -n rebus --timeout=5m
    kubectl rollout status deployment/rebus-frontend -n rebus --timeout=5m
    
    echo "✅ Production deployment complete"
    kubectl get services -n rebus
    ;;
    
  *)
    echo "❌ Invalid environment. Use 'staging' or 'production'"
    exit 1
    ;;
esac

echo "✨ Deployment script complete!"
