#!/bin/bash
set -euxo pipefail

# --- Basic OS prep ---
swapoff -a || true
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab || true

apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg git conntrack ipset iptables

# --- Pull your Git repo (non-blocking) ---
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

# --- Kernel modules + sysctl (MUST for CNI) ---
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

# --- containerd ---
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# --- Kubernetes repo (v1.30) ---
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# --- kubeadm init ---
kubeadm init \
  --apiserver-advertise-address="${INTERNAL_IP}" \
  --pod-network-cidr=192.168.0.0/16 \
  --token=abcdef.0123456789abcdef \
  --token-ttl=0

# --- kubeconfig for ubuntu + root ---
mkdir -p /home/ubuntu/.kube
cp -f /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

mkdir -p /root/.kube
cp -f /etc/kubernetes/admin.conf /root/.kube/config
chown -R root:root /root/.kube

# --- Install Calico (match your running version) ---
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml

# Optional: wait a bit for system pods
kubectl --kubeconfig=/etc/kubernetes/admin.conf -n kube-system rollout status deploy/coredns --timeout=180s || true
kubectl --kubeconfig=/etc/kubernetes/admin.conf -n kube-system rollout status ds/calico-node --timeout=300s || true

# --- Print join command into a file (for manual use/debug) ---
kubeadm token create --print-join-command > /opt/kubeadm_join.sh || true
chmod +x /opt/kubeadm_join.sh || true
