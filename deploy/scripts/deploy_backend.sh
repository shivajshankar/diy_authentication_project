#!/bin/bash
set -eo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
NAMESPACE=${NAMESPACE:-auth-app}
WORKING_DIR=${WORKING_DIR:-/home/ubuntu/githubautomation_be}
BACKEND_IMAGE=${BACKEND_IMAGE:-diy-auth-backend}
K3S_DIR=${K3S_DIR:-$WORKING_DIR/deploy/k3s}
CLEANUP_SCRIPT="$WORKING_DIR/deploy/scripts/cleanup_backend_images.sh"

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
    local context="backendspringboot"
    local image_name="${BACKEND_IMAGE}"
    local tag="latest"
    local full_image_name="${image_name}:${tag}"
    
    echo -e "${GREEN}Building ${full_image_name}...${NC}"
    
    pushd "${context}" > /dev/null || { echo -e "${RED}Failed to change to directory: ${context}${NC}"; return 1; }
    
    # Build the JAR file using Maven directly on the host
    echo -e "${GREEN}Building JAR file with Maven...${NC}"
    if ! mvn clean package -DskipTests; then
        echo -e "${RED}Failed to build JAR with Maven${NC}"
        popd > /dev/null || true
        return 1
    fi
    
    # Build the Docker image using the pre-built JAR
    echo -e "${GREEN}Building Docker image...${NC}"
    if ! docker build \
        -t "${full_image_name}" \
        -f "Dockerfile.runtime" \
        --build-arg JAR_FILE=target/*.jar \
        --build-arg MONGODB_URI="${MONGODB_URI}" \
        --build-arg JWT_SECRET="${JWT_SECRET}" \
        --build-arg JWT_EXPIRATION_MS="${JWT_EXPIRATION_MS}" \
        --build-arg GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID}" \
        --build-arg GOOGLE_CLIENT_SECRET="${GOOGLE_CLIENT_SECRET}" \
        --build-arg APP_URL="${BACKEND_URL}" \
        --build-arg CORS_ALLOWED_ORIGINS="${FRONTEND_URL}" \
        .; then
        echo -e "${RED}Failed to build Docker image${NC}"
        popd > /dev/null || true
        return 1
    fi
    
    popd > /dev/null || return 1
    
    # Import the image into k3s
    echo -e "\n${GREEN}Importing ${full_image_name} into k3s...${NC}"
    if ! docker save "${full_image_name}" | sudo k3s ctr images import -; then
        echo -e "${RED}Failed to import image into k3s${NC}"
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
    
    echo -e "${GREEN}Successfully built and imported ${full_image_name}${NC}"
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
    
    # List all YAML files for debugging
    echo -e "\n${YELLOW}=== Available YAML Files ===${NC}"
    find "${K3S_DIR}" -type f \( -name "*.yaml" -o -name "*.yml" \) -print0 | sort -z | xargs -0 ls -la
    echo -e "${YELLOW}============================${NC}\n"
    
    # Apply Kubernetes configurations
    echo -e "\n${GREEN}=== Applying Backend Kubernetes Configurations ===${NC}"
    
    # 1. Create namespace
    if [ -f "${K3S_DIR}/namespaces/auth-namespace.yaml" ]; then
        echo -e "${GREEN}Applying auth namespace...${NC}"
        kubectl apply -f "${K3S_DIR}/namespaces/auth-namespace.yaml"
    else
        echo -e "${YELLOW}Auth namespace file not found at ${K3S_DIR}/namespaces/auth-namespace.yaml${NC}"
    fi
    
    # 2. Apply ConfigMaps
    if [ -f "${K3S_DIR}/configs/backend-config.yaml" ]; then
        echo -e "${GREEN}Applying backend config...${NC}"
        kubectl apply -f "${K3S_DIR}/configs/backend-config.yaml"
    else
        echo -e "${YELLOW}Backend config file not found at ${K3S_DIR}/configs/backend-config.yaml${NC}"
    fi
    
    # 3. Apply Secrets
    if [ -f "${K3S_DIR}/secrets/backend-secrets.yaml" ]; then
        echo -e "${GREEN}Applying backend secrets...${NC}"
        kubectl apply -f "${K3S_DIR}/secrets/backend-secrets.yaml"
    else
        echo -e "${YELLOW}Backend secrets file not found at ${K3S_DIR}/secrets/backend-secrets.yaml${NC}"
    fi
    
    # 4. Deploy backend
    if [ -f "${K3S_DIR}/deployments/backend-deployment.yaml" ]; then
        echo -e "${GREEN}Applying backend deployment...${NC}"
        kubectl apply -f "${K3S_DIR}/deployments/backend-deployment.yaml"
    else
        echo -e "${RED}Backend deployment file not found at ${K3S_DIR}/deployments/backend-deployment.yaml${NC}"
        exit 1
    fi
    
    # 5. Create backend service
    if [ -f "${K3S_DIR}/services/backend-service.yaml" ]; then
        echo -e "${GREEN}Applying backend service...${NC}"
        kubectl apply -f "${K3S_DIR}/services/backend-service.yaml"
    else
        echo -e "${YELLOW}Backend service file not found at ${K3S_DIR}/services/backend-service.yaml${NC}"
    fi
    
    # 6. Set up ingress
    if [ -f "${K3S_DIR}/ingresses/auth-ingress.yaml" ]; then
        echo -e "${GREEN}Applying auth ingress...${NC}"
        kubectl apply -f "${K3S_DIR}/ingresses/auth-ingress.yaml"
    else
        echo -e "${YELLOW}Auth ingress file not found at ${K3S_DIR}/ingresses/auth-ingress.yaml${NC}"
    fi
    
    # 7. Restart backend deployment
    echo -e "\n${GREEN}=== Restarting Backend Deployment ===${NC}"
    if kubectl get deployment -n "${NAMESPACE}" -l app=auth-backend &> /dev/null; then
        kubectl rollout restart deployment -n "${NAMESPACE}" -l app=auth-backend
    else
        echo -e "${YELLOW}No deployments found with label app=auth-backend${NC}"
    fi
    
    # 8. Verify deployment
    echo -e "\n${GREEN}=== Backend Deployment Status ===${NC}"
    kubectl get pods,svc,ingress -n "${NAMESPACE}" -l app=auth-backend || \
        echo -e "${YELLOW}No resources found with label app=auth-backend${NC}"
    
    # 9. Check backend health
    if [ -n "${BACKEND_URL}" ]; then
        echo -e "\n${GREEN}=== Backend Health Check ===${NC}"
        echo -n "Backend health status: "
        curl -s -o /dev/null -w "%{http_code}" "${BACKEND_URL}/actuator/health" || echo "unreachable"
    fi
    
    # 10. Clean up old images one final time
    cleanup_old_images
    
    echo -e "\n${GREEN}=== Backend deployment completed! ===${NC}"
    echo -e "Backend API: ${BACKEND_URL:-Not set}"
}

# Run the main function
main "$@"
