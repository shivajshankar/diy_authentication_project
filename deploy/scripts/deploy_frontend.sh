#!/bin/bash
set -eo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
NAMESPACE=${NAMESPACE:-auth-app}
WORKING_DIR=${WORKING_DIR:-/home/ubuntu/githubautomation_fe}
FRONTEND_IMAGE=${FRONTEND_IMAGE:-diy-auth-frontend}
K3S_DIR=${K3S_DIR:-$WORKING_DIR/deploy/k3s}
CLEANUP_SCRIPT="$WORKING_DIR/deploy/scripts/cleanup_frontend_images.sh"

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
    
    pushd "${context}" > /dev/null || { echo -e "${RED}Failed to change to directory: ${context}${NC}"; return 1; }
    
    # Build the Docker image with proper build args
    local build_cmd="docker build -t ${full_image_name} -f ${dockerfile}"
    
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
    
    # Remove any existing frontend images from k3s
    echo -e "${GREEN}Checking for existing frontend images in k3s...${NC}"
    existing_images=$(sudo k3s ctr images ls | grep "${image_name}:" || true)
    
    if [ -n "$existing_images" ]; then
        echo -e "${YELLOW}Found existing frontend images, removing them...${NC}"
        echo "$existing_images" | while read -r img; do
            img_ref=$(echo "$img" | awk '{print $1}')
            echo "Removing $img_ref..."
            sudo k3s ctr images rm "$img_ref" || true
        done
        echo -e "${GREEN}Removed existing frontend images from k3s${NC}"
    else
        echo -e "${GREEN}No existing frontend images found in k3s${NC}"
    fi
    
    # Save the image to a file
    local image_tar="/tmp/${image_name}_${tag}.tar"
    echo -e "\n${GREEN}Saving ${full_image_name} to ${image_tar}...${NC}"
    if ! docker save -o "${image_tar}" "${full_image_name}"; then
        echo -e "${RED}Error saving ${full_image_name} to ${image_tar}${NC}"
        popd > /dev/null || true
        return 1
    fi
    
    # Import the saved image into k3s
    echo -e "\n${GREEN}Importing ${image_tar} into k3s...${NC}"
    if ! sudo k3s ctr images import "${image_tar}"; then
        echo -e "${RED}Error importing ${image_tar} into k3s${NC}"
        # Clean up the temporary file
        rm -f "${image_tar}" || true
        popd > /dev/null || true
        return 1
    fi
    
    # Verify the image was imported
    if ! sudo k3s ctr images ls | grep -q "${image_name}.*${tag}"; then
        echo -e "${YELLOW}Warning: Could not verify image was imported into k3s, but continuing deployment${NC}"
        echo -e "${YELLOW}Current k3s images:${NC}"
        sudo k3s ctr images ls | grep -i "${image_name}" || echo "No matching images found"
    else
        echo -e "${GREEN}Successfully verified ${image_name}:${tag} in k3s${NC}"
    fi
    
    # Clean up the temporary file
    rm -f "${image_tar}" || true
    
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
    
    # List all YAML files for debugging
    echo -e "\n${YELLOW}=== Available YAML Files ===${NC}"
    find "${K3S_DIR}" -type f \( -name "*.yaml" -o -name "*.yml" \) -print0 | sort -z | xargs -0 ls -la
    echo -e "${YELLOW}============================${NC}\n"
    
    # Apply Kubernetes configurations
    echo -e "\n${GREEN}=== Applying Frontend Kubernetes Configurations ===${NC}"
    
    # 1. Create namespace
    if [ -f "${K3S_DIR}/namespaces/auth-namespace.yaml" ]; then
        echo -e "${GREEN}Applying auth namespace...${NC}"
        kubectl apply -f "${K3S_DIR}/namespaces/auth-namespace.yaml"
    else
        echo -e "${YELLOW}Auth namespace file not found at ${K3S_DIR}/namespaces/auth-namespace.yaml${NC}"
    fi
    
    # 2. Apply ConfigMaps
    if [ -f "${K3S_DIR}/configs/frontend-config.yaml" ]; then
        echo -e "${GREEN}Applying frontend config...${NC}"
        kubectl apply -f "${K3S_DIR}/configs/frontend-config.yaml"
    else
        echo -e "${YELLOW}Frontend config file not found at ${K3S_DIR}/configs/frontend-config.yaml${NC}"
    fi
    
    # 3. Deploy frontend
    if [ -f "${K3S_DIR}/deployments/frontend-deployment.yaml" ]; then
        echo -e "${GREEN}Applying frontend deployment...${NC}"
        kubectl apply -f "${K3S_DIR}/deployments/frontend-deployment.yaml"
    else
        echo -e "${RED}Frontend deployment file not found at ${K3S_DIR}/deployments/frontend-deployment.yaml${NC}"
        exit 1
    fi
    
    # 4. Create frontend service
    if [ -f "${K3S_DIR}/services/frontend-service.yaml" ]; then
        echo -e "${GREEN}Applying frontend service...${NC}"
        kubectl apply -f "${K3S_DIR}/services/frontend-service.yaml"
    else
        echo -e "${YELLOW}Frontend service file not found at ${K3S_DIR}/services/frontend-service.yaml${NC}"
    fi
    
    # 5. Set up ingress
    if [ -f "${K3S_DIR}/ingresses/auth-ingress.yaml" ]; then
        echo -e "${GREEN}Applying auth ingress...${NC}"
        kubectl apply -f "${K3S_DIR}/ingresses/auth-ingress.yaml"
    else
        echo -e "${YELLOW}Auth ingress file not found at ${K3S_DIR}/ingresses/auth-ingress.yaml${NC}"
    fi
    
    # 6. Restart frontend deployment
    echo -e "\n${GREEN}=== Restarting Frontend Deployment ===${NC}"
    if kubectl get deployment -n "${NAMESPACE}" -l app=auth-frontend &> /dev/null; then
        kubectl rollout restart deployment -n "${NAMESPACE}" -l app=auth-frontend
    else
        echo -e "${YELLOW}No deployments found with label app=auth-frontend${NC}"
        echo -e "${YELLOW}Available deployments in namespace ${NAMESPACE}:${NC}"
        kubectl get deployments -n "${NAMESPACE}" || true
    fi
    
    # 7. Verify deployment
    echo -e "\n${GREEN}=== Frontend Deployment Status ===${NC}"
    kubectl get pods,svc,ingress -n "${NAMESPACE}" -l app=auth-frontend || {
        echo -e "${YELLOW}No resources found with label app=auth-frontend${NC}"
        echo -e "${YELLOW}All resources in namespace ${NAMESPACE}:${NC}"
        kubectl get all -n "${NAMESPACE}" || true
    }
    
    # 8. Clean up old images one final time
    cleanup_old_images
    
    echo -e "\n${GREEN}=== Frontend deployment completed! ===${NC}"
    echo -e "Frontend URL: ${FRONTEND_URL:-Not set}"
}

# Run the main function
main "$@"
