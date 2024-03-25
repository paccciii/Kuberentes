Here's the corrected README.md file incorporating the provided instructions:

```markdown
# Kubernetes Cluster Setup with RKE

This repository contains instructions and scripts for setting up a Kubernetes cluster using RKE (Rancher Kubernetes Engine).

## 1. Adjust Sysctl Parameters

Before proceeding, review the current system parameters using `sysctl -a` and adjust them if necessary. For example, to enable `net.bridge.bridge-nf-call-iptables`, use:

```bash
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
```

To persist changes after reboot, edit the sysctl configuration file:

```bash
sudo vi /etc/sysctl.d/99-kubernetes-params.conf
```

## 2. Download and Install RKE

Download the latest RKE binary and install it:

```bash
wget https://github.com/rancher/rke/releases/download/v1.5.6/rke_linux-amd64
chmod +x rke_linux-amd64
sudo mv rke_linux-amd64 /usr/local/bin/rke
rke --version
```

## 3. Install Docker Engine

Ensure Docker Engine is installed and running with necessary permissions:

```bash
sudo apt update && \
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
sudo apt update && \
sudo apt install -y docker-ce docker-ce-cli containerd.io && \
sudo systemctl start docker && \
sudo systemctl enable docker && \
docker --version
```

## 4. Grant Docker Group Permissions

Ensure the SSH user has permissions to access Docker:

```bash
sudo usermod -aG docker <user_name>
```

## 5. Configure RKE Cluster

Run `rke config` to create the `cluster.yml` configuration file. Provide the requested information to configure your cluster.

```bash
rke config
vi cluster.yml
```

## 6. High Availability Setup

To set up a highly available cluster, specify multiple control plane nodes in the `cluster.yml` file.

## 7. Deploy Kubernetes Cluster

After configuring the `cluster.yml` file, deploy the Kubernetes cluster:

```bash
rke up
```

## 8. Interact with Kubernetes Cluster

Use the generated kubeconfig file to interact with your Kubernetes cluster using `kubectl`.

## 9. Install Rancher Server

Follow these steps to install Rancher Server using Helm:

```bash
# Download and install Helm
wget https://get.helm.sh/helm-v3.7.1-linux-amd64.tar.gz || curl -LO https://get.helm.sh/helm-v3.7.1-linux-amd64.tar.gz
tar -zxvf helm-v3.7.1-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
helm version

# Add Helm repository for Rancher
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable

# Create Namespace for Rancher
kubectl create namespace cattle-system

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/<VERSION>/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true

# Install Rancher using Helm
helm install rancher rancher-stable/rancher --namespace cattle-system --set hostname=rancher.my.org --set bootstrapPassword=admin

# Verify Rancher deployment
kubectl -n cattle-system rollout status deploy/rancher
```

## 10. Verify Rancher Deployment

Check if Rancher was successfully deployed:

```bash
kubectl -n cattle-system rollout status deploy/rancher
```

If Rancher is successfully rolled out, you should see the deployment status as completed.

---

These instructions guide you through setting up a Kubernetes cluster with RKE and installing Rancher Server. Feel free to contribute and provide feedback.
```

This README.md file incorporates the provided instructions, correcting typos and organizing the content for clarity. It guides users through the process of setting up a Kubernetes cluster with RKE and installing Rancher Server, providing detailed steps and explanations along the way.
