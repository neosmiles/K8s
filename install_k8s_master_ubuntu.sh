#!/bin/bash

# INSTALL KUBERNETES ON ubuntu Master

# set hostname
sudo hostnamectl set-hostname \
$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# Update package manager
sudo apt-get update -y

# Install Docker
sudo apt-get install docker.io -y 

# Enable Docker
sudo systemctl enable docker

# Start Docker
sudo systemctl start docker

# Disable Swap on all nodes
sudo swapoff -a

# Install kubeadm, kubelet, and kubectl

# Install required packages
sudo apt-get install -y apt-transport-https ca-certificates curl

# Add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package list
sudo apt-get update

# Install kubelet, kubeadm and kubectl
sudo apt-get install -y kubelet kubeadm kubectl

# Hold these packages at their installed version
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

sudo systemctl restart kubelet

# Prompt user for API server advertise address
# read -p "Enter the API server advertise address (i.e private ipv4 address e.g., 172.31.47.64): " apiserver_address

# Initialize the Master Node with user-provided address
#sudo kubeadm init --apiserver-advertise-address=$apiserver_address --pod-network-cidr=192.168.0.0/16

# Setup Network with AWS provider
cat << EOF > /etc/kubernetes/aws.yaml  
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
networking:
  serviceSubnet: "10.0.0.0/16"
  podSubnet: "10.100.0.0/24"
apiServer:
  extraArgs:
    cloud-provider: "aws"
controllerManager:
  extraArgs:
    cloud-provider: "aws"
EOF

kubeadm init --config /etc/kubernetes/aws.yaml

# Set up the local kubeconfig file
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico Network Plugin

# Download the Calico manifest
curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/calico-typha.yaml -o calico.yaml

# Apply the Calico network plugin manifest
kubectl apply -f calico.yaml
