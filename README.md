# MicroK8s Kubernetes Setup

This repository contains all the necessary files and configurations to set up a production-ready MicroK8s cluster with GPU support.

## Directory Structure

```
k8s-setup/
├── namespaces/          # Namespace definitions and resource quotas
├── storage/             # Storage classes and PVC templates
├── ingress/             # Ingress configurations and cert-manager
├── monitoring/          # Prometheus and Grafana setup
├── applications/        # Example applications including GPU workloads
├── scripts/             # Setup and maintenance scripts
├── docs/                # Additional documentation
└── README.md            # This file
```

## Prerequisites

- Ubuntu 24.04 LTS
- MicroK8s installed
- NVIDIA GPU with drivers (for GPU workloads)
- At least 32GB RAM
- 500GB+ storage space

## Quick Start

1. **Initial Setup**
   ```bash
   sudo /home/repos/k8s-setup/scripts/setup-cluster.sh
   ```

2. **Verify Installation**
   ```bash
   sudo /home/repos/k8s-setup/scripts/health-check.sh
   ```

3. **Apply Sample Applications**
   ```bash
   # Create namespaces first
   sudo microk8s kubectl apply -f /home/repos/k8s-setup/namespaces/namespaces.yaml
   
   # Deploy sample web app
   sudo microk8s kubectl apply -f /home/repos/k8s-setup/applications/sample-web-app.yaml
   ```

## Key Components

### Namespaces

- **production**: Production workloads
- **staging**: Staging environment
- **development**: Development environment
- **monitoring**: Monitoring stack (Prometheus, Grafana)
- **gpu-workloads**: GPU-accelerated applications

### Storage Classes

- **standard**: Default storage class with retain policy
- **fast-ssd**: High-performance storage for databases
- **gpu-storage**: Optimized storage for GPU workloads

### Ingress

- NGINX Ingress Controller
- Cert-Manager for SSL certificates
- Example configurations for different use cases

### GPU Support

- NVIDIA GPU Operator automatically installed
- Example GPU applications:
  - Jupyter Notebook with GPU
  - LLM Inference Server (vLLM)

### Monitoring

- Prometheus for metrics collection
- Grafana for visualization
- Pre-configured dashboards and alerts
- GPU metrics monitoring

## Common Operations

### Deploy an Application

```bash
# Apply your application manifest
sudo microk8s kubectl apply -f your-app.yaml

# Check deployment status
sudo microk8s kubectl get pods -n your-namespace
```

### Access Kubernetes Dashboard

```bash
# Enable dashboard
sudo microk8s enable dashboard

# Get access token
sudo microk8s kubectl describe secret -n kube-system microk8s-dashboard-token

# Start proxy
sudo microk8s dashboard-proxy
```

### Backup Persistent Volumes

```bash
sudo /home/repos/k8s-setup/scripts/backup-pvs.sh
```

### Monitor GPU Usage

```bash
# Check GPU availability
sudo microk8s kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPUs:.status.capacity.'nvidia\.com/gpu'

# Monitor GPU metrics
nvidia-smi

# View GPU pods
sudo microk8s kubectl get pods -n gpu-operator-resources
```

### Scale Applications

```bash
# Manual scaling
sudo microk8s kubectl scale deployment/app-name --replicas=5 -n namespace

# Check HPA status
sudo microk8s kubectl get hpa -n namespace
```

## Troubleshooting

### MicroK8s Not Starting

```bash
# Check status
sudo microk8s status

# View logs
sudo journalctl -u snap.microk8s.daemon-kubelite -f

# Reset if needed
sudo microk8s reset
```

### GPU Not Detected

```bash
# Verify NVIDIA driver
nvidia-smi

# Check GPU operator pods
sudo microk8s kubectl get pods -n gpu-operator-resources

# View GPU operator logs
sudo microk8s kubectl logs -n gpu-operator-resources deployment/gpu-operator
```

### Storage Issues

```bash
# Check PV/PVC status
sudo microk8s kubectl get pv
sudo microk8s kubectl get pvc --all-namespaces

# Describe problematic PVC
sudo microk8s kubectl describe pvc pvc-name -n namespace
```

## Security Considerations

1. **Change Default Passwords**: Update all default passwords in the manifests
2. **Configure RBAC**: Set up proper role-based access control
3. **Network Policies**: Implement network policies for pod communication
4. **Secrets Management**: Use proper secret management for sensitive data
5. **Regular Updates**: Keep MicroK8s and addons updated

## Maintenance

### Daily Tasks
- Monitor cluster health: `/home/repos/k8s-setup/scripts/health-check.sh`
- Check resource usage: `sudo microk8s kubectl top nodes`

### Weekly Tasks
- Backup persistent volumes: `/home/repos/k8s-setup/scripts/backup-pvs.sh`
- Review logs and alerts
- Update applications if needed

### Monthly Tasks
- Update MicroK8s: `sudo snap refresh microk8s`
- Review and update security policies
- Clean up unused resources

## Additional Resources

- [MicroK8s Documentation](https://microk8s.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator)
- [Prometheus Operator](https://prometheus-operator.dev/)

## Support

For issues specific to this setup:
1. Check the troubleshooting section
2. Review logs using `kubectl logs`
3. Consult the official documentation

---

Last Updated: July 2025