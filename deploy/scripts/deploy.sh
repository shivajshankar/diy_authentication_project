#!/bin/bash
set -e

# Apply all configurations in order
echo "Applying Kubernetes configurations..."

# 1. Create namespace
echo "Creating namespace..."
kubectl apply -f k3s/namespaces/

# 2. Apply ConfigMaps
echo "Applying ConfigMaps..."
kubectl apply -f k3s/configs/

# 3. Apply Secrets
echo "Applying Secrets..."
kubectl apply -f k3s/secrets/

# 4. Deploy applications
echo "Deploying applications..."
kubectl apply -f k3s/deployments/

# 5. Create services
echo "Creating services..."
kubectl apply -f k3s/services/

# 6. Set up ingress
echo "Setting up ingress..."
kubectl apply -f k3s/ingresses/

echo "Deployment complete!"
echo "Check the status of your deployments with: kubectl get pods -n auth-app"
echo "Check services with: kubectl get svc -n auth-app"
echo "Check ingress with: kubectl get ingress -n auth-app"
