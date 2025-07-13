# MicroK8s Aliases Guide

This guide documents all the aliases and functions available for MicroK8s operations.

## Basic Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `k` | `microk8s kubectl` | Short kubectl alias |
| `kubectl` | `microk8s kubectl` | Standard kubectl alias |
| `mk` | `microk8s` | Short microk8s alias |

## Pod Operations

| Alias | Command | Description |
|-------|---------|-------------|
| `kgp` | `kubectl get pods` | List pods in current namespace |
| `kgpa` | `kubectl get pods --all-namespaces` | List all pods |
| `kgpw` | `kubectl get pods -o wide` | List pods with extra info |
| `kgpwatch` | `watch kubectl get pods` | Watch pod status |
| `kdp` | `kubectl describe pod` | Describe a pod |
| `kdelp` | `kubectl delete pod` | Delete a pod |
| `klogf` | `kubectl logs -f` | Follow pod logs |

## Service Operations

| Alias | Command | Description |
|-------|---------|-------------|
| `kgs` | `kubectl get svc` | List services |
| `kgsa` | `kubectl get svc --all-namespaces` | List all services |
| `kds` | `kubectl describe svc` | Describe a service |

## Deployment Operations

| Alias | Command | Description |
|-------|---------|-------------|
| `kgd` | `kubectl get deployment` | List deployments |
| `kgda` | `kubectl get deployment --all-namespaces` | List all deployments |
| `kdd` | `kubectl describe deployment` | Describe deployment |
| `ksd` | `kubectl scale deployment` | Scale deployment |
| `krrd` | `kubectl rollout restart deployment` | Restart deployment |

## Namespace Operations

| Alias | Command | Description |
|-------|---------|-------------|
| `kgns` | `kubectl get namespaces` | List namespaces |
| `kns` | `kubectl config set-context --current --namespace` | Switch namespace |
| `kcns` | `kubectl create namespace` | Create namespace |

## Resource Monitoring

| Alias | Command | Description |
|-------|---------|-------------|
| `ktop` | `kubectl top` | Top command |
| `ktopn` | `kubectl top nodes` | Show node resources |
| `ktopp` | `kubectl top pods` | Show pod resources |

## Storage Operations

| Alias | Command | Description |
|-------|---------|-------------|
| `kgpvc` | `kubectl get pvc` | List PVCs |
| `kgpvca` | `kubectl get pvc --all-namespaces` | List all PVCs |
| `kgpv` | `kubectl get pv` | List PVs |

## GPU Operations

| Alias | Command | Description |
|-------|---------|-------------|
| `kgpu` | Show GPU availability | List nodes with GPU count |
| `kgpupods` | `kubectl get pods -n gpu-operator-resources` | GPU operator pods |
| `kgpuwork` | `kubectl get pods -n gpu-workloads` | GPU workload pods |

## MicroK8s Specific

| Alias | Command | Description |
|-------|---------|-------------|
| `mkstatus` | `microk8s status` | Check MicroK8s status |
| `mkstart` | `microk8s start` | Start MicroK8s |
| `mkstop` | `microk8s stop` | Stop MicroK8s |
| `mkenable` | `microk8s enable` | Enable addon |
| `mkdash` | `microk8s dashboard-proxy` | Start dashboard proxy |
| `mkhelm` | `microk8s helm3` | Helm 3 command |

## Useful Functions

### `kall <namespace>`
Get all resources in a namespace
```bash
kall production
```

### `ksh <pod> [container]`
Quick shell access to a pod
```bash
ksh my-pod
ksh my-pod my-container
```

### `kpf <pod> <local-port> <pod-port>`
Port forward helper
```bash
kpf my-pod 8080 80
```

### `kloggrep <pod> <search-term>`
Search in pod logs
```bash
kloggrep my-pod "error"
```

### `kwatchns <namespace>`
Watch pods in a specific namespace
```bash
kwatchns production
```

### `kevents [namespace]`
Get events sorted by time
```bash
kevents          # All namespaces
kevents production  # Specific namespace
```

### `kinfo`
Quick cluster information overview
```bash
kinfo
```

### `kclean`
Clean up completed and failed pods
```bash
kclean
```

### `kresources`
Show resource usage summary
```bash
kresources
```

### `khealth`
Run cluster health check
```bash
khealth
```

### `kapplydir <directory>`
Apply all manifests in a directory
```bash
kapplydir /home/repos/k8s-setup/namespaces/
```

## Examples

### Quick Debugging Session
```bash
# Check pod status
kgp

# Describe problematic pod
kdp problematic-pod

# Check logs
klogf problematic-pod

# Shell into pod
ksh problematic-pod

# Check events
kevents
```

### Deployment Management
```bash
# Scale deployment
ksd my-app --replicas=5

# Restart deployment
krrd my-app

# Watch rollout
watch kgd
```

### Resource Monitoring
```bash
# Check node resources
ktopn

# Check pod resources in namespace
kns production
ktopp

# Full resource overview
kresources
```

## Tips

1. **Tab Completion**: These aliases support kubectl tab completion
2. **Namespace Context**: Use `kns` to switch namespace context
3. **Quick Access**: Most common operations are 3-4 characters
4. **Chaining**: Aliases can be combined with standard Unix tools

## Adding Custom Aliases

To add your own aliases, edit `~/.bash_aliases` and add:

```bash
alias myalias='microk8s kubectl my-command'
```

Then reload:
```bash
source ~/.bashrc
```