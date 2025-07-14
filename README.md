# MicroK8s GPU Stack

A comprehensive Kubernetes setup for AI/ML workloads with GPU support, designed for development and production environments.

## 🚀 Deployed Infrastructure

✅ **Core Services:**
- **Temporal.io**: Workflow orchestration (`temporal` namespace)
- **MongoDB**: Replica set with authentication (`mongodb` namespace) 
- **Ollama**: GPU-accelerated LLM inference (`ollama` namespace)
- **Apache Pulsar**: Message streaming platform (`pulsar` namespace)
- **Docker Registry**: Local image registry with UI
- **Cert-Manager**: SSL certificate management
- **NGINX Ingress**: SSL-enabled ingress controller

✅ **External Access:**
- **Temporal UI**: http://192.168.0.118:30880
- **MongoDB**: 192.168.0.118:30017 (MongoDB Compass ready)
- **Registry UI**: http://192.168.0.118:32080
- **Pulsar Manager**: http://192.168.0.118:30527/pulsar-manager
- **Pulsar Broker**: pulsar://192.168.0.118:30650

✅ **SSL Domains (HTTPS Only):**

**Production Environment:**
- **Web**: https://www.playablestories.ai (Full production app with styling)
- **API**: https://api.playablestories.ai (Production API v1.0.0)

**Development Environment:**
- **Dev Web**: https://dev.playablestories.ai (Simple HTML placeholder)
- **Dev API**: https://dev-api.playablestories.ai (JSON status endpoint)

> **DNS Configuration**: All domains resolve to 107.194.78.98 via CNAME to egdirty.ddns.net. NAT forwards port 443 to 192.168.0.118. Let's Encrypt certificates are being issued for all subdomains.

> **Note**: If dev.playablestories.ai is not resolving externally, verify DNS propagation and NAT forwarding configuration for the development subdomain.

## Directory Structure

```
k8s-setup/
├── applications/           # Production-ready applications
│   ├── mongodb/           # MongoDB replica set with authentication
│   ├── temporal/          # Temporal.io workflow orchestration
│   ├── ollama/            # GPU-accelerated LLM inference
│   ├── pulsar/            # Apache Pulsar messaging platform
│   ├── gpu/               # GPU testing and examples
│   └── registry-ui.yaml   # Docker registry with web UI
├── domains/               # Domain-based organization
│   ├── _templates/        # Reusable templates
│   └── playablestories.ai/ # Domain-specific configs (dev/prod)
├── ingress/               # Ingress controllers and SSL
├── monitoring/            # Prometheus/Grafana stack
├── namespaces/            # Namespace definitions
├── scripts/               # Setup and maintenance scripts
├── storage/               # Storage configuration
└── docs/                  # Documentation
```

## Quick Start

### 1. Prerequisites
- Ubuntu 24.04 LTS
- MicroK8s installed with GPU support
- NVIDIA GPU with drivers
- 32GB+ RAM, 500GB+ storage

### 2. Deploy Core Infrastructure
```bash
# Apply namespaces
kubectl apply -f namespaces/namespaces.yaml

# Deploy MongoDB replica set
kubectl apply -f applications/mongodb-replica-set.yaml

# Deploy Temporal workflow engine
kubectl apply -f applications/temporal/temporal-postgres.yaml

# Deploy Ollama GPU inference
kubectl apply -f applications/ollama-gpu.yaml

# Deploy Apache Pulsar
kubectl apply -f applications/pulsar-standalone.yaml

# Deploy registry UI
kubectl apply -f applications/registry-ui.yaml

# Install cert-manager for SSL
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
kubectl apply -f ingress/cert-manager.yaml

# Deploy development environment with SSL
kubectl apply -f domains/playablestories.ai/development/namespace.yaml
kubectl apply -f domains/playablestories.ai/development/ingress-ssl.yaml
```

### 3. Verify Deployments
```bash
# Check all services
kubectl get pods --all-namespaces

# Test external access
curl http://192.168.0.118:30880  # Temporal UI
curl http://192.168.0.118:32080  # Registry UI
```

## Connection Information

### MongoDB (Production Ready)
- **External**: `192.168.0.118:30017`
- **Username**: `admin` / **Password**: `admin123`
- **Compass**: `mongodb://admin:admin123@192.168.0.118:30017/?authSource=admin&directConnection=true`

### Temporal.io
- **UI**: http://192.168.0.118:30880
- **gRPC**: `192.168.0.118:30733`

### Apache Pulsar
- **Broker**: `pulsar://192.168.0.118:30650`
- **Admin**: `http://192.168.0.118:30080`
- **Manager UI**: http://192.168.0.118:30527/pulsar-manager

### Docker Registry
- **UI**: http://192.168.0.118:32080
- **Registry**: `192.168.0.118:32000`

### SSL Domains (HTTPS + Auth)
- **Development Web**: https://dev.playablestories.ai (user: admin, pass: changeme)
- **Development API**: https://dev-api.playablestories.ai (user: admin, pass: changeme)

## Key Features

### 🔐 Security
- Generated secure passwords for all services
- Kubernetes secrets management
- Replica set authentication for MongoDB
- Keyfile-based internal authentication

### 🚀 GPU Support
- NVIDIA GPU Operator integration
- Ollama with GPU acceleration
- Resource limits and requests configured

### 📊 Observability
- Temporal workflow monitoring
- MongoDB replica set health checks
- Registry metrics and UI

### 🌐 Domain Management
- Template-based domain configuration
- Development and production environments
- Cert-manager for SSL certificates

## Operations

### Health Checks
```bash
# MongoDB status
kubectl exec -n mongodb mongodb-0 -- mongosh --eval "rs.status()"

# Temporal status  
kubectl get pods -n temporal

# GPU availability
kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPUs:.status.capacity.'nvidia\.com/gpu'
```

### Scaling
```bash
# Scale deployments
kubectl scale deployment/temporal-ui --replicas=2 -n temporal

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces
```

### Backups
```bash
# Backup persistent volumes
./scripts/backup-pvs.sh

# MongoDB backup
kubectl exec -n mongodb mongodb-0 -- mongodump --out /tmp/backup
```

## Documentation

- [MongoDB Setup](applications/mongodb/README.md)
- [Temporal Setup](applications/temporal/README.md)  
- [Apache Pulsar Setup](applications/pulsar/README.md)
- [MongoDB Compass Guide](applications/mongodb/COMPASS-SETUP.md)
- [GPU Setup Guide](docs/gpu-setup.md)
- [Domain Management](docs/playablestories-setup.md)

## Troubleshooting

### Common Issues

**MongoDB Connection**:
```bash
# Test internal connection
kubectl exec -n mongodb mongodb-0 -- mongosh --eval "rs.status()"

# Test external connection
mongosh "mongodb://admin:admin123@192.168.0.118:30017/?authSource=admin&directConnection=true"
```

**GPU Not Available**:
```bash
# Check GPU operator
kubectl get pods -n gpu-operator-resources

# Verify drivers
nvidia-smi
```

**Temporal UI 500 Error**:
```bash
# Check backend status
kubectl logs -n temporal deployment/temporal

# Restart if needed
kubectl rollout restart deployment/temporal -n temporal
```

**SSL Certificate Issues**:
```bash
# Check certificate status
kubectl get certificate -n playablestories-ai-development

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Check ClusterIssuer status (requires valid email, not example.com)
kubectl describe clusterissuer letsencrypt-prod

# Verify ACME challenges
kubectl get challenge -A
```

**Ingress Authentication Issues**:
- Remove conflicting ingress resources in other namespaces
- Ensure basic auth secrets are deleted if auth is disabled
- Restart nginx ingress controller: `kubectl delete pod -n ingress -l app=nginx-ingress-microk8s`

**External Access Issues**:
If domains are not accessible externally but work locally:
```bash
# Test local access (should work)
curl -H "Host: dev.playablestories.ai" http://localhost

# Test external connectivity (may fail if NAT issue)
telnet 107.194.78.98 443

# Verify ingress is listening on correct ports
kubectl describe daemonset nginx-ingress-microk8s-controller -n ingress | grep Port

# Check NAT/Router configuration:
# - Ensure port 443 is forwarded to 192.168.0.118:443
# - Ensure port 80 is forwarded to 192.168.0.118:80
# - Check if ISP blocks incoming connections
# - Verify router/firewall allows incoming HTTPS traffic
```

## Maintenance

### Regular Tasks
- **Daily**: Monitor cluster health with `scripts/health-check.sh`
- **Weekly**: Backup persistent volumes
- **Monthly**: Update MicroK8s and applications

### Updates
```bash
# Update MicroK8s
sudo snap refresh microk8s

# Update application images
kubectl set image deployment/temporal temporalio/auto-setup:latest -n temporal
```

## Support

For issues:
1. Check service-specific README files
2. Review troubleshooting guides
3. Check pod logs: `kubectl logs -n <namespace> <pod-name>`

---

**Last Updated**: July 2025 | **Status**: Production Ready ✅