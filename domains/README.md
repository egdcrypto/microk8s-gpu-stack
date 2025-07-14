# Domain-Based Kubernetes Organization

This directory contains a domain-centric organization structure for managing multiple websites and applications on MicroK8s.

## Directory Structure

```
domains/
├── _templates/              # Reusable templates
│   ├── namespace-template.yaml
│   ├── web-service-template.yaml
│   ├── api-service-template.yaml
│   ├── ingress-template.yaml
│   └── environment-config.yaml
├── playablestories.ai/      # Example domain
│   ├── domain-config.yaml   # Domain-wide settings
│   ├── production/          # Production environment
│   │   ├── config.yaml      # Environment config
│   │   ├── web/            # Web service configs
│   │   └── api/            # API service configs
│   ├── staging/            # Staging environment
│   └── development/        # Development environment
└── README.md               # This file
```

## Concept

Each domain gets its own:
- **Namespace per environment**: `domain-environment` (e.g., `playablestories-ai-production`)
- **Resource quotas**: CPU, memory, storage limits per environment
- **Security policies**: Basic auth, SSL, CORS configuration
- **Service definitions**: Web and API services with environment-specific settings

## Using the Domain Manager

### 1. List all domains
```bash
./scripts/domain-manager.sh list
```

### 2. Create a new domain
```bash
./scripts/domain-manager.sh create mynewdomain.com
```

### 3. Deploy a domain
```bash
# Deploy to production
./scripts/domain-manager.sh deploy playablestories.ai production

# Deploy to development
./scripts/domain-manager.sh deploy playablestories.ai development
```

### 4. Check domain status
```bash
./scripts/domain-manager.sh status playablestories.ai
```

### 5. Remove a deployment
```bash
./scripts/domain-manager.sh remove playablestories.ai development
```

## Configuration Files

### domain-config.yaml
Main configuration for the domain:
- Domain name and safe name (for K8s resources)
- Subdomain mappings
- Application settings (ports, health checks)
- TLS configuration

### Environment config.yaml
Environment-specific settings:
- Resource allocations (CPU, memory)
- Replica counts
- Security settings (auth, SSL)
- Network policies (CORS, rate limiting)
- Logging levels

## Adding a New Domain

1. **Create domain structure**:
   ```bash
   ./scripts/domain-manager.sh create example.com
   ```

2. **Edit domain configuration**:
   ```bash
   vim domains/example.com/domain-config.yaml
   ```

3. **Customize environment settings**:
   ```bash
   vim domains/example.com/production/config.yaml
   vim domains/example.com/development/config.yaml
   ```

4. **Add your application manifests**:
   - Place web app configs in `domains/example.com/production/web/`
   - Place API configs in `domains/example.com/production/api/`

5. **Deploy**:
   ```bash
   ./scripts/domain-manager.sh deploy example.com production
   ```

## Templates

The `_templates` directory contains reusable Kubernetes manifests with placeholders:

- **{{DOMAIN}}**: The domain name
- **{{DOMAIN_SAFE}}**: Domain name safe for K8s (dots replaced with dashes)
- **{{ENVIRONMENT}}**: Environment name (production, staging, development)
- **{{NAMESPACE}}**: Computed namespace name
- **{{WEB_REPLICAS}}**, **{{API_REPLICAS}}**: Replica counts
- **{{CPU_REQUEST}}**, **{{MEMORY_LIMIT}}**: Resource allocations
- And many more...

## Best Practices

1. **Namespace Isolation**: Each domain-environment combination gets its own namespace
2. **Resource Quotas**: Set appropriate limits to prevent resource hogging
3. **Security**: 
   - Enable basic auth for development/staging
   - Use TLS for production
   - Configure CORS appropriately
4. **Monitoring**: Label all resources with domain and environment for easy filtering
5. **Gradual Rollout**: Test in development → staging → production

## Example: playablestories.ai

The included example shows:
- Multi-environment setup (production, staging, development)
- Different resource allocations per environment
- Basic auth for development
- CORS configuration for APIs
- Ingress routing for subdomains

## Troubleshooting

### Domain not deploying
1. Check domain exists: `ls domains/`
2. Validate configs: `cat domains/DOMAIN/domain-config.yaml`
3. Check namespace: `kubectl get ns | grep DOMAIN`

### Services not accessible
1. Check ingress: `kubectl get ingress -A | grep DOMAIN`
2. Verify DNS: `nslookup subdomain.DOMAIN`
3. Check pods: `kubectl get pods -n DOMAIN-ENVIRONMENT`

### Resource issues
1. Check quotas: `kubectl describe resourcequota -n DOMAIN-ENVIRONMENT`
2. View usage: `kubectl top pods -n DOMAIN-ENVIRONMENT`
3. Adjust limits in environment config.yaml

## Future Enhancements

- [ ] Helm chart generation from templates
- [ ] Automated TLS certificate management
- [ ] GitHub Actions integration for CI/CD
- [ ] Multi-cluster support
- [ ] Backup and restore functionality
- [ ] A/B deployment support