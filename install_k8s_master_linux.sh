#!/bin/bash

# INSTALL KUBERNETES ON AMAZON LINUX 2 + (WORKER NODE)

# Update package manager
yum update -y

# Install Docker
sudo yum install docker -y 

# Enable Docker
sudo systemctl enable docker

# Start Docker
sudo systemctl start docker

# Disable Swap on all nodes
 swapoff -a

# Install kubeadm, kubelet, and kubectl

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# This overwrites any existing configuration in /etc/yum.repos.d/kubernetes.repo
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl enable --now kubelet

sudo systemctl restart kubelet

# Prompt user for API server advertise address
read -p "Enter the API server advertise address (i.e private ipv4 address e.g., 172.31.47.64): " apiserver_address

# Initialize the Master Node with user-provided address
sudo kubeadm init --apiserver-advertise-address=$apiserver_address --pod-network-cidr=192.168.0.0/16

# Set up the local kubeconfig file
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico Network Plugin

# Download the Calico manifest
curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/calico-typha.yaml -o calico.yaml

# Apply the Calico network plugin manifest
kubectl apply -f calico.yaml
