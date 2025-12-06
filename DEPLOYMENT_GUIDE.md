# 🚀 NTIL REBUS-GROK Deployment Guide

## ✅ Implementation Complete: A + B + C

### A) Syft + Cosign in CI/CD ✅
- **GitHub Actions Workflow** (`.github/workflows/deploy.yml`)
  - Builds backend & frontend images
  - Automatically signs images with Cosign (keyless signing via Sigstore)
  - Generates CycloneDX SBOMs for supply chain transparency
  - Uploads artifacts for audit trail

### B) Service Health Checks + Rollback ✅
- **PowerShell Deploy Script Enhanced** (`deploy/scripts/deploy.ps1`)
  - Post-deployment health checks on both services
  - Automatic rollback if services unhealthy
  - Max 10 attempts with 3-second intervals
  - Production-only: will revert to previous version on failure

### C) Monitoring Stack (Prometheus + Grafana) ✅
- **Kubernetes Manifests** (`deploy/kubernetes/monitoring-stack.yaml`)
  - Prometheus server scraping all pods in `rebus` & `monitoring` namespaces
  - Grafana with pre-configured Prometheus datasource
  - ServiceAccount + RBAC for secure access
  - LoadBalancer service for Grafana UI

---

## 🔧 Setup Instructions

### 1. **Enable GitHub Actions Secrets**

Go to: `Settings → Secrets and variables → Actions`

Add these secrets:

```
KUBECONFIG_FILE
  → Paste your kubeconfig as base64 or raw text
```

### 2. **Deploy Monitoring Stack**

```bash
kubectl apply -f deploy/kubernetes/monitoring-stack.yaml
```

Verify:
```bash
kubectl get all -n monitoring
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

Open: `http://localhost:3000` (admin/admin)

### 3. **Instrument Your Backend**

Update `backend/pom.xml`:
```xml
<!-- Add these dependencies -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

Update `backend/src/main/resources/application.yml`:
```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  metrics:
    export:
      prometheus:
        enabled: true
```

### 4. **Update Kubernetes Deployment**

Ensure your `rebus-backend` deployment has:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/actuator/prometheus"

spec:
  livenessProbe:
    httpGet:
      path: /actuator/health
      port: 8080
    initialDelaySeconds: 30
    periodSeconds: 10
  readinessProbe:
    httpGet:
      path: /actuator/health/readiness
      port: 8080
    initialDelaySeconds: 10
    periodSeconds: 5
```

---

## 📊 First Deployment Workflow

### Staging (Automatic on `git push origin main`):

1. GitHub Actions builds images
2. Syft generates SBOMs
3. Cosign signs images (keyless via Sigstore)
4. Images pushed to `ghcr.io/noveratech2025-a11y/ntil-rebus-grok-*`
5. docker-compose restarts services
6. Health checks verify deployment

### Production (Manual tag trigger):

```bash
git tag v1.0.0
git push origin v1.0.0
```

Then:
1. GitHub Actions builds & signs images
2. kubectl updates deployments
3. Monitors rollout status
4. **NEW:** Health checks verify services
5. **NEW:** Auto-rollback on failure
6. **NEW:** Prometheus scrapes metrics
7. **NEW:** View dashboards in Grafana

---

## 🎯 Grafana Dashboard Setup

After logging in to Grafana:

1. **Add Datasource**
   - Already configured → skip
   - Or manually: Settings → Data Sources → Add Prometheus
   - URL: `http://prometheus:9090`

2. **Create Dashboard**
   - New → Create → Dashboard
   - Add Panel with queries:
     - `rate(http_requests_total[5m])` → Request Rate
     - `http_request_duration_seconds_bucket` → Response Time
     - `container_memory_usage_bytes` → Memory
     - `container_cpu_usage_seconds_total` → CPU

3. **Or Import Pre-built**
   - Dashboard → Import
   - Dashboard ID: `1860` (Node Exporter)
   - Dashboard ID: `3662` (Prometheus)

---

## 🔒 Security Checklist

- ✅ **Image Signing:** Cosign signs all images (keyless via Sigstore)
- ✅ **SBOM Generation:** CycloneDX reports for supply chain transparency
- ✅ **Health Checks:** Services verified before considering deployment successful
- ✅ **Auto-Rollback:** Failed deployments automatically revert
- ✅ **RBAC:** Prometheus/Grafana have least-privilege service accounts
- ✅ **Observability:** All metrics scraped for auditing

---

## 📋 Next Steps

After first successful production deployment:

1. ✅ Create Grafana dashboards for alerting
2. ✅ Add AlertManager for critical metrics
3. ✅ Implement log aggregation (ELK / Loki)
4. ✅ Add distributed tracing (Jaeger / Tempo)
5. ✅ Set up SLOs (Service Level Objectives)

---

## 🆘 Troubleshooting

**Grafana not loading dashboards?**
```bash
kubectl logs -n monitoring deployment/grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

**Prometheus not scraping metrics?**
```bash
kubectl logs -n monitoring deployment/prometheus
# Check: http://localhost:9090/targets
```

**Rollback triggered unexpectedly?**
```bash
kubectl rollout history deployment/rebus-backend -n rebus
kubectl rollout undo deployment/rebus-backend -n rebus --to-revision=1
```

**Images not signed?**
- Ensure cosign.key exists locally or Sigstore keyless is enabled
- Check GitHub Actions workflow for sign step logs

---

**Questions? Check logs:**
```bash
# Workflow logs
gh run list --repo noveratech2025-a11y/STARKTANK
gh run view <RUN_ID> --log

# Deployment logs
kubectl logs -n rebus deployment/rebus-backend
kubectl logs -n monitoring deployment/prometheus
```
