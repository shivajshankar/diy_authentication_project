#!/bin/bash
# File: deploylocal6.sh
set -eo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Global variables
SHOULD_CLEANUP=true
TAG=""
CLEANUP_SCRIPT="./deploy/scripts/cleanup_k3s_images.sh"

# Cleanup function
cleanup() {
    if [ "$SHOULD_CLEANUP" = true ]; then
        echo -e "\n${YELLOW}Cleaning up...${NC}"
        rm -f diy-auth-*.tar
        echo -e "${GREEN}Cleanup complete.${NC}"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Check if cleanup script exists
if [ ! -f "$CLEANUP_SCRIPT" ]; then
    echo -e "${RED}Error: Cleanup script $CLEANUP_SCRIPT not found${NC}"
    exit 1
fi

# Check if required environment variables are set
required_vars=(
  "MONGODB_URI" "JWT_SECRET" "JWT_EXPIRATION_MS"
  "GOOGLE_CLIENT_ID" "GOOGLE_CLIENT_SECRET" "APP_URL"
  "FRONTEND_URL" "BACKEND_URL" "DOMAIN" "CORS_ALLOWED_ORIGINS"
)

echo -e "${GREEN}=== Starting Local k3s Deployment ===${NC}"

# Validate environment variables
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo -e "${RED}Error: $var is not set. Please source your secrets file first.${NC}"
    echo -e "${YELLOW}Example: source /path/to/secrets.sh${NC}"
    exit 1
  fi
done

# Create namespace if it doesn't exist
echo -e "\n${GREEN}=== Creating/Updating Namespace ===${NC}"
kubectl create namespace auth-app --dry-run=client -o yaml | kubectl apply -f -

# Create backend secrets
echo -e "\n${GREEN}=== Creating Backend Secrets ===${NC}"
kubectl create secret generic backend-secrets \
  --namespace=auth-app \
  --from-literal=MONGODB_URI="$MONGODB_URI" \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  --from-literal=JWT_EXPIRATION_MS="$JWT_EXPIRATION_MS" \
  --from-literal=GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID" \
  --from-literal=GOOGLE_CLIENT_SECRET="$GOOGLE_CLIENT_SECRET" \
  --from-literal=APP_URL="$APP_URL" \
  --from-literal=FRONTEND_URL="$FRONTEND_URL" \
  --from-literal=BACKEND_URL="$BACKEND_URL" \
  --from-literal=DOMAIN="$DOMAIN" \
  --from-literal=CORS_ALLOWED_ORIGINS="$CORS_ALLOWED_ORIGINS" \
  --dry-run=client -o yaml | kubectl apply -f -

# Generate unique tag with timestamp
TAG="$(date +%Y%m%d%H%M%S)"

# Clean up old k3s images before importing new ones
echo -e "\n=== Starting initial cleanup of old k3s images ==="
bash "$CLEANUP_SCRIPT" "$TAG"
echo -e "=== Completed initial cleanup of old k3s images ===\n"

# Import Docker images into k3s
echo -e "\n${GREEN}=== Building and Importing Docker Images to k3s ===${NC}"

# Build and import backend
echo -e "\n=== Building and importing backend... ==="
if ! docker build -t "diy-auth-backend:$TAG" -f Dockerfile.backend .; then
    echo -e "${RED}Failed to build backend image${NC}"
    exit 1
fi
echo -e "\n=== docker save diy-auth-backend:$TAG -o diy-auth-backend.tar ===\n"
docker save "diy-auth-backend:$TAG" -o diy-auth-backend.tar
echo -e "\n=== sudo k3s ctr images import diy-auth-backend.tar ===\n"
sudo k3s ctr images import diy-auth-backend.tar
echo -e "\n=== completed the k3s ctr images import for backend ===\n"

# Build and import frontend
echo -e "\n=== Building and importing frontend... ==="
# Ensure BACKEND_URL has a trailing slash if not present
if [[ "$BACKEND_URL" != */ ]]; then
    BACKEND_URL="${BACKEND_URL}/"
fi

if ! docker build \
    --build-arg REACT_APP_API_URL=${BACKEND_URL}api \
    --build-arg REACT_APP_GOOGLE_AUTH_URL=${BACKEND_URL}oauth2/authorization/google \
    --build-arg REACT_APP_ENV=production \
    -t "diy-auth-frontend:$TAG" \
    -f nodejs/loginscreen/Dockerfile \
    nodejs/loginscreen/; then
    echo -e "${RED}Failed to build frontend image${NC}"
    exit 1
fi

echo -e "\n=== docker save diy-auth-frontend:$TAG -o diy-auth-frontend.tar ===\n"
docker save "diy-auth-frontend:$TAG" -o diy-auth-frontend.tar
echo -e "\n=== sudo k3s ctr images import diy-auth-frontend.tar ===\n"
sudo k3s ctr images import diy-auth-frontend.tar
echo -e "\n=== completed the k3s ctr images import for frontend ===\n"

# Clean up old k3s images after importing new ones
echo -e "\n=== Starting final cleanup of old k3s images ==="
bash "$CLEANUP_SCRIPT" "$TAG"
echo -e "=== Completed final cleanup of old k3s images ===\n"

# Update image tags in deployments
echo -e "\n${GREEN}=== Updating Deployments with New Image Tags ===${NC}"

# Create backups of deployment files
cp ./deploy/k3s/deployments/backend-deployment.yaml{,.bak}
cp ./deploy/k3s/deployments/frontend-deployment.yaml{,.bak}

# Update backend deployment
sed -i "s|image: diy-auth-backend:.*|image: diy-auth-backend:$TAG|g" ./deploy/k3s/deployments/backend-deployment.yaml

# Update frontend deployment
sed -i "s|image: diy-auth-frontend:.*|image: diy-auth-frontend:$TAG|g" ./deploy/k3s/deployments/frontend-deployment.yaml

# Verify the changes
echo -e "\n${YELLOW}Updated image tags:${NC}"
grep "image:" ./deploy/k3s/deployments/*-deployment.yaml

# Apply k3s configurations
echo -e "\n${GREEN}=== Applying k3s Configurations ===${NC}"
K3S_DIR="./deploy/k3s"

for dir in "configs" "deployments" "services" "ingresses"; do
  if [ -d "${K3S_DIR}/${dir}" ]; then
    echo -e "\n${GREEN}=== Applying ${dir} ===${NC}"
    kubectl apply -f "${K3S_DIR}/${dir}/" -n auth-app
  fi
done

# Restart deployments to ensure they use the new images
echo -e "\n${GREEN}=== Restarting Deployments ===${NC}"
kubectl rollout restart deployment -n auth-app

# Show deployment status
echo -e "\n${GREEN}=== Deployment Status ===${NC}"
kubectl get pods,svc,ingress -n auth-app

echo -e "\n${GREEN}=== Deployment Complete! ===${NC}"
echo -e "Frontend URL: ${FRONTEND_URL}"
echo -e "Backend API: ${BACKEND_URL}"
echo -e "Deployed with image tag: ${TAG}"

# Set cleanup to false as we've completed successfully
SHOULD_CLEANUP=false
