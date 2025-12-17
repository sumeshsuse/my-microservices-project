#!/bin/bash
set -euxo pipefail

# Disable swap (required for kubeadm)
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg git

# Pull your Git repo (public) - non-blocking so cluster bootstrap won't fail if GitHub is temporarily unreachable
REPO_URL="https://github.com/sumeshsuse/my-microservices-project.git"
DEST_DIR="/opt/my-microservices-project"

mkdir -p /opt
if [ ! -d "$DEST_DIR/.git" ]; then
  git clone "$REPO_URL" "$DEST_DIR" || true
else
  cd "$DEST_DIR"
  git pull origin main || true
fi
chown -R ubuntu:ubuntu "$DEST_DIR" || true

# Kernel modules and sysctl for Kubernetes networking
cat <<EOT >/etc/modules-load.d/k8s.conf
br_netfilter
EOT

modprobe br_netfilter

cat <<EOT >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOT

sysctl --system

# containerd runtime
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Kubernetes apt repo (v1.30 stable)
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Init control plane
kubeadm init \
  --apiserver-advertise-address=${INTERNAL_IP} \
  --pod-network-cidr=192.168.0.0/16 \
  --token=abcdef.0123456789abcdef \
  --token-ttl=0

# Configure kubectl for ubuntu user
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# ✅ Configure kubectl for root too (so sudo kubeadm/kubectl works)
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config

# Install Calico CNI (use explicit kubeconfig)
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
