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
build_and_import_backend() {
    local context="."
    local dockerfile="Dockerfile.backend"
    local image_name="${BACKEND_IMAGE}"
    local tag="latest"
    local full_image_name="${image_name}:${tag}"
    
    echo -e "${GREEN}Building ${full_image_name}...${NC}"
    
    # Change to the context directory
    pushd "${context}" > /dev/null || { echo -e "${RED}Failed to change to directory: ${context}${NC}"; return 1; }
    
    # Build the Docker image with appropriate build args
    local build_cmd="docker build -t ${full_image_name} -f ${dockerfile}"
    
    # Add build args for backend
    build_cmd+=" --build-arg SPRING_PROFILES_ACTIVE=prod"
    build_cmd+=" --build-arg MONGODB_URI=${MONGODB_URI}"
    build_cmd+=" --build-arg JWT_SECRET=${JWT_SECRET}"
    build_cmd+=" --build-arg JWT_EXPIRATION_MS=${JWT_EXPIRATION_MS}"
    build_cmd+=" --build-arg GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}"
    build_cmd+=" --build-arg GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}"
    build_cmd+=" --build-arg APP_URL=${BACKEND_URL}"
    build_cmd+=" --build-arg CORS_ALLOWED_ORIGINS=\"${FRONTEND_URL},http://localhost:3000,http://localhost\""
    
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
    
    # Verify backend directory exists
    if [ ! -f "pom.xml" ] && [ ! -f "build.gradle" ]; then
        echo -e "${RED}Backend build file (pom.xml or build.gradle) not found in ${WORKING_DIR}${NC}"
        exit 1
    fi
    
    # Clean up old images before starting new build
    cleanup_old_images
    
    # Build and import backend image
    echo -e "\n${GREEN}=== Building Backend ===${NC}"
    build_and_import_backend
    
    # Verify deployment file exists
    if [ ! -f "${K3S_DIR}/deployments/backend-deployment.yaml" ]; then
        echo -e "${RED}Backend deployment file not found in ${K3S_DIR}/deployments/${NC}"
        exit 1
    fi
    
    # Update image reference in deployment file
    echo -e "\n${GREEN}Updating backend image reference...${NC}"
    sed -i "s|image: .*|image: ${BACKEND_IMAGE}:latest|" "${K3S_DIR}/deployments/backend-deployment.yaml"
    
    # Apply Kubernetes configurations
    echo -e "\n${GREEN}=== Applying Backend Kubernetes Configurations ===${NC}"
    
    # 1. Create namespace
    apply_if_exists "namespace" "${K3S_DIR}/namespaces/"
    
    # 2. Apply ConfigMaps (only backend related)
    if [ -d "${K3S_DIR}/configs/" ]; then
        echo -e "${GREEN}Applying backend ConfigMaps...${NC}"
        for file in "${K3S_DIR}/configs/"*-backend-*; do
            if [ -f "$file" ]; then
                kubectl apply -f "$file"
            fi
        done
    fi
    
    # 3. Apply Secrets
    apply_if_exists "Secrets" "${K3S_DIR}/secrets/"
    
    # 4. Deploy backend
    apply_if_exists "backend deployment" "${K3S_DIR}/deployments/backend-deployment.yaml"
    
    # 5. Create backend service
    if [ -f "${K3S_DIR}/services/backend-service.yaml" ]; then
        apply_if_exists "backend service" "${K3S_DIR}/services/backend-service.yaml"
    fi
    
    # 6. Set up ingress (only if it contains backend rules)
    if [ -f "${K3S_DIR}/ingresses/backend-ingress.yaml" ]; then
        apply_if_exists "backend ingress" "${K3S_DIR}/ingresses/backend-ingress.yaml"
    fi
    
    # 7. Restart backend deployment
    echo -e "\n${GREEN}=== Restarting Backend Deployment ===${NC}"
    kubectl rollout restart deployment -n "${NAMESPACE}" -l app=backend
    
    # 8. Verify deployment
    echo -e "\n${GREEN}=== Backend Deployment Status ===${NC}"
    kubectl get pods,svc,ingress -n "${NAMESPACE}" -l app=backend
    
    # 9. Check backend health
    echo -e "\n${GREEN}=== Backend Health Check ===${NC}"
    echo -n "Backend health status: "
    curl -s -o /dev/null -w "%{http_code}" ${BACKEND_URL}/actuator/health || echo "unreachable"
    
    # 10. Clean up old images one final time
    cleanup_old_images
    
    echo -e "\n${GREEN}=== Backend deployment completed! ===${NC}"
    echo -e "Backend API: ${BACKEND_URL:-Not set}"
}

# Run the main function
main "$@"
