#!/bin/bash
set -e

echo "MicroK8s Cluster Setup Script"
echo "============================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        echo "✓ $1 completed successfully"
    else
        echo "✗ $1 failed"
        exit 1
    fi
}

# Start MicroK8s if not running
echo "Starting MicroK8s..."
microk8s start
check_status "MicroK8s start"

# Wait for MicroK8s to be ready
echo "Waiting for MicroK8s to be ready..."
microk8s status --wait-ready
check_status "MicroK8s ready check"

# Enable essential addons
echo "Enabling essential addons..."
microk8s enable dns hostpath-storage ingress
check_status "Essential addons"

# Enable GPU support if NVIDIA GPU is present
if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU detected, enabling GPU support..."
    microk8s enable gpu
    check_status "GPU addon"
fi

# Enable additional addons
echo "Enabling additional addons..."
microk8s enable metrics-server
check_status "Metrics server"

# Apply namespaces
echo "Creating namespaces..."
microk8s kubectl apply -f /home/repos/k8s-setup/namespaces/namespaces.yaml
check_status "Namespace creation"

# Apply resource quotas
echo "Applying resource quotas..."
microk8s kubectl apply -f /home/repos/k8s-setup/namespaces/resource-quotas.yaml
check_status "Resource quota application"

# Apply storage classes
echo "Creating storage classes..."
microk8s kubectl apply -f /home/repos/k8s-setup/storage/storage-classes.yaml
check_status "Storage class creation"

# Install cert-manager for SSL certificates
echo "Installing cert-manager..."
microk8s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml
sleep 30  # Wait for cert-manager to be ready
check_status "Cert-manager installation"

# Apply cert-manager issuers
echo "Creating certificate issuers..."
microk8s kubectl apply -f /home/repos/k8s-setup/ingress/cert-manager.yaml
check_status "Certificate issuer creation"

echo ""
echo "✓ MicroK8s cluster setup completed!"
echo ""
echo "Next steps:"
echo "1. Update ingress examples with your domain names"
echo "2. Install Prometheus/Grafana monitoring stack (see monitoring/README.md)"
echo "3. Deploy your applications"
echo ""
echo "Useful commands:"
echo "  microk8s status        - Check cluster status"
echo "  microk8s kubectl       - Run kubectl commands"
echo "  microk8s dashboard-proxy - Access Kubernetes dashboard"