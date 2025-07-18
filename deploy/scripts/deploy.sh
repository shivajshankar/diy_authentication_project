#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Kubernetes deployment...${NC}"

# Function to apply configurations if directory exists
apply_if_exists() {
    local config_type=$1
    local dir_path=$2
    
    if [ -d "$dir_path" ] && [ "$(ls -A $dir_path 2>/dev/null)" ]; then
        echo -e "${GREEN}Applying ${config_type}...${NC}"
        kubectl apply -f "$dir_path"
    else
        echo -e "${YELLOW}Skipping ${config_type} - ${dir_path} not found or empty${NC}"
        return 0
    fi
}

# 1. Create namespace
apply_if_exists "namespace" "k3s/namespaces/"

# 2. Apply ConfigMaps
apply_if_exists "ConfigMaps" "k3s/configs/"

# 3. Apply Secrets (will be skipped if directory doesn't exist)
# Note: Secrets are now created directly in the GitHub Actions workflow
apply_if_exists "Secrets" "k3s/secrets/"

# 4. Deploy applications
apply_if_exists "deployments" "k3s/deployments/"

# 5. Create services
apply_if_exists "services" "k3s/services/"

# 6. Set up ingress
apply_if_exists "ingress" "k3s/ingresses/"

# 7. Verify deployment
echo -e "\n${GREEN}=== Deployment Status ===${NC}"
kubectl get pods,svc,ingress -n auth-app

echo -e "\n${GREEN}Deployment completed successfully!${NC}"
echo -e "Frontend URL: ${FRONTEND_URL:-Not set}"
echo -e "Backend API: ${BACKEND_URL:-Not set}"
