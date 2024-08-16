#!/bin/bash

# INSTALL KUBERNETES ON ubuntu Worker

# Set Hostname
# TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && sudo hostnamectl set-hostname $(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-hostname)

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