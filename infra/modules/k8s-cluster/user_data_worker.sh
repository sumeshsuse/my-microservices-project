#!/bin/bash
set -euxo pipefail

swapoff -a || true
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab || true

apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg conntrack ipset iptables

# Kernel modules + sysctl
cat <<'EOT' >/etc/modules-load.d/k8s.conf
br_netfilter
EOT

modprobe br_netfilter || true

cat <<'EOT' >/etc/sysctl.d/k8s.conf
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOT

sysctl --system

# containerd
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Kubernetes repo (v1.30)
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

# ✅ Terraform substitutes this placeholder via templatefile()
CONTROL_PLANE_IP="${CONTROL_PLANE_IP}"

# Join (lab/dev friendly)
kubeadm join "${CONTROL_PLANE_IP}:6443" \
  --token abcdef.0123456789abcdef \
  --discovery-token-unsafe-skip-ca-verification
