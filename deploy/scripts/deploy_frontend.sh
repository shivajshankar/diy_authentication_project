#!/bin/bash
set -eo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
NAMESPACE=${NAMESPACE:-auth-app}
WORKING_DIR=${WORKING_DIR:-/home/ubuntu/githubautomation/diy_authentication_project}
FRONTEND_IMAGE=${FRONTEND_IMAGE:-diy-auth-frontend}
K3S_DIR=${K3S_DIR:-$WORKING_DIR/deploy/k3s}
CLEANUP_SCRIPT="$WORKING_DIR/deploy/scripts/cleanup_k3s_images.sh"

# Environment variables with defaults
FRONTEND_URL=${FRONTEND_URL:-}
BACKEND_URL=${BACKEND_URL:-}

# Function to clean up old k3s images
cleanup_old_images() {
    echo -e "\n${YELLOW}=== Cleaning up old k3s images ===${NC}"
    
    if [ ! -f "$CLEANUP_SCRIPT" ]; then
        echo -e "${YELLOW}Cleanup script not found at $CLEANUP_SCRIPT, skipping cleanup${NC}"
        return 0
    fi
    
    echo "Running cleanup script: $CLEANUP_SCRIPT"
    if ! bash "$CLEANUP_SCRIPT" "latest"; then
        echo -e "${YELLOW}Warning: Image cleanup failed, but continuing with deployment${NC}"
    fi
}

# Function to build and import Docker image
build_and_import_frontend() {
    local context="nodejs/loginscreen"
    local dockerfile="Dockerfile"
    local image_name="${FRONTEND_IMAGE}"
    local tag="latest"
    local full_image_name="${image_name}:${tag}"
    
    echo -e "${GREEN}Building ${full_image_name}...${NC}"
    
    # Change to the context directory
    pushd "${context}" > /dev/null || { echo -e "${RED}Failed to change to directory: ${context}${NC}"; return 1; }
    
    # Build the Docker image with appropriate build args
    local build_cmd="docker build --no-cache -t ${full_image_name} -f ${dockerfile}"
    
    # Add build args for frontend
    build_cmd+=" --build-arg REACT_APP_API_URL=\"${BACKEND_URL}/api\""
    build_cmd+=" --build-arg REACT_APP_ENV=\"production\""
    build_cmd+=" --build-arg REACT_APP_GOOGLE_AUTH_URL=\"${BACKEND_URL}/oauth2/authorization/google\""
    
    build_cmd+=" ."
    
    if ! eval "${build_cmd}"; then
        echo -e "${RED}Error building ${full_image_name}${NC}"
        popd > /dev/null || true
        return 1
    fi
    
    # Clean up old images before importing new ones
    cleanup_old_images
    
    # Import into k3s
    echo -e "${GREEN}Importing ${full_image_name} into k3s...${NC}"
    if ! docker save "${full_image_name}" | sudo k3s ctr images import -; then
        echo -e "${RED}Error importing ${full_image_name} into k3s${NC}"
        popd > /dev/null || true
        return 1
    fi
    
    popd > /dev/null || true
    echo -e "${GREEN}Successfully built and imported ${full_image_name}${NC}"
}

# Function to apply configurations if directory exists
apply_if_exists() {
    local config_type=$1
    local dir_path=$2
    
    if [ -d "$dir_path" ]; then
        # Skip if directory is empty
        if [ -z "$(ls -A "$dir_path" 2>/dev/null)" ]; then
            echo -e "${YELLOW}Skipping ${config_type} - ${dir_path} is empty${NC}"
            return 0
        fi
        
        echo -e "${GREEN}Applying ${config_type} from ${dir_path}...${NC}"
        
        # For secrets, only apply YAML/JSON files
        if [ "$config_type" = "Secrets" ]; then
            for file in "$dir_path"/{*.yaml,*.yml,*.json}; do
                if [ -f "$file" ]; then
                    echo "Applying $(basename "$file")"
                    kubectl apply -f "$file"
                fi
            done
        else
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
    echo -e "${GREEN}Working directory: ${WORKING_DIR}${NC}"
    cd "${WORKING_DIR}" || { echo -e "${RED}Failed to change to working directory${NC}"; exit 1; }
    
    # Verify directory structure
    echo -e "${GREEN}Verifying directory structure...${NC}"
    
    # Verify k3s directory exists
    if [ ! -d "${K3S_DIR}" ]; then
        echo -e "${RED}K3S directory not found at ${K3S_DIR}${NC}"
        exit 1
    fi
    
    # Verify frontend directory exists
    if [ ! -d "nodejs/loginscreen" ]; then
        echo -e "${RED}Frontend directory not found at nodejs/loginscreen${NC}"
        exit 1
    fi
    
    # Clean up old images before starting new build
    cleanup_old_images
    
    # Build and import frontend image
    echo -e "\n${GREEN}=== Building Frontend ===${NC}"
    build_and_import_frontend
    
    # Verify deployment file exists
    if [ ! -f "${K3S_DIR}/deployments/frontend-deployment.yaml" ]; then
        echo -e "${RED}Frontend deployment file not found in ${K3S_DIR}/deployments/${NC}"
        exit 1
    fi
    
    # Update image reference in deployment file
    echo -e "\n${GREEN}Updating frontend image reference...${NC}"
    sed -i "s|image: .*|image: ${FRONTEND_IMAGE}:latest|" "${K3S_DIR}/deployments/frontend-deployment.yaml"
    
    # Apply Kubernetes configurations
    echo -e "\n${GREEN}=== Applying Frontend Kubernetes Configurations ===${NC}"
    
    # 1. Create namespace
    apply_if_exists "namespace" "${K3S_DIR}/namespaces/"
    
    # 2. Apply ConfigMaps (only frontend related)
    if [ -d "${K3S_DIR}/configs/" ]; then
        echo -e "${GREEN}Applying frontend ConfigMaps...${NC}"
        for file in "${K3S_DIR}/configs/"*-frontend-*; do
            if [ -f "$file" ]; then
                kubectl apply -f "$file"
            fi
        done
    fi
    
    # 3. Deploy frontend
    apply_if_exists "frontend deployment" "${K3S_DIR}/deployments/frontend-deployment.yaml"
    
    # 4. Create frontend service
    if [ -f "${K3S_DIR}/services/frontend-service.yaml" ]; then
        apply_if_exists "frontend service" "${K3S_DIR}/services/frontend-service.yaml"
    fi
    
    # 5. Set up ingress (only if it contains frontend rules)
    if [ -f "${K3S_DIR}/ingresses/frontend-ingress.yaml" ]; then
        apply_if_exists "frontend ingress" "${K3S_DIR}/ingresses/frontend-ingress.yaml"
    fi
    
    # 6. Restart frontend deployment
    echo -e "\n${GREEN}=== Restarting Frontend Deployment ===${NC}"
    kubectl rollout restart deployment -n "${NAMESPACE}" -l app=frontend
    
    # 7. Verify deployment
    echo -e "\n${GREEN}=== Frontend Deployment Status ===${NC}"
    kubectl get pods,svc,ingress -n "${NAMESPACE}" -l app=frontend
    
    # 8. Clean up old images one final time
    cleanup_old_images
    
    echo -e "\n${GREEN}=== Frontend deployment completed! ===${NC}"
    echo -e "Frontend URL: ${FRONTEND_URL:-Not set}"
}

# Run the main function
main "$@"
