#!/bin/bash

# INSTALL KUBERNETES ON ubuntu Master

# Exit on error, undefined variable, or error in any pipeline
set -euxo pipefail

# Set Hostname
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && sudo hostnamectl set-hostname $(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-hostname)


# Update package manager
sudo apt-get update && sudo apt-get upgrade -y

# Install necessary packages
sudo apt-get update && sudo apt-get install -y apt-transport-https curl

# Install Docker
sudo apt-get install docker.io -y 

# Enable Docker
sudo systemctl enable docker

# Start Docker
sudo systemctl start docker

# Disable Swap on all nodes
sudo swapoff -a

# Install kubeadm, kubelet, and kubectl

# Add Google's public signing key
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Add Kubernetes GPG key
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg - dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

apt-get install gpg


sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package list
sudo apt-get update

# Install kubelet, kubeadm and kubectl
sudo apt-get install -y kubelet kubeadm kubectl

# Hold these packages at their installed version
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

sudo systemctl restart kubelet


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

sleep 60

kubectl get nodes

echo " K8s Master Setup has completed"