#!/bin/bash
# This script sets up port forwarding for Traefik and Backend

# Get the current NodePorts
FRONTEND_NODE_PORT=$(kubectl get svc -n auth-app auth-frontend-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
BACKEND_NODE_PORT=$(kubectl get svc -n auth-app auth-backend-nodeport -o jsonpath='{.spec.ports[0].nodePort}')

echo "Setting up port forwarding:"
echo "3000 (external) -> $FRONTEND_NODE_PORT (frontend)"
echo "8080 (external) -> $BACKEND_NODE_PORT (backend)"

# Remove any existing rules
sudo iptables -t nat -F PREROUTING

# Forward HTTP frontend (port 3000)
sudo iptables -t nat -A PREROUTING -p tcp --dport 3000 -j REDIRECT --to-port $FRONTEND_NODE_PORT

# Forward HTTP backend (port 8080)
sudo iptables -t nat -A PREROUTING -p tcp --dport 8080 -j REDIRECT --to-port $BACKEND_NODE_PORT

# Install iptables-persistent if not already installed
if ! dpkg -l | grep -q iptables-persistent; then
    echo "Installing iptables-persistent..."
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
    sudo apt-get update
    sudo apt-get install -y iptables-persistent
fi

# Save the rules
sudo netfilter-persistent save

echo "Port forwarding setup complete!"
echo "Access your application at:"
echo "- Frontend: http://shivajshankar1.duckdns.org:3000"
echo "- Backend:  http://shivajshankar1.duckdns.org:8080"
