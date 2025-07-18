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
    
    if [ -d "$dir_path" ]; then
        # Skip if directory is empty
        if [ -z "$(ls -A $dir_path 2>/dev/null)" ]; then
            echo -e "${YELLOW}Skipping ${config_type} - ${dir_path} is empty${NC}"
            return 0
        fi
        
        # For secrets, only apply YAML/JSON files
        if [ "$config_type" = "Secrets" ]; then
            echo -e "${GREEN}Applying ${config_type}...${NC}"
            for file in "$dir_path"/*.{yaml,yml,json}; do
                if [ -f "$file" ]; then
                    echo "Applying $(basename $file)"
                    kubectl apply -f "$file"
                fi
            done
        else
            echo -e "${GREEN}Applying ${config_type}...${NC}"
            kubectl apply -f "$dir_path"
        fi
    else
        echo -e "${YELLOW}Skipping ${config_type} - ${dir_path} not found${NC}"
        return 0
    fi
}

# 1. Create namespace
apply_if_exists "namespace" "k3s/namespaces/"

# 2. Apply ConfigMaps
apply_if_exists "ConfigMaps" "k3s/configs/"

# 3. Apply Secrets (will be skipped if directory doesn't exist or is empty)
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
