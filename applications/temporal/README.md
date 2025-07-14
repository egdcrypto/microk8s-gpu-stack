# Temporal Workflow Engine on MicroK8s

## Overview
This deployment sets up Temporal.io workflow orchestration platform with PostgreSQL persistence on MicroK8s.

## Components

### Deployed Resources
- **Namespace**: `temporal`
- **PostgreSQL Database**: Persistent storage with 20Gi PVC
- **Temporal Server**: All-in-one deployment with auto-setup
- **Temporal UI**: Latest version with custom configuration
- **External Access**: NodePort services for both gRPC and Web UI

## Access Points

### Internal (Within Cluster)
- **Temporal Frontend gRPC**: `temporal-frontend.temporal.svc.cluster.local:7233`
- **PostgreSQL**: `postgres.temporal.svc.cluster.local:5432`

### External (Network Access)
- **Temporal Frontend gRPC**: `<NODE_IP>:30733`
- **Temporal UI**: `http://<NODE_IP>:30880`

## Deployment

### Apply the Configuration
```bash
kubectl apply -f temporal-postgres.yaml
```

### Verify Deployment
```bash
# Check all resources
kubectl get all -n temporal

# Check Temporal server logs
kubectl logs -n temporal -l app=temporal

# Check Web UI logs
kubectl logs -n temporal -l app=temporal-web
```

## Usage

### Connect to Temporal (from within cluster)
```yaml
# In your application configuration
temporal:
  address: temporal-frontend.temporal.svc.cluster.local:7233
```

### Connect to Temporal (from outside cluster)
```yaml
# In your application configuration
temporal:
  address: <NODE_IP>:30733
```

### Access Web UI
Open your browser to: `http://<NODE_IP>:30880`

### Using Temporal CLI
```bash
# From within a pod in the cluster
temporal --address temporal-frontend:7233 operator namespace list

# From outside the cluster
temporal --address <NODE_IP>:30733 operator namespace list
```

## Configuration Details

### PostgreSQL
- **Database**: temporal
- **User**: temporal
- **Password**: temporal123
- **Storage**: 20Gi persistent volume

### Temporal Server
- **Image**: temporalio/auto-setup:1.22.4
- **Resources**: 
  - Requests: 1Gi memory, 500m CPU
  - Limits: 2Gi memory, 1000m CPU
- **Features**:
  - Auto-setup enabled
  - PostgreSQL persistence
  - Dynamic configuration support
  - Elasticsearch disabled

### Web UI
- **Image**: temporalio/ui:latest
- **Port**: 8080
- **NodePort**: 30880
- **Custom Configuration**: Mounted via ConfigMap

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n temporal
```

### View Logs
```bash
# Temporal server logs
kubectl logs -n temporal deployment/temporal

# PostgreSQL logs
kubectl logs -n temporal deployment/postgres

# Web UI logs
kubectl logs -n temporal deployment/temporal-ui
```

### Common Issues

1. **UI Connection Issues**: The UI requires a custom configuration to work properly. This deployment includes a ConfigMap with the necessary configuration.

2. **Server Restart Loops**: Check PostgreSQL is running and accessible. The Temporal server depends on database connectivity.

3. **Cannot Connect**: Ensure you're using the correct address:
   - Internal: `temporal-frontend:7233`
   - External: `<NODE_IP>:30733`

### Test Connectivity
```bash
# Test from inside cluster
kubectl run -n temporal test-client --rm -it --image=temporalio/admin-tools:1.22.4 -- \
  temporal --address temporal-frontend:7233 operator namespace list

# Test Web UI
curl http://<NODE_IP>:30880
```

## Cleanup

To remove the entire Temporal deployment:
```bash
kubectl delete -f temporal-postgres.yaml
```

To completely remove including persistent data:
```bash
kubectl delete namespace temporal
```

## Notes

- The deployment uses MicroK8s hostpath storage class
- PostgreSQL data persists across pod restarts
- The Temporal server includes all services (frontend, history, matching, worker) in a single deployment
- External access is provided via NodePort services