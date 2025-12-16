#!/bin/bash
set -euxo pipefail

# ----------------------------
# Base packages
# ----------------------------
apt-get update -y
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  docker.io \
  docker-compose \
  ufw

systemctl enable docker
systemctl start docker

# ----------------------------
# Install Harbor
# ----------------------------
mkdir -p /opt/harbor
cd /opt/harbor

HARBOR_VERSION="2.10.0"

curl -L -o harbor-online-installer.tgz \
  https://github.com/goharbor/harbor/releases/download/v${HARBOR_VERSION}/harbor-online-installer-v${HARBOR_VERSION}.tgz

tar xvf harbor-online-installer.tgz
cd harbor

cp harbor.yml.tmpl harbor.yml

PUBLIC_IP="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

# ----------------------------
# Harbor configuration (HTTP)
# ----------------------------
sed -i "s/^hostname:.*/hostname: ${PUBLIC_IP}/" harbor.yml

# Enable HTTP on port 80
sed -i 's/^#\?http:/http:/g' harbor.yml
sed -i 's/^#\?  port: 80/  port: 80/g' harbor.yml

# Remove HTTPS completely
sed -i '/^https:/,/^[a-zA-Z_].*:/{/^https:/d;/^[a-zA-Z_].*:/!d;}' harbor.yml || true
sed -i '/certificate:/d' harbor.yml || true
sed -i '/private_key:/d' harbor.yml || true

# Admin password
sed -i 's/^harbor_admin_password:.*/harbor_admin_password: StrongHarborPass123/' harbor.yml

# ----------------------------
# Install Harbor
# ----------------------------
./prepare
./install.sh --with-trivy

# ----------------------------
# Firewall rules (make 443 fail FAST)
# ----------------------------
ufw allow 22/tcp
ufw allow 80/tcp
ufw reject 443/tcp
ufw --force enable
