#!/bin/bash
set -e

# Backup script for Persistent Volumes
BACKUP_DIR="/home/backups/k8s-pvs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$TIMESTAMP"

echo "Kubernetes PV Backup Script"
echo "=========================="
echo "Backup directory: $BACKUP_PATH"

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Function to backup a PVC
backup_pvc() {
    local namespace=$1
    local pvc=$2
    local mount_path=$3
    
    echo "Backing up PVC: $namespace/$pvc"
    
    # Create a temporary pod to access the PVC
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: backup-pod-temp
  namespace: $namespace
spec:
  containers:
  - name: backup
    image: busybox
    command: ['sleep', '3600']
    volumeMounts:
    - name: data
      mountPath: $mount_path
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: $pvc
EOF

    # Wait for pod to be ready
    microk8s kubectl wait --for=condition=ready pod/backup-pod-temp -n $namespace --timeout=60s
    
    # Create backup
    microk8s kubectl exec -n $namespace backup-pod-temp -- tar czf - $mount_path > "$BACKUP_PATH/${namespace}-${pvc}.tar.gz"
    
    # Clean up
    microk8s kubectl delete pod backup-pod-temp -n $namespace --force --grace-period=0
    
    echo "✓ Backed up $pvc to $BACKUP_PATH/${namespace}-${pvc}.tar.gz"
}

# Get all PVCs
echo "Finding all PVCs..."
PVCS=$(microk8s kubectl get pvc --all-namespaces -o json | jq -r '.items[] | "\(.metadata.namespace),\(.metadata.name)"')

# Backup each PVC
for pvc_info in $PVCS; do
    IFS=',' read -r namespace pvc <<< "$pvc_info"
    backup_pvc "$namespace" "$pvc" "/data"
done

# Backup cluster configuration
echo "Backing up cluster configuration..."
microk8s kubectl get all --all-namespaces -o yaml > "$BACKUP_PATH/all-resources.yaml"
microk8s kubectl get pv -o yaml > "$BACKUP_PATH/persistent-volumes.yaml"
microk8s kubectl get pvc --all-namespaces -o yaml > "$BACKUP_PATH/persistent-volume-claims.yaml"
microk8s kubectl get configmap --all-namespaces -o yaml > "$BACKUP_PATH/configmaps.yaml"
microk8s kubectl get secret --all-namespaces -o yaml > "$BACKUP_PATH/secrets.yaml"

# Compress the entire backup
echo "Compressing backup..."
cd "$BACKUP_DIR"
tar czf "k8s-backup-$TIMESTAMP.tar.gz" "$TIMESTAMP"
rm -rf "$TIMESTAMP"

# Clean up old backups (keep last 7 days)
find "$BACKUP_DIR" -name "k8s-backup-*.tar.gz" -mtime +7 -delete

echo ""
echo "✓ Backup completed: $BACKUP_DIR/k8s-backup-$TIMESTAMP.tar.gz"
echo ""
echo "To restore from this backup:"
echo "  tar xzf $BACKUP_DIR/k8s-backup-$TIMESTAMP.tar.gz"
echo "  kubectl apply -f $TIMESTAMP/*.yaml"