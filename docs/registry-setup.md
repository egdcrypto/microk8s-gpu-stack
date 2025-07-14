# MicroK8s Local Registry Setup

## Overview
The MicroK8s registry addon provides a local Docker registry for storing container images within your cluster.

## Access Points

### Registry
- **Internal URL**: `registry.container-registry.svc.cluster.local:5000`
- **NodePort**: `localhost:32000`
- **Storage**: 20Gi persistent volume

### Registry UI
- **URL**: http://localhost:32080
- **Features**: Browse images, delete images, view tags

## Usage

### Push Images
```bash
# Tag your image
docker tag myimage:latest localhost:32000/myimage:latest

# Push to registry
docker push localhost:32000/myimage:latest
```

### Use in Kubernetes
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: myapp
        image: localhost:32000/myimage:latest
```

### From within cluster
```yaml
image: registry.container-registry.svc.cluster.local:5000/myimage:latest
```

## Configuration

### Docker Daemon
The Docker daemon has been configured to treat the local registry as insecure:
```json
{
  "insecure-registries": ["localhost:32000", "10.152.183.0/24"]
}
```

### Storage
Registry data is stored in a 20Gi persistent volume managed by the hostpath provisioner.

## Troubleshooting

### Check Registry Status
```bash
kubectl get all -n container-registry
```

### View Registry Logs
```bash
kubectl logs -n container-registry deployment/registry
```

### List Images via API
```bash
curl http://localhost:32000/v2/_catalog
```

### List Tags for an Image
```bash
curl http://localhost:32000/v2/myimage/tags/list
```