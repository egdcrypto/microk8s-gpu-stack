#!/bin/bash

echo "MicroK8s Health Check"
echo "===================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $2 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
    fi
}

# Check MicroK8s status
echo "Checking MicroK8s status..."
microk8s status &> /dev/null
print_status "MicroK8s is running" $?

# Check nodes
echo ""
echo "Node Status:"
NODES=$(microk8s kubectl get nodes --no-headers 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "$NODES" | while read line; do
        NODE_NAME=$(echo $line | awk '{print $1}')
        NODE_STATUS=$(echo $line | awk '{print $2}')
        if [ "$NODE_STATUS" = "Ready" ]; then
            echo -e "  ${GREEN}✓${NC} $NODE_NAME: $NODE_STATUS"
        else
            echo -e "  ${RED}✗${NC} $NODE_NAME: $NODE_STATUS"
        fi
    done
else
    echo -e "  ${RED}✗${NC} Unable to get node status"
fi

# Check system pods
echo ""
echo "System Pods Status:"
SYSTEM_NAMESPACES="kube-system gpu-operator-resources monitoring ingress"
for ns in $SYSTEM_NAMESPACES; do
    TOTAL=$(microk8s kubectl get pods -n $ns --no-headers 2>/dev/null | wc -l)
    READY=$(microk8s kubectl get pods -n $ns --no-headers 2>/dev/null | grep -c "Running\|Completed")
    if [ $TOTAL -eq 0 ]; then
        echo -e "  ${YELLOW}⚠${NC}  $ns: No pods found"
    elif [ $TOTAL -eq $READY ]; then
        echo -e "  ${GREEN}✓${NC} $ns: $READY/$TOTAL pods ready"
    else
        echo -e "  ${RED}✗${NC} $ns: $READY/$TOTAL pods ready"
        # Show problematic pods
        microk8s kubectl get pods -n $ns --no-headers 2>/dev/null | grep -v "Running\|Completed" | while read pod; do
            POD_NAME=$(echo $pod | awk '{print $1}')
            POD_STATUS=$(echo $pod | awk '{print $3}')
            echo -e "      ${RED}-${NC} $POD_NAME: $POD_STATUS"
        done
    fi
done

# Check GPU if available
if command -v nvidia-smi &> /dev/null; then
    echo ""
    echo "GPU Status:"
    GPU_COUNT=$(microk8s kubectl get nodes -o json | jq -r '.items[0].status.capacity."nvidia.com/gpu" // "0"')
    if [ "$GPU_COUNT" != "0" ]; then
        echo -e "  ${GREEN}✓${NC} GPU available: $GPU_COUNT GPU(s)"
        nvidia-smi --query-gpu=name,memory.total,memory.used,temperature.gpu --format=csv,noheader | while read gpu_info; do
            echo "    - $gpu_info"
        done
    else
        echo -e "  ${RED}✗${NC} No GPUs detected in Kubernetes"
    fi
fi

# Check storage
echo ""
echo "Storage Status:"
PV_COUNT=$(microk8s kubectl get pv --no-headers 2>/dev/null | wc -l)
PVC_COUNT=$(microk8s kubectl get pvc --all-namespaces --no-headers 2>/dev/null | wc -l)
echo -e "  ${GREEN}✓${NC} Persistent Volumes: $PV_COUNT"
echo -e "  ${GREEN}✓${NC} Persistent Volume Claims: $PVC_COUNT"

# Check resource usage
echo ""
echo "Resource Usage:"
if microk8s kubectl top nodes &> /dev/null; then
    microk8s kubectl top nodes --no-headers | while read line; do
        NODE=$(echo $line | awk '{print $1}')
        CPU=$(echo $line | awk '{print $3}')
        MEM=$(echo $line | awk '{print $5}')
        echo "  Node $NODE: CPU $CPU, Memory $MEM"
    done
else
    echo -e "  ${YELLOW}⚠${NC}  Metrics server not available"
fi

# Check ingress
echo ""
echo "Ingress Status:"
INGRESS_COUNT=$(microk8s kubectl get ingress --all-namespaces --no-headers 2>/dev/null | wc -l)
echo -e "  ${GREEN}✓${NC} Ingress rules: $INGRESS_COUNT"

echo ""
echo "Health check completed!"