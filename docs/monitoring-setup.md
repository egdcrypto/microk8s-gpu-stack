# Monitoring Setup Guide

## Overview

This guide covers setting up Prometheus and Grafana for comprehensive monitoring of your MicroK8s cluster, including GPU metrics.

## Installation

### 1. Add Prometheus Helm Repository

```bash
sudo microk8s helm3 repo add prometheus-community https://prometheus-community.github.io/helm-charts
sudo microk8s helm3 repo update
```

### 2. Install Prometheus Stack

```bash
# Create monitoring namespace
sudo microk8s kubectl create namespace monitoring

# Install kube-prometheus-stack
sudo microk8s helm3 install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values /home/repos/k8s-setup/monitoring/prometheus-values.yaml
```

### 3. Apply Additional Monitoring Resources

```bash
sudo microk8s kubectl apply -f /home/repos/k8s-setup/monitoring/monitoring-stack.yaml
```

## Accessing Services

### Grafana

```bash
# Port forward Grafana
sudo microk8s kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Access at http://localhost:3000
# Default credentials: admin / changeme
```

### Prometheus

```bash
# Port forward Prometheus
sudo microk8s kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Access at http://localhost:9090
```

### AlertManager

```bash
# Port forward AlertManager
sudo microk8s kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093

# Access at http://localhost:9093
```

## Grafana Dashboards

### Pre-installed Dashboards

1. **Kubernetes Cluster Overview**: Overall cluster health
2. **Node Exporter**: Detailed node metrics
3. **NVIDIA GPU Dashboard**: GPU utilization and metrics

### Importing Additional Dashboards

1. Go to Grafana → Dashboards → Import
2. Enter dashboard ID or paste JSON
3. Select Prometheus as data source

Recommended dashboards:
- 12239: NVIDIA DCGM Exporter Dashboard
- 15172: Kubernetes Cluster Monitoring
- 11074: Node Exporter for Prometheus
- 10000: Kubernetes Cluster Autoscaler

## Prometheus Queries

### Useful PromQL Queries

```promql
# CPU usage percentage
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# GPU utilization
DCGM_FI_DEV_GPU_UTIL

# GPU memory usage
DCGM_FI_DEV_FB_USED / DCGM_FI_DEV_FB_FREE * 100

# Pod restart count
increase(kube_pod_container_status_restarts_total[1h])

# PVC usage
(kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes) * 100
```

## Alert Configuration

### Email Alerts

Edit AlertManager configuration:

```yaml
# /home/repos/k8s-setup/monitoring/alertmanager-config.yaml
receivers:
- name: 'email-notifications'
  email_configs:
  - to: 'admin@example.com'
    from: 'alerts@example.com'
    smarthost: 'smtp.gmail.com:587'
    auth_username: 'alerts@example.com'
    auth_password: 'your-app-password'
```

### Slack Alerts

```yaml
receivers:
- name: 'slack-notifications'
  slack_configs:
  - api_url: 'YOUR_SLACK_WEBHOOK_URL'
    channel: '#alerts'
    title: 'Kubernetes Alert'
```

### Custom Alerts

Add to `/home/repos/k8s-setup/monitoring/monitoring-stack.yaml`:

```yaml
- alert: HighPodCPU
  expr: sum(rate(container_cpu_usage_seconds_total[5m])) by (pod) > 0.8
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Pod {{ $labels.pod }} high CPU usage"
    description: "Pod {{ $labels.pod }} CPU usage is above 80%"
```

## Monitoring Best Practices

### 1. Resource Allocation

Ensure monitoring components have sufficient resources:

```yaml
resources:
  requests:
    cpu: 500m
    memory: 2Gi
  limits:
    cpu: 2000m
    memory: 8Gi
```

### 2. Data Retention

Configure appropriate retention periods:

```yaml
prometheus:
  prometheusSpec:
    retention: 30d  # Adjust based on storage capacity
    retentionSize: 90GB
```

### 3. Scrape Intervals

Balance between data granularity and resource usage:

```yaml
global:
  scrape_interval: 30s      # Default
  evaluation_interval: 30s
```

### 4. Storage Performance

Use fast storage for Prometheus:

```yaml
storageSpec:
  volumeClaimTemplate:
    spec:
      storageClassName: fast-ssd
```

## Custom Metrics

### Application Metrics

Expose custom metrics from your applications:

```python
# Python example with prometheus_client
from prometheus_client import Counter, Histogram, Gauge, start_http_server

# Define metrics
request_count = Counter('app_requests_total', 'Total requests')
request_latency = Histogram('app_request_latency_seconds', 'Request latency')
active_users = Gauge('app_active_users', 'Active users')

# Use in your application
@request_latency.time()
def process_request():
    request_count.inc()
    # Your logic here

# Start metrics server
start_http_server(8000)
```

### ServiceMonitor for Custom Metrics

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: app-metrics
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: your-app
  endpoints:
  - port: metrics
    interval: 30s
```

## Troubleshooting

### Prometheus Not Scraping Targets

```bash
# Check service discovery
sudo microk8s kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Go to http://localhost:9090/targets

# Check ServiceMonitor
sudo microk8s kubectl get servicemonitor -n monitoring
```

### High Memory Usage

1. Reduce retention period
2. Increase scrape intervals
3. Use recording rules for complex queries
4. Enable compression

### Missing Metrics

```bash
# Check if exporter is running
sudo microk8s kubectl get pods -n monitoring

# Check exporter logs
sudo microk8s kubectl logs -n monitoring <exporter-pod>

# Verify network policies
sudo microk8s kubectl get networkpolicies -n monitoring
```

## Performance Optimization

### 1. Recording Rules

Create recording rules for frequently used queries:

```yaml
groups:
- name: node_rules
  interval: 30s
  rules:
  - record: instance:node_cpu:rate5m
    expr: 100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100)
```

### 2. Downsampling

For long-term storage, consider using Thanos for downsampling.

### 3. Federation

For multi-cluster setups, use Prometheus federation:

```yaml
- job_name: 'federate'
  scrape_interval: 15s
  honor_labels: true
  metrics_path: '/federate'
  params:
    'match[]':
    - '{job="prometheus"}'
    - '{__name__=~"job:.*"}'
  static_configs:
  - targets:
    - 'prometheus-cluster-b:9090'
```

## Integration with Other Tools

### Logging (Loki)

```bash
sudo microk8s helm3 install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set prometheus.enabled=false
```

### Tracing (Jaeger)

```bash
sudo microk8s kubectl create namespace tracing
sudo microk8s kubectl apply -n tracing -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.53.0/jaeger-operator.yaml
```

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Kubernetes Monitoring Guide](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/)