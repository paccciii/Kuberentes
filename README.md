# Kuberentes
Kubernetes installation process
# 1.set hostname:
hostnamectl set-hostname <name>


#disable swap off on all vms:

sudo swapoff -a
sudo sed -i '/\sswap\s/s/^/#/' /etc/fstab





# 2. installing contaianerd

https://github.com/containerd/containerd/releases/download/v2.0.0-rc.0/containerd-2.0.0-rc.0-linux-amd64.tar.gz

$ tar Cxzvf /usr/local containerd-1.6.2-linux-amd64.tar.gz
bin/
bin/containerd-shim-runc-v2
bin/containerd-shim 
bin/ctr
bin/containerd-shim-runc-v1
bin/containerd
bin/containerd-stress

# 3.installing contaianerd
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service cp /usr/local/lib/systemd/system/containerd.service

systemctl daemon-reload
systemctl enable --now containerd


# 4.installing runc
wget https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64
$ install -m 755 runc.amd64 /usr/local/sbin/runc


# 5.cni plugins


https://github.com/containernetworking/plugins/releases/download/v1.4.1/cni-plugins-linux-amd64-v1.4.1.tgz
$ mkdir -p /opt/cni/bin
$ tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz
./
./macvlan
./static
./vlan
./portmap
./host-local
./vrf
./bridge
./tuning
./firewall
./host-device
./sbr
./loopback
./dhcp
./ptp
./ipvlan
./bandwidth

# 6.Installing crictl

VERSION="v1.26.0" # check latest version in /releases page
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz

# 7.crictl needs a socket to talk to the containerd


cat /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: true
pull-image-on-create: false

# 8.Forwarding IPv4 and letting iptables see bridge traffic:

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 9.sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# 10.Verify that the br_netfilter, overlay modules are loaded by running the following commands:

lsmod | grep br_netfilter
lsmod | grep overlay

# 11.Apply sysctl params without reboot
sudo sysctl --system
installing kubeadm kubectl kubelet

sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# 12.this step is optional: 
sudo systemctl enable --now kubelet


# 13. Run on master node
kubeadm config images pull 
kubeadm init  (there are many arguments that can be passed here like;<--apiserver-advertise-address> for choosing the ip of master node when there are multiple IPs present and --control-plane-endpoint can be used to set the shared endpoint for all control-plane nodes.  )

(#Initialize the control plane using the following command.

sudo kubeadm init --pod-network-cidr=192.168.0.0/16

NOTE
If 192.168.0.0/16 is already in use within your network you must select a different pod network CIDR, replacing 192.168.0.0/16 in the above command.)

#basically master node used port 6443(API-server port) to communicate with the workers nodes and this port needs to be opened in the worker node too

Your Kubernetes control-plane has initialized successfully!

# 14.To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  
 15. Installing Calico(Pod Network Addon)
 You must deploy a Container Network Interface (CNI) based Pod network add-on so that your Pods can communicate with each other. Cluster DNS (CoreDNS) will not start up before a network is installed.


 kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/tigera-operator.yaml
 
 watch kubectl get pods -n calico-system
  

  
16. 
Control plane node isolation 
By default, your cluster will not schedule Pods on the control plane nodes for security reasons. If you want to be able to schedule Pods on the control plane nodes, for example for a single machine Kubernetes cluster, run:

kubectl taint nodes --all node-role.kubernetes.io/control-plane-
The output will look something like:

node "test-01" untainted

17. 
Joining your nodes
The nodes are where your workloads (containers and Pods, etc) run. To add new nodes to your cluster do the following for each machine:

SSH to the machine

Become root (e.g. sudo su -)

Install a runtime if needed

Run the command that was output by kubeadm init. For example:
kubeadm join --token <token> <control-plane-host>:<control-plane-port> --discovery-token-ca-cert-hash sha256:<hash>

If you do not have the token, you can get it by running the following command on the control-plane node:

kubeadm token list
