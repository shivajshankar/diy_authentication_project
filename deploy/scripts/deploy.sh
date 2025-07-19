#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
NAMESPACE=${NAMESPACE:-auth-app}
WORKING_DIR=${WORKING_DIR:-/home/ubuntu/githubautomation/diy_authentication_project}
BACKEND_IMAGE=${BACKEND_IMAGE:-diy-auth-backend}
FRONTEND_IMAGE=${FRONTEND_IMAGE:-diy-auth-frontend}

echo -e "${GREEN}Starting Kubernetes deployment...${NC}"

# Function to build and import Docker image
build_and_import_image() {
    local context=$1
    local dockerfile=$2
    local image_name=$3
    local tag=${4:-latest}
    
    echo -e "${GREEN}Building ${image_name}:${tag}...${NC}"
    
    # Build the Docker image
    if ! docker build -t "${image_name}:${tag}" -f "${dockerfile}" "${context}"; then
        echo -e "${RED}Error building ${image_name}${NC}"
        return 1
    fi
    
    # Save and import into k3s
    echo "Importing ${image_name}:${tag} into k3s..."
    if ! docker save "${image_name}:${tag}" | sudo k3s ctr images import -; then
        echo -e "${RED}Error importing ${image_name} into k3s${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Successfully built and imported ${image_name}:${tag}${NC}"
}

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

# Main deployment process
main() {
    # Change to working directory
    cd "${WORKING_DIR}" || { echo -e "${RED}Failed to change to working directory${NC}"; exit 1; }
    
    # Build and import backend image
    build_and_import_image "." "Dockerfile.backend" "${BACKEND_IMAGE}" "latest"
    
    # Build and import frontend image
    build_and_import_image "./nodejs/loginscreen" "Dockerfile" "${FRONTEND_IMAGE}" "latest"
    
    # Update image references in deployment files
    echo -e "${GREEN}Updating image references...${NC}"
    sed -i "s|image: .*|image: ${BACKEND_IMAGE}:latest|" "deploy/k3s/deployments/backend-deployment.yaml"
    sed -i "s|image: .*|image: ${FRONTEND_IMAGE}:latest|" "deploy/k3s/deployments/frontend-deployment.yaml"
    
    # 1. Create namespace
    apply_if_exists "namespace" "deploy/k3s/namespaces/"
    
    # 2. Apply ConfigMaps
    apply_if_exists "ConfigMaps" "deploy/k3s/configs/"
    
    # 3. Apply Secrets (will be skipped if directory doesn't exist or is empty)
    apply_if_exists "Secrets" "deploy/k3s/secrets/"
    
    # 4. Deploy applications
    apply_if_exists "deployments" "deploy/k3s/deployments/"
    
    # 5. Create services
    apply_if_exists "services" "deploy/k3s/services/"
    
    # 6. Set up ingress
    apply_if_exists "ingress" "deploy/k3s/ingresses/"
    
    # 7. Verify deployment
    echo -e "\n${GREEN}=== Deployment Status ===${NC}"
    kubectl get pods,svc,ingress -n "${NAMESPACE}"
    
    echo -e "\n${GREEN}Deployment completed successfully!${NC}"
    echo -e "Frontend URL: ${FRONTEND_URL:-Not set}"
    echo -e "Backend API: ${BACKEND_URL:-Not set}"
}

# Run the main function
main "$@"
