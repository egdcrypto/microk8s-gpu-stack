# Playable Stories AI - Kubernetes Setup

## Overview

This document describes the Kubernetes configuration for hosting playablestories.ai on MicroK8s with separate environments for production and development.

## Domain Configuration

### Current DNS Setup
- **www.playablestories.ai** → Production web application
- **api.playablestories.ai** → Production API
- **dev.playablestories.ai** → Development web application (password protected)
- **dev-api.playablestories.ai** → Development API (password protected)

All subdomains point to `egdirty.ddns.net` (your dynamic DNS).

## Kubernetes Resources

### Namespaces
- **production** - Production environment for live services
- **development** - Development environment with basic auth protection

### Services Deployed

#### Production Environment
1. **playablestories-web** - Main website (2 replicas)
   - Nginx serving custom HTML
   - Accessible at: https://www.playablestories.ai

2. **playablestories-api** - Production API (2 replicas)
   - Mock API returning JSON status
   - Accessible at: https://api.playablestories.ai
   - CORS enabled for all origins

#### Development Environment
1. **playablestories-dev-web** - Development website (1 replica)
   - Nginx serving development HTML
   - Accessible at: https://dev.playablestories.ai
   - Protected with basic auth (admin/changeme)

2. **playablestories-dev-api** - Development API (1 replica)
   - Mock API with debug flag
   - Accessible at: https://dev-api.playablestories.ai
   - Protected with basic auth (admin/changeme)
   - CORS enabled

## Accessing the Services

### Local Testing
```bash
# Test production web
curl -H "Host: www.playablestories.ai" http://localhost

# Test production API
curl -H "Host: api.playablestories.ai" http://localhost

# Test dev web (with auth)
curl -u admin:changeme -H "Host: dev.playablestories.ai" http://localhost

# Test dev API (with auth)
curl -u admin:changeme -H "Host: dev-api.playablestories.ai" http://localhost
```

### Port Forwarding for Direct Access
```bash
# Forward ingress controller
sudo microk8s kubectl port-forward -n ingress daemonset/nginx-ingress-microk8s-controller 8080:80

# Then access via:
# http://localhost:8080 with appropriate Host header
```

## Security Considerations

### Development Environment Protection
- Basic authentication enabled (username: `admin`, password: `changeme`)
- **Important**: Change the password in production by updating the secret:

```bash
# Generate new password
htpasswd -nb newuser newpassword | base64

# Update the secret
kubectl edit secret basic-auth -n development
```

### SSL/TLS Configuration
Currently SSL is disabled. To enable:

1. Install cert-manager (already in our setup scripts)
2. Update ingress annotations:
   ```yaml
   nginx.ingress.kubernetes.io/ssl-redirect: "true"
   cert-manager.io/cluster-issuer: "letsencrypt-prod"
   ```
3. Add TLS section to each ingress

## Monitoring

Check service health:
```bash
# View all pods
kubectl get pods -n production
kubectl get pods -n development

# View ingress status
kubectl get ingress --all-namespaces

# Check logs
kubectl logs -n production deployment/playablestories-web
kubectl logs -n production deployment/playablestories-api
```

## Updating Content

### To update the web content:
```bash
# Edit the ConfigMap
kubectl edit configmap playablestories-web-content -n production

# Restart pods to pick up changes
kubectl rollout restart deployment playablestories-web -n production
```

### To deploy real applications:
1. Replace the temporary deployments with your actual applications
2. Update the service definitions to match your app ports
3. Consider adding persistent storage for data
4. Add proper health checks and resource limits

## Next Steps

1. **Enable SSL/TLS** with Let's Encrypt
2. **Replace temporary pods** with actual applications
3. **Set up CI/CD** pipeline for automated deployments
4. **Configure monitoring** with Prometheus/Grafana
5. **Add backup strategies** for persistent data
6. **Implement proper secrets management**

## Troubleshooting

### Ingress not working
```bash
# Check ingress controller
kubectl get pods -n ingress

# View ingress logs
kubectl logs -n ingress -l app=nginx-ingress-microk8s

# Verify DNS resolution
nslookup www.playablestories.ai
```

### Pods not starting
```bash
# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>

# Check resource availability
kubectl top nodes
kubectl top pods -n <namespace>
```