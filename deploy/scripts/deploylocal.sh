#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if required environment variables are set
required_vars=(
  "MONGODB_URI" "JWT_SECRET" "JWT_EXPIRATION_MS"
  "GOOGLE_CLIENT_ID" "GOOGLE_CLIENT_SECRET" "APP_URL"
  "FRONTEND_URL" "BACKEND_URL" "DOMAIN" "CORS_ALLOWED_ORIGINS"
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo -e "${RED}Error: $var is not set. Please source your secrets file first.${NC}"
    echo -e "${YELLOW}Example: source /path/to/secrets.sh${NC}"
    exit 1
  fi
done

echo -e "${GREEN}=== Starting Local k3s Deployment ===${NC}"

# Create namespace if it doesn't exist
echo -e "\n${GREEN}=== Creating/Updating Namespace ===${NC}"
kubectl create namespace auth-app --dry-run=client -o yaml | kubectl apply -f -

# Create backend secrets
echo -e "\n${GREEN}=== Creating Backend Secrets ===${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: backend-secrets
  namespace: auth-app
type: Opaque
stringData:
  MONGODB_URI: "${MONGODB_URI}"
  JWT_SECRET: "${JWT_SECRET}"
  JWT_EXPIRATION_MS: "${JWT_EXPIRATION_MS}"
  GOOGLE_CLIENT_ID: "${GOOGLE_CLIENT_ID}"
  GOOGLE_CLIENT_SECRET: "${GOOGLE_CLIENT_SECRET}"
  APP_URL: "${APP_URL}"
  FRONTEND_URL: "${FRONTEND_URL}"
  BACKEND_URL: "${BACKEND_URL}"
  DOMAIN: "${DOMAIN}"
  CORS_ALLOWED_ORIGINS: "${CORS_ALLOWED_ORIGINS}"
EOF

# Import Docker images into k3s
echo -e "\n${GREEN}=== Importing Docker Images to k3s ===${NC}"
docker save diy-auth-backend:latest -o diy-auth-backend.tar
docker save diy-auth-frontend:latest -o diy-auth-frontend.tar
sudo k3s ctr images import diy-auth-backend.tar
sudo k3s ctr images import diy-auth-frontend.tar

# Clean up temp files
rm -f diy-auth-backend.tar diy-auth-frontend.tar

# Apply k3s configurations
echo -e "\n${GREEN}=== Applying k3s Configurations ===${NC}"
K3S_DIR="./deploy/k3s"

# Apply configmaps
if [ -d "${K3S_DIR}/configs" ]; then
  echo -e "\n${GREEN}=== Applying ConfigMaps ===${NC}"
  kubectl apply -f ${K3S_DIR}/configs/ -n auth-app
fi

# Apply deployments
if [ -d "${K3S_DIR}/deployments" ]; then
  echo -e "\n${GREEN}=== Applying Deployments ===${NC}"
  kubectl apply -f ${K3S_DIR}/deployments/ -n auth-app
fi

# Apply services
if [ -d "${K3S_DIR}/services" ]; then
  echo -e "\n${GREEN}=== Applying Services ===${NC}"
  kubectl apply -f ${K3S_DIR}/services/ -n auth-app
fi

# Apply ingresses
if [ -d "${K3S_DIR}/ingresses" ]; then
  echo -e "\n${GREEN}=== Applying Ingresses ===${NC}"
  kubectl apply -f ${K3S_DIR}/ingresses/ -n auth-app
fi

# Show deployment status
echo -e "\n${GREEN}=== Deployment Status ===${NC}"
kubectl get pods,svc,ingress -n auth-app

echo -e "\n${GREEN}=== Deployment Complete! ===${NC}"
echo -e "Frontend URL: ${FRONTEND_URL}"
echo -e "Backend API: ${BACKEND_URL}"
