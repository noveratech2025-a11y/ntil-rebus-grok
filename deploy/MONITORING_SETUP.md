<!-- Backend Spring Boot Actuator + Micrometer for Prometheus Metrics -->

Add to `backend/pom.xml`:

```xml
<!-- Actuator for health & metrics -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>

<!-- Micrometer for Prometheus -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

Add to `backend/src/main/resources/application.yml`:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: when-authorized
  metrics:
    export:
      prometheus:
        enabled: true

spring:
  application:
    name: rebus-backend
```

Add to your Kubernetes Deployment (`backend/deployment.yaml`):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rebus-backend
  namespace: rebus
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: rebus-backend
  template:
    metadata:
      labels:
        app: rebus-backend
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/actuator/prometheus"
    spec:
      containers:
      - name: backend
        image: ghcr.io/noveratech2025-a11y/ntil-rebus-grok-backend:latest
        ports:
        - name: http
          containerPort: 8080
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
```

Add to your Frontend Nginx config for metrics:

```nginx
# Add to `/frontend/nginx.conf`:

server {
    listen 9113;
    server_name _;
    
    location /metrics {
        default_type text/plain;
        return 200 "# Frontend metrics\nfrontend_up 1\n";
    }
}
```

Deployment Checklist:

1. ✅ Apply monitoring stack:
   ```bash
   kubectl apply -f deploy/kubernetes/monitoring-stack.yaml
   ```

2. ✅ Update backend deployment with Prometheus annotations
3. ✅ Access Grafana:
   ```bash
   kubectl port-forward -n monitoring svc/grafana 3000:3000
   # Login: admin/admin
   # Add Prometheus datasource (already configured)
   ```

4. ✅ Import pre-built dashboards:
   - Dashboard ID: 1860 (Node Exporter Full)
   - Dashboard ID: 3662 (Prometheus)
   - Dashboard ID: 11074 (Node Exporter for Prometheus)

5. ✅ Create custom dashboard for REBUS:
   - Query: `rate(http_requests_total[5m])` (Request rate)
   - Query: `http_request_duration_seconds_bucket` (Response time)
   - Query: `container_memory_usage_bytes` (Memory)
   - Query: `container_cpu_usage_seconds_total` (CPU)
