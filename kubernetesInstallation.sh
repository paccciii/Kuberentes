#!/bin/bash

# 1. Set hostname
hostnamectl set-hostname <name>

# 2. Disable swap on all VMs
sudo swapoff -a
sudo sed -i '/\sswap\s/s/^/#/' /etc/fstab

# 3. Installing containerd
wget https://github.com/containerd/containerd/releases/download/v2.5.0/containerd-2.5.0-linux-amd64.tar.gz
sudo tar Cxzvf containerd-2.5.0-linux-amd64.tar.gz -C /usr/local

# 4. Install and enable containerd service
sudo wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -O /etc/systemd/system/containerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# 5. Installing runc
wget https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

# 6. Install CNI plugins
wget https://github.com/containernetworking/plugins/releases/download/v1.4.1/cni-plugins-linux-amd64-v1.4.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf cni-plugins-linux-amd64-v1.4.1.tgz -C /opt/cni/bin

# 7. Install crictl
VERSION="v1.26.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz

# 8. Configure crictl socket
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: true
pull-image-on-create: false
EOF

# 9. Forwarding IPv4 and letting iptables see bridge traffic
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# 10. Verify module loading
lsmod | grep br_netfilter
lsmod | grep overlay

# 11. Install kubeadm, kubectl, kubelet
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

# 12. Initialize Kubernetes control plane
sudo kubeadm config images pull
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# 13. Set up kubeconfig for regular user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 14. Install Calico for pod networking
kubectl create -f https://docs.projectcalico.org/v3.27/manifests/calico.yaml

# 15. Control plane node isolation
kubectl taint nodes --all node-role.kubernetes.io/master-

# 16. Instructions for joining worker nodes
echo "Now, to add worker nodes, run the join command provided after kubeadm init completes."
