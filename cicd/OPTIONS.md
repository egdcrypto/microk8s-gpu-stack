# CI/CD Options for Kubernetes

## Lightweight Options

### 1. **Drone CI** ⭐ (Recommended for lightweight)
- Very lightweight (single container)
- Native Kubernetes support
- GitHub webhook integration built-in
- Uses YAML pipeline definitions
- Memory: ~256MB

### 2. **Tekton**
- Kubernetes-native CI/CD
- CRD-based (no extra services)
- Very lightweight
- Steep learning curve

### 3. **Gitea + Drone**
- Self-hosted Git + CI combo
- Extremely lightweight
- Good for air-gapped environments

## Medium Weight Options

### 4. **GitLab Runner**
- Just the runner, not full GitLab
- Works with GitHub
- Good Docker support
- Memory: ~512MB

### 5. **Woodpecker CI**
- Fork of Drone
- Even more lightweight
- Simple YAML configs
- Memory: ~128MB

### 6. **Jenkins** 
- Well-known, lots of plugins
- Can be resource heavy
- Memory: 1-2GB minimum

## Heavier Options

### 7. **ArgoCD + Argo Workflows**
- GitOps focused
- Good for production
- Memory: ~1GB

### 8. **Flux + Flagger**
- GitOps alternative
- Lightweight individually
- Complex setup

## Simple Script-Based

### 9. **Webhook + Kubernetes Jobs**
- Ultra lightweight
- Custom webhook receiver
- Kubernetes Jobs for builds
- Memory: ~50MB

### 10. **GitHub Actions + Self-hosted Runner**
- Use existing GitHub Actions
- Self-hosted runner in cluster
- Memory: ~512MB

## Recommendation

For your use case, I'd recommend:
1. **Drone CI** - Simplest setup, lightweight, great GitHub integration
2. **Woodpecker CI** - If you want even lighter
3. **Webhook + K8s Jobs** - If you want minimal dependencies