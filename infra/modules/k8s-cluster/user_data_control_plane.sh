#!/bin/bash
set -euxo pipefail

# Disable swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg

cat <<EOT >/etc/modules-load.d/k8s.conf
br_netfilter
EOT

modprobe br_netfilter

cat <<EOT >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOT

sysctl --system

# containerd
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Kubernetes repo
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" > /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Init control plane (using a fixed token so workers can join)
kubeadm init \
  --apiserver-advertise-address=${INTERNAL_IP} \
  --pod-network-cidr=192.168.0.0/16 \
  --token=abcdef.0123456789abcdef \
  --token-ttl=0

mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

sudo -u ubuntu kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
