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
BACKEND_IMAGE=${BACKEND_IMAGE:-diy-auth-backend}
FRONTEND_IMAGE=${FRONTEND_IMAGE:-diy-auth-frontend}
K3S_DIR=${K3S_DIR:-$WORKING_DIR/deploy/k3s}
CLEANUP_SCRIPT="$WORKING_DIR/deploy/scripts/cleanup_k3s_images.sh"

# Environment variables with defaults
MONGODB_URI=${MONGODB_URI:-}
JWT_SECRET=${JWT_SECRET:-}
JWT_EXPIRATION_MS=${JWT_EXPIRATION_MS:-86400000}
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID:-}
GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET:-}
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
build_and_import_image() {
    local context=$1
    local dockerfile=$2
    local image_name=$3
    local tag=${4:-latest}
    local full_image_name="${image_name}:${tag}"
    
    echo -e "${GREEN}Building ${full_image_name}...${NC}"
    
    # Change to the context directory
    pushd "${context}" > /dev/null || { echo -e "${RED}Failed to change to directory: ${context}${NC}"; return 1; }
    
    # Build the Docker image with appropriate build args
    local build_cmd="docker build -t ${full_image_name} -f ${dockerfile}"
    
    # Add build args for backend
    if [ "${dockerfile}" = "Dockerfile.backend" ]; then
        build_cmd+=" --build-arg SPRING_PROFILES_ACTIVE=prod"
        build_cmd+=" --build-arg MONGODB_URI=${MONGODB_URI}"
        build_cmd+=" --build-arg JWT_SECRET=${JWT_SECRET}"
        build_cmd+=" --build-arg JWT_EXPIRATION_MS=${JWT_EXPIRATION_MS}"
        build_cmd+=" --build-arg GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}"
        build_cmd+=" --build-arg GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}"
        build_cmd+=" --build-arg APP_URL=${BACKEND_URL}"
        build_cmd+=" --build-arg CORS_ALLOWED_ORIGINS=\"${FRONTEND_URL},http://localhost:3000,http://localhost\""
    # Add build args for frontend
    elif [ "${dockerfile}" = "Dockerfile" ]; then
        build_cmd+=" --build-arg REACT_APP_API_URL=\"${BACKEND_URL}/api\""
        build_cmd+=" --build-arg REACT_APP_ENV=\"production\""
        build_cmd+=" --build-arg REACT_APP_GOOGLE_AUTH_URL=\"${BACKEND_URL}/oauth2/authorization/google\""
    fi
    
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
        if [ -z "$(ls -A $dir_path 2>/dev/null)" ]; then
            echo -e "${YELLOW}Skipping ${config_type} - ${dir_path} is empty${NC}"
            return 0
        fi
        
        echo -e "${GREEN}Applying ${config_type} from ${dir_path}...${NC}"
        
        # For secrets, only apply YAML/JSON files
        if [ "$config_type" = "Secrets" ]; then
            for file in "$dir_path"/*.{yaml,yml,json}; do
                if [ -f "$file" ]; then
                    echo "Applying $(basename $file)"
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
    ls -la
    
    # Verify k3s directory exists
    if [ ! -d "${K3S_DIR}" ]; then
        echo -e "${RED}K3S directory not found at ${K3S_DIR}${NC}"
        exit 1
    }
    
    # Clean up old images before starting new build
    cleanup_old_images
    
    # Build and import backend image
    echo -e "\n${GREEN}=== Building Backend ===${NC}"
    build_and_import_image "." "Dockerfile.backend" "${BACKEND_IMAGE}" "latest"
    
    # Build and import frontend image
    echo -e "\n${GREEN}=== Building Frontend ===${NC}"
    if [ ! -d "nodejs/loginscreen" ]; then
        echo -e "${RED}Frontend directory not found at nodejs/loginscreen${NC}"
        echo -e "Current directory: $(pwd)"
        ls -la
        exit 1
    }
    
    build_and_import_image "nodejs/loginscreen" "Dockerfile" "${FRONTEND_IMAGE}" "latest"
    
    # Verify deployment files exist
    if [ ! -f "${K3S_DIR}/deployments/backend-deployment.yaml" ] || [ ! -f "${K3S_DIR}/deployments/frontend-deployment.yaml" ]; then
        echo -e "${RED}Deployment files not found in ${K3S_DIR}/deployments/${NC}"
        exit 1
    }
    
    # Update image references in deployment files
    echo -e "\n${GREEN}Updating image references...${NC}"
    sed -i "s|image: .*|image: ${BACKEND_IMAGE}:latest|" "${K3S_DIR}/deployments/backend-deployment.yaml"
    sed -i "s|image: .*|image: ${FRONTEND_IMAGE}:latest|" "${K3S_DIR}/deployments/frontend-deployment.yaml"
    
    # Apply Kubernetes configurations
    echo -e "\n${GREEN}=== Applying Kubernetes Configurations ===${NC}"
    
    # 1. Create namespace
    apply_if_exists "namespace" "${K3S_DIR}/namespaces/"
    
    # 2. Apply ConfigMaps
    apply_if_exists "ConfigMaps" "${K3S_DIR}/configs/"
    
    # 3. Apply Secrets
    apply_if_exists "Secrets" "${K3S_DIR}/secrets/"
    
    # 4. Deploy applications
    apply_if_exists "deployments" "${K3S_DIR}/deployments/"
    
    # 5. Create services
    apply_if_exists "services" "${K3S_DIR}/services/"
    
    # 6. Set up ingress
    apply_if_exists "ingress" "${K3S_DIR}/ingresses/"
    
    # 7. Restart deployments to ensure new images are used
    echo -e "\n${GREEN}=== Restarting Deployments ===${NC}"
    kubectl rollout restart deployment -n "${NAMESPACE}"
    
    # 8. Verify deployment
    echo -e "\n${GREEN}=== Deployment Status ===${NC}"
    kubectl get pods,svc,ingress -n "${NAMESPACE}"
    
    # 9. Clean up old images one final time
    cleanup_old_images
    
    echo -e "\n${GREEN}=== Deployment completed! ===${NC}"
    echo -e "Frontend URL: ${FRONTEND_URL:-Not set}"
    echo -e "Backend API: ${BACKEND_URL:-Not set}"
}

# Run the main function
main "$@"
