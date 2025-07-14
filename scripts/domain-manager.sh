#!/bin/bash
set -e

# Domain Manager Script for MicroK8s
# Manages domain-based Kubernetes deployments

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
DOMAINS_DIR="$BASE_DIR/domains"
TEMPLATES_DIR="$DOMAINS_DIR/_templates"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Function to show usage
usage() {
    echo "Domain Manager for MicroK8s"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  deploy <domain> <environment>    Deploy a domain to specified environment"
    echo "  remove <domain> <environment>    Remove a domain from specified environment"
    echo "  list                            List all configured domains"
    echo "  status <domain>                 Show status of a domain across all environments"
    echo "  create <domain>                 Create a new domain structure"
    echo ""
    echo "Examples:"
    echo "  $0 deploy playablestories.ai production"
    echo "  $0 remove playablestories.ai development"
    echo "  $0 create mynewdomain.com"
    exit 1
}

# Function to validate domain exists
validate_domain() {
    local domain=$1
    if [ ! -d "$DOMAINS_DIR/$domain" ]; then
        print_error "Domain '$domain' not found in $DOMAINS_DIR"
        exit 1
    fi
}

# Function to validate environment exists
validate_environment() {
    local domain=$1
    local env=$2
    if [ ! -d "$DOMAINS_DIR/$domain/$env" ]; then
        print_error "Environment '$env' not found for domain '$domain'"
        exit 1
    fi
}

# Function to load configuration files
load_config() {
    local config_file=$1
    if [ -f "$config_file" ]; then
        # Source the YAML file as shell variables (basic parsing)
        eval $(cat "$config_file" | grep -E '^[a-zA-Z_]+:' | sed 's/: /=/' | sed 's/^/export /')
    fi
}

# Function to apply template substitutions
apply_template() {
    local template_file=$1
    local output_file=$2
    local domain_config=$3
    local env_config=$4
    
    # Load configurations
    source <(yq eval -o=shell "$domain_config")
    source <(yq eval -o=shell "$env_config")
    
    # Create output from template
    cp "$template_file" "$output_file"
    
    # Perform substitutions (basic implementation)
    # In production, use a proper templating engine
    sed -i "s/{{DOMAIN}}/$domain/g" "$output_file"
    sed -i "s/{{DOMAIN_SAFE}}/$domain_safe/g" "$output_file"
    sed -i "s/{{ENVIRONMENT}}/$environment/g" "$output_file"
    # Add more substitutions as needed
}

# Function to deploy a domain
deploy_domain() {
    local domain=$1
    local env=$2
    
    print_info "Deploying $domain to $env environment..."
    
    validate_domain "$domain"
    validate_environment "$domain" "$env"
    
    local domain_config="$DOMAINS_DIR/$domain/domain-config.yaml"
    local env_config="$DOMAINS_DIR/$domain/$env/config.yaml"
    local output_dir="/tmp/k8s-deploy-$$"
    
    mkdir -p "$output_dir"
    
    # Generate namespace
    print_info "Creating namespace..."
    # TODO: Apply template substitutions
    
    # Generate web service
    if [ -f "$DOMAINS_DIR/$domain/$env/web/deployment.yaml" ]; then
        print_info "Deploying web service..."
        microk8s kubectl apply -f "$DOMAINS_DIR/$domain/$env/web/deployment.yaml"
    fi
    
    # Generate API service
    if [ -f "$DOMAINS_DIR/$domain/$env/api/deployment.yaml" ]; then
        print_info "Deploying API service..."
        microk8s kubectl apply -f "$DOMAINS_DIR/$domain/$env/api/deployment.yaml"
    fi
    
    # Apply ingress rules
    if [ -f "$DOMAINS_DIR/$domain/$env/ingress.yaml" ]; then
        print_info "Configuring ingress..."
        microk8s kubectl apply -f "$DOMAINS_DIR/$domain/$env/ingress.yaml"
    fi
    
    print_success "Deployment completed for $domain in $env"
    
    # Cleanup
    rm -rf "$output_dir"
}

# Function to remove a domain deployment
remove_domain() {
    local domain=$1
    local env=$2
    
    print_info "Removing $domain from $env environment..."
    
    validate_domain "$domain"
    validate_environment "$domain" "$env"
    
    # Load domain config to get namespace
    local domain_safe=$(echo "$domain" | sed 's/\./-/g')
    local namespace="${domain_safe}-${env}"
    
    # Delete namespace (this will delete all resources in it)
    print_info "Deleting namespace $namespace..."
    microk8s kubectl delete namespace "$namespace" --ignore-not-found=true
    
    print_success "Removed $domain from $env environment"
}

# Function to list domains
list_domains() {
    print_info "Configured domains:"
    echo ""
    
    for domain_dir in "$DOMAINS_DIR"/*/; do
        if [ -d "$domain_dir" ] && [ "$(basename "$domain_dir")" != "_templates" ]; then
            domain=$(basename "$domain_dir")
            echo "  • $domain"
            
            # List environments
            for env_dir in "$domain_dir"/*/; do
                if [ -d "$env_dir" ]; then
                    env=$(basename "$env_dir")
                    if [[ ! "$env" =~ ^(domain-config\.yaml|\..*) ]]; then
                        echo "    - $env"
                    fi
                fi
            done
            echo ""
        fi
    done
}

# Function to show domain status
show_status() {
    local domain=$1
    
    validate_domain "$domain"
    
    print_info "Status for domain: $domain"
    echo ""
    
    local domain_safe=$(echo "$domain" | sed 's/\./-/g')
    
    # Check each environment
    for env in production staging development; do
        local namespace="${domain_safe}-${env}"
        
        # Check if namespace exists
        if microk8s kubectl get namespace "$namespace" &>/dev/null; then
            echo "Environment: $env"
            echo "  Namespace: $namespace (Active)"
            
            # Get pods
            local pods=$(microk8s kubectl get pods -n "$namespace" --no-headers 2>/dev/null | wc -l)
            echo "  Pods: $pods"
            
            # Get services
            local services=$(microk8s kubectl get services -n "$namespace" --no-headers 2>/dev/null | wc -l)
            echo "  Services: $services"
            
            # Get ingress
            local ingress=$(microk8s kubectl get ingress -n "$namespace" --no-headers 2>/dev/null | wc -l)
            echo "  Ingress rules: $ingress"
        else
            echo "Environment: $env"
            echo "  Namespace: $namespace (Not deployed)"
        fi
        echo ""
    done
}

# Function to create a new domain
create_domain() {
    local domain=$1
    local domain_safe=$(echo "$domain" | sed 's/\./-/g')
    
    if [ -d "$DOMAINS_DIR/$domain" ]; then
        print_error "Domain $domain already exists"
        exit 1
    fi
    
    print_info "Creating new domain structure for $domain..."
    
    # Create directory structure
    mkdir -p "$DOMAINS_DIR/$domain"/{production,staging,development}/{web,api}
    
    # Create domain config
    cat > "$DOMAINS_DIR/$domain/domain-config.yaml" << EOF
# Domain Configuration for $domain
domain: $domain
domain_safe: $domain_safe
description: "Description for $domain"

# Environments for this domain
environments:
  - production
  - staging
  - development

# Subdomain mapping
subdomains:
  production:
    web: www.$domain
    api: api.$domain
  staging:
    web: staging.$domain
    api: staging-api.$domain
  development:
    web: dev.$domain
    api: dev-api.$domain

# Application settings
applications:
  web:
    port: 80
    health_check_path: /
    image: nginx:alpine
  api:
    port: 8080
    health_check_path: /health
    image: nginx:alpine

# TLS Configuration
tls:
  enabled: false
  cert_manager_issuer: letsencrypt-prod
  secret_name_pattern: "{{subdomain}}-tls"
EOF

    # Copy environment configs from template
    for env in production staging development; do
        cp "$DOMAINS_DIR/playablestories.ai/$env/config.yaml" "$DOMAINS_DIR/$domain/$env/"
    done
    
    print_success "Created domain structure for $domain"
    print_info "Edit the configuration files in $DOMAINS_DIR/$domain to customize your deployment"
}

# Main script logic
if [ $# -lt 1 ]; then
    usage
fi

COMMAND=$1

case $COMMAND in
    deploy)
        if [ $# -ne 3 ]; then
            print_error "Usage: $0 deploy <domain> <environment>"
            exit 1
        fi
        deploy_domain "$2" "$3"
        ;;
    remove)
        if [ $# -ne 3 ]; then
            print_error "Usage: $0 remove <domain> <environment>"
            exit 1
        fi
        remove_domain "$2" "$3"
        ;;
    list)
        list_domains
        ;;
    status)
        if [ $# -ne 2 ]; then
            print_error "Usage: $0 status <domain>"
            exit 1
        fi
        show_status "$2"
        ;;
    create)
        if [ $# -ne 2 ]; then
            print_error "Usage: $0 create <domain>"
            exit 1
        fi
        create_domain "$2"
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        usage
        ;;
esac