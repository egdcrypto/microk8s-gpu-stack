#!/bin/bash

# Kubernetes Cluster Resource Report Script
# This script provides a comprehensive view of cluster resources including:
# - Total node capacity (CPU, memory, storage)
# - Current usage by namespace
# - Available resources
# - Pod count by namespace
# - PVC usage
# - Summary table

set -euo pipefail

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to print headers
print_header() {
    echo -e "\n${BOLD}${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}\n"
}

# Function to print sub-headers
print_subheader() {
    echo -e "\n${BOLD}${PURPLE}▶ $1${NC}"
    echo -e "${PURPLE}$(printf '─%.0s' {1..80})${NC}\n"
}

# Function to format bytes to human readable
format_bytes() {
    local bytes=$1
    if [[ $bytes -gt 1073741824 ]]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}")Gi"
    elif [[ $bytes -gt 1048576 ]]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}")Mi"
    elif [[ $bytes -gt 1024 ]]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1024}")Ki"
    else
        echo "${bytes}B"
    fi
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl command not found. Please install kubectl first.${NC}"
    exit 1
fi

# Check if connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Not connected to a Kubernetes cluster.${NC}"
    exit 1
fi

# Get cluster name
CLUSTER_NAME=$(kubectl config current-context 2>/dev/null || echo "Unknown")

echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║                    KUBERNETES CLUSTER RESOURCE REPORT                          ║${NC}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
echo -e "\n${CYAN}Cluster: ${YELLOW}${CLUSTER_NAME}${NC}"
echo -e "${CYAN}Report Time: ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"

# 1. TOTAL NODE CAPACITY
print_header "1. TOTAL NODE CAPACITY"

# Get node information
print_subheader "Node Details"
kubectl get nodes -o custom-columns=\
'NAME:.metadata.name,STATUS:.status.conditions[?(@.type=="Ready")].status,ROLES:.metadata.labels.node-role\.kubernetes\.io/*,AGE:.metadata.creationTimestamp,VERSION:.status.nodeInfo.kubeletVersion,OS:.status.nodeInfo.osImage,KERNEL:.status.nodeInfo.kernelVersion' \
--no-headers | while IFS= read -r line; do
    echo -e "${GREEN}$line${NC}"
done

print_subheader "Node Resource Capacity"
echo -e "${BOLD}Node Name               CPU Capacity    Memory Capacity    Storage Capacity${NC}"
echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────${NC}"

TOTAL_CPU=0
TOTAL_MEMORY=0
TOTAL_STORAGE=0

kubectl get nodes --no-headers -o json | jq -r '.items[] | 
    "\(.metadata.name)|\(.status.capacity.cpu)|\(.status.capacity.memory)|\(.status.capacity["ephemeral-storage"])"' | \
while IFS='|' read -r node cpu memory storage; do
    # Convert memory to bytes
    mem_value=$(echo $memory | sed 's/Ki$//')
    mem_bytes=$((mem_value * 1024))
    
    # Convert storage to bytes
    storage_value=$(echo $storage | sed 's/Ki$//')
    storage_bytes=$((storage_value * 1024))
    
    # Format for display
    mem_human=$(format_bytes $mem_bytes)
    storage_human=$(format_bytes $storage_bytes)
    
    printf "%-23s %-15s %-18s %s\n" "$node" "${cpu} cores" "$mem_human" "$storage_human"
    
    # Add to totals
    TOTAL_CPU=$((TOTAL_CPU + cpu))
    TOTAL_MEMORY=$((TOTAL_MEMORY + mem_bytes))
    TOTAL_STORAGE=$((TOTAL_STORAGE + storage_bytes))
done

echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────${NC}"
printf "${BOLD}%-23s %-15s %-18s %s${NC}\n" "TOTAL" "${TOTAL_CPU} cores" \
    "$(format_bytes $TOTAL_MEMORY)" "$(format_bytes $TOTAL_STORAGE)"

# 2. CURRENT USAGE BY NAMESPACE
print_header "2. CURRENT USAGE BY NAMESPACE"

print_subheader "Resource Requests and Limits by Namespace"
echo -e "${BOLD}Namespace               CPU Request    CPU Limit      Memory Request    Memory Limit${NC}"
echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────────────${NC}"

kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name | while read -r ns; do
    # Get resource requests and limits for the namespace
    resources=$(kubectl get pods -n "$ns" --no-headers -o json 2>/dev/null | jq -r '
        .items[].spec.containers[] | 
        "\(.resources.requests.cpu // "0")|\(.resources.limits.cpu // "0")|\(.resources.requests.memory // "0")|\(.resources.limits.memory // "0")"' 2>/dev/null || echo "")
    
    if [ -n "$resources" ]; then
        cpu_req_total=0
        cpu_lim_total=0
        mem_req_total=0
        mem_lim_total=0
        
        while IFS='|' read -r cpu_req cpu_lim mem_req mem_lim; do
            # Process CPU (convert m to millicores if needed)
            if [[ $cpu_req == *"m" ]]; then
                cpu_req_val=$(echo $cpu_req | sed 's/m$//')
            else
                cpu_req_val=$((cpu_req * 1000))
            fi
            
            if [[ $cpu_lim == *"m" ]]; then
                cpu_lim_val=$(echo $cpu_lim | sed 's/m$//')
            else
                cpu_lim_val=$((cpu_lim * 1000))
            fi
            
            # Process Memory (convert to bytes)
            if [[ $mem_req == *"Gi" ]]; then
                mem_req_val=$(echo $mem_req | sed 's/Gi$//')
                mem_req_bytes=$((mem_req_val * 1024 * 1024 * 1024))
            elif [[ $mem_req == *"Mi" ]]; then
                mem_req_val=$(echo $mem_req | sed 's/Mi$//')
                mem_req_bytes=$((mem_req_val * 1024 * 1024))
            elif [[ $mem_req == *"Ki" ]]; then
                mem_req_val=$(echo $mem_req | sed 's/Ki$//')
                mem_req_bytes=$((mem_req_val * 1024))
            else
                mem_req_bytes=$mem_req
            fi
            
            if [[ $mem_lim == *"Gi" ]]; then
                mem_lim_val=$(echo $mem_lim | sed 's/Gi$//')
                mem_lim_bytes=$((mem_lim_val * 1024 * 1024 * 1024))
            elif [[ $mem_lim == *"Mi" ]]; then
                mem_lim_val=$(echo $mem_lim | sed 's/Mi$//')
                mem_lim_bytes=$((mem_lim_val * 1024 * 1024))
            elif [[ $mem_lim == *"Ki" ]]; then
                mem_lim_val=$(echo $mem_lim | sed 's/Ki$//')
                mem_lim_bytes=$((mem_lim_val * 1024))
            else
                mem_lim_bytes=$mem_lim
            fi
            
            cpu_req_total=$((cpu_req_total + cpu_req_val))
            cpu_lim_total=$((cpu_lim_total + cpu_lim_val))
            mem_req_total=$((mem_req_total + mem_req_bytes))
            mem_lim_total=$((mem_lim_total + mem_lim_bytes))
        done <<< "$resources"
        
        if [ $cpu_req_total -gt 0 ] || [ $mem_req_total -gt 0 ]; then
            printf "%-23s %-14s %-14s %-17s %s\n" "$ns" \
                "${cpu_req_total}m" "${cpu_lim_total}m" \
                "$(format_bytes $mem_req_total)" "$(format_bytes $mem_lim_total)"
        fi
    fi
done

# 3. AVAILABLE RESOURCES
print_header "3. AVAILABLE RESOURCES"

print_subheader "Node Resource Allocation"
echo -e "${BOLD}Node Name               Allocatable CPU    Allocatable Memory    CPU Pressure    Memory Pressure${NC}"
echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────────────────────────${NC}"

kubectl get nodes --no-headers -o json | jq -r '.items[] | 
    "\(.metadata.name)|\(.status.allocatable.cpu)|\(.status.allocatable.memory)|\(.status.conditions[] | select(.type=="MemoryPressure") | .status)|\(.status.conditions[] | select(.type=="DiskPressure") | .status)"' | \
while IFS='|' read -r node alloc_cpu alloc_memory mem_pressure disk_pressure; do
    # Convert memory to human readable
    mem_value=$(echo $alloc_memory | sed 's/Ki$//')
    mem_bytes=$((mem_value * 1024))
    mem_human=$(format_bytes $mem_bytes)
    
    # Color code pressure status
    if [ "$mem_pressure" = "True" ]; then
        mem_status="${RED}High${NC}"
    else
        mem_status="${GREEN}Normal${NC}"
    fi
    
    if [ "$disk_pressure" = "True" ]; then
        disk_status="${RED}High${NC}"
    else
        disk_status="${GREEN}Normal${NC}"
    fi
    
    printf "%-23s %-18s %-21s %-15s %s\n" "$node" "${alloc_cpu} cores" "$mem_human" "$mem_status" "$disk_status"
done

# 4. POD COUNT BY NAMESPACE
print_header "4. POD COUNT BY NAMESPACE"

print_subheader "Pod Distribution"
echo -e "${BOLD}Namespace               Running    Pending    Failed    Succeeded    Total${NC}"
echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────${NC}"

TOTAL_RUNNING=0
TOTAL_PENDING=0
TOTAL_FAILED=0
TOTAL_SUCCEEDED=0
TOTAL_PODS=0

kubectl get pods --all-namespaces --no-headers -o custom-columns=\
'NAMESPACE:.metadata.namespace,STATUS:.status.phase' | \
awk '{count[$1][$2]++; total[$1]++} 
END {
    for (ns in total) {
        printf "%-23s %-10s %-10s %-9s %-12s %s\n", 
            ns, 
            count[ns]["Running"]+0, 
            count[ns]["Pending"]+0, 
            count[ns]["Failed"]+0, 
            count[ns]["Succeeded"]+0, 
            total[ns]
    }
}' | sort | while read -r line; do
    echo -e "${GREEN}$line${NC}"
    
    # Extract values for totals
    running=$(echo "$line" | awk '{print $2}')
    pending=$(echo "$line" | awk '{print $3}')
    failed=$(echo "$line" | awk '{print $4}')
    succeeded=$(echo "$line" | awk '{print $5}')
    total=$(echo "$line" | awk '{print $6}')
    
    TOTAL_RUNNING=$((TOTAL_RUNNING + running))
    TOTAL_PENDING=$((TOTAL_PENDING + pending))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))
    TOTAL_SUCCEEDED=$((TOTAL_SUCCEEDED + succeeded))
    TOTAL_PODS=$((TOTAL_PODS + total))
done

echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────${NC}"
printf "${BOLD}%-23s %-10s %-10s %-9s %-12s %s${NC}\n" "TOTAL" \
    "$TOTAL_RUNNING" "$TOTAL_PENDING" "$TOTAL_FAILED" "$TOTAL_SUCCEEDED" "$TOTAL_PODS"

# 5. PVC USAGE
print_header "5. PERSISTENT VOLUME CLAIMS (PVC) USAGE"

print_subheader "PVC Details"
echo -e "${BOLD}Namespace    PVC Name                         Status    Volume              Capacity    StorageClass${NC}"
echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"

kubectl get pvc --all-namespaces --no-headers -o custom-columns=\
'NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,VOLUME:.spec.volumeName,CAPACITY:.status.capacity.storage,STORAGECLASS:.spec.storageClassName' | \
while IFS= read -r line; do
    status=$(echo "$line" | awk '{print $3}')
    if [ "$status" = "Bound" ]; then
        echo -e "${GREEN}$line${NC}"
    else
        echo -e "${YELLOW}$line${NC}"
    fi
done

# 6. STORAGE USAGE (using df)
print_header "6. NODE STORAGE USAGE"

print_subheader "File System Usage on Nodes"
echo -e "${CYAN}Note: This shows local file system usage on the current node where kubectl is running${NC}\n"

echo -e "${BOLD}Filesystem              Size    Used    Avail   Use%   Mounted on${NC}"
echo -e "${CYAN}────────────────────────────────────────────────────────────────────────${NC}"

df -h | grep -E '^/dev/|^tmpfs|^overlay' | while IFS= read -r line; do
    use_percent=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    if [ "$use_percent" -gt 90 ]; then
        echo -e "${RED}$line${NC}"
    elif [ "$use_percent" -gt 70 ]; then
        echo -e "${YELLOW}$line${NC}"
    else
        echo -e "${GREEN}$line${NC}"
    fi
done

# 7. SUMMARY TABLE
print_header "7. CLUSTER RESOURCE SUMMARY"

echo -e "${BOLD}${CYAN}┌─────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}${CYAN}│                         RESOURCE SUMMARY                            │${NC}"
echo -e "${BOLD}${CYAN}├─────────────────────────────────────────────────────────────────────┤${NC}"

# Get current resource usage
USED_CPU=$(kubectl top nodes --no-headers 2>/dev/null | awk '{sum+=$2} END {print sum}' || echo "N/A")
USED_MEMORY=$(kubectl top nodes --no-headers 2>/dev/null | awk '{sum+=$4} END {print sum}' || echo "N/A")

# Node count
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
NODE_READY=$(kubectl get nodes --no-headers | grep -c " Ready " || echo 0)

# Namespace count
NS_COUNT=$(kubectl get namespaces --no-headers | wc -l)

# Pod summary
POD_RUNNING=$(kubectl get pods --all-namespaces --no-headers | grep -c "Running" || echo 0)
POD_TOTAL=$(kubectl get pods --all-namespaces --no-headers | wc -l)

# PVC summary
PVC_BOUND=$(kubectl get pvc --all-namespaces --no-headers | grep -c "Bound" || echo 0)
PVC_TOTAL=$(kubectl get pvc --all-namespaces --no-headers | wc -l)

echo -e "${BOLD}${CYAN}│${NC} ${BOLD}Nodes:${NC}                                                              ${BOLD}${CYAN}│${NC}"
echo -e "${BOLD}${CYAN}│${NC}   Total: ${GREEN}$NODE_COUNT${NC}  |  Ready: ${GREEN}$NODE_READY${NC}  |  Not Ready: ${RED}$((NODE_COUNT - NODE_READY))${NC}                      ${BOLD}${CYAN}│${NC}"
echo -e "${BOLD}${CYAN}├─────────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${BOLD}${CYAN}│${NC} ${BOLD}Namespaces:${NC} ${GREEN}$NS_COUNT${NC}                                                       ${BOLD}${CYAN}│${NC}"
echo -e "${BOLD}${CYAN}├─────────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${BOLD}${CYAN}│${NC} ${BOLD}Pods:${NC}                                                               ${BOLD}${CYAN}│${NC}"
echo -e "${BOLD}${CYAN}│${NC}   Total: ${GREEN}$POD_TOTAL${NC}  |  Running: ${GREEN}$POD_RUNNING${NC}  |  Other: ${YELLOW}$((POD_TOTAL - POD_RUNNING))${NC}               ${BOLD}${CYAN}│${NC}"
echo -e "${BOLD}${CYAN}├─────────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${BOLD}${CYAN}│${NC} ${BOLD}PVCs:${NC}                                                               ${BOLD}${CYAN}│${NC}"
echo -e "${BOLD}${CYAN}│${NC}   Total: ${GREEN}$PVC_TOTAL${NC}  |  Bound: ${GREEN}$PVC_BOUND${NC}  |  Pending: ${YELLOW}$((PVC_TOTAL - PVC_BOUND))${NC}                 ${BOLD}${CYAN}│${NC}"
echo -e "${BOLD}${CYAN}├─────────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${BOLD}${CYAN}│${NC} ${BOLD}Resource Capacity:${NC}                                                  ${BOLD}${CYAN}│${NC}"
echo -e "${BOLD}${CYAN}│${NC}   CPU: ${GREEN}${TOTAL_CPU} cores${NC}                                                   ${BOLD}${CYAN}│${NC}"
echo -e "${BOLD}${CYAN}│${NC}   Memory: ${GREEN}$(format_bytes $TOTAL_MEMORY)${NC}                                              ${BOLD}${CYAN}│${NC}"
echo -e "${BOLD}${CYAN}│${NC}   Storage: ${GREEN}$(format_bytes $TOTAL_STORAGE)${NC}                                            ${BOLD}${CYAN}│${NC}"
echo -e "${BOLD}${CYAN}└─────────────────────────────────────────────────────────────────────┘${NC}"

echo -e "\n${BOLD}${GREEN}Report completed successfully!${NC}"
echo -e "${CYAN}Generated on: $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}\n"