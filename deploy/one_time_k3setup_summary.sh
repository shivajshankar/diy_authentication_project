#!/bin/bash
# k3s_setup_and_config.sh
# A comprehensive script to set up k3s and generate kubeconfig for GitHub Actions

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Starting k3s Setup and Configuration ===${NC}"

# Get server information
PUBLIC_IP=$(curl -s ifconfig.me)
DOMAIN="shivajshankar1.duckdns.org"

echo -e "\n${GREEN}[1/4] Configuring k3s server...${NC}"

# Stop k3s if running
echo "Stopping k3s service..."
sudo systemctl stop k3s 2>/dev/null || true

# Create backup of existing config
echo "Creating backup of existing k3s config..."
sudo mkdir -p /etc/rancher/k3s/backup
sudo cp /etc/rancher/k3s/k3s.yaml /etc/rancher/k3s/backup/k3s.yaml.$(date +%Y%m%d%H%M%S) 2>/dev/null || true

# Create systemd override directory
echo "Creating systemd override..."
sudo mkdir -p /etc/systemd/system/k3s.service.d

# Create k3s service override
echo "Configuring k3s service..."
sudo bash -c "cat > /etc/systemd/system/k3s.service.d/override.conf" << EOF
[Service]
ExecStart=
ExecStart=/usr/local/bin/k3s server \\
  --tls-san=${PUBLIC_IP} \\
  --tls-san=${DOMAIN} \\
  --write-kubeconfig-mode=644 \\
  --kube-apiserver-arg=anonymous-auth=true
EOF

# Reload systemd and restart k3s
echo "Reloading systemd and starting k3s..."
sudo systemctl daemon-reload
sudo systemctl start k3s

# Wait for k3s to start
echo "Waiting for k3s to start..."
sleep 10

# Verify k3s status
echo -e "\n${GREEN}k3s Status:${NC}"
sudo systemctl status k3s --no-pager

echo -e "\n${GREEN}[2/4] Setting up local kubeconfig...${NC}"

# Create .kube directory
mkdir -p ~/.kube

# Create kubeconfig
echo "Creating kubeconfig..."
cat > ~/.kube/config << EOF
apiVersion: v1
kind: Config
clusters:
- name: default
  cluster:
    server: https://${DOMAIN}:6443
    certificate-authority-data: $(sudo cat /var/lib/rancher/k3s/server/tls/server-ca.crt | base64 -w0)
contexts:
- name: default
  context:
    cluster: default
    user: default
current-context: default
users:
- name: default
  user:
    client-certificate-data: $(sudo cat /var/lib/rancher/k3s/server/tls/client-admin.crt | base64 -w0)
    client-key-data: $(sudo cat /var/lib/rancher/k3s/server/tls/client-admin.key | base64 -w0)
EOF

# Set permissions
chmod 600 ~/.kube/config

# Verify cluster access
echo -e "\n${GREEN}Cluster Information:${NC}"
kubectl cluster-info
echo -e "\n${GREEN}Nodes:${NC}"
kubectl get nodes

echo -e "\n${GREEN}[3/4] Creating GitHub kubeconfig...${NC}"

# Create GitHub kubeconfig
echo "Generating GitHub kubeconfig..."
cat > ~/github-kubeconfig.yaml << EOF
apiVersion: v1
kind: Config
clusters:
- name: default
  cluster:
    server: https://${DOMAIN}:6443
    certificate-authority-data: $(sudo cat /var/lib/rancher/k3s/server/tls/server-ca.crt | base64 -w0)
contexts:
- name: default
  context:
    cluster: default
    user: default
current-context: default
users:
- name: default
  user:
    client-certificate-data: $(sudo cat /var/lib/rancher/k3s/server/tls/client-admin.crt | base64 -w0)
    client-key-data: $(sudo cat /var/lib/rancher/k3s/server/tls/client-admin.key | base64 -w0)
EOF

# Process the template
eval "echo \"$(cat ~/github-kubeconfig.yaml)\"" > ~/github-kubeconfig-processed.yaml

echo -e "\n${GREEN}[4/4] Generating GitHub Secret...${NC}"

# Encode kubeconfig for GitHub Secret
echo "Base64-encoded kubeconfig for GitHub Secret:"
echo "------------------------------------------"
cat ~/github-kubeconfig-processed.yaml | base64 -w0
echo -e "\n------------------------------------------"

echo -e "\n${GREEN}=== Setup Complete! ===${NC}"
echo -e "1. Copy the base64 output above"
echo -e "2. Go to your GitHub repository"
echo -e "3. Settings > Secrets > Actions"
echo -e "4. Update the KUBE_CONFIG secret with the copied value"
echo -e "\n${YELLOW}Note:${NC} Make sure to open port 6443 in your firewall for GitHub Actions IPs"
