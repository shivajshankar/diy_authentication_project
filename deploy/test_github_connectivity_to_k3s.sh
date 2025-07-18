# Get your public IP
PUBLIC_IP=$(curl -s ifconfig.me)

# Update k3s server URL to use public IP
sudo sed -i "s/--tls-san=.*/--tls-san=${PUBLIC_IP}/g" /etc/systemd/system/k3s.service

# Restart k3s
sudo systemctl daemon-reload
sudo systemctl restart k3s

# Update kubeconfig with public IP
sed -i "s|server:.*|server: https://${PUBLIC_IP}:6443|g" ~/.kube/config

# Get the updated kubeconfig
cat ~/.kube/config | base64 -w 0
