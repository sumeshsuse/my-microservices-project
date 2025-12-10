#!/bin/bash
set -euxo pipefail

# ----- Basic setup -----
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release \
                   docker.io docker-compose

systemctl enable docker
systemctl start docker

# ----- Install Harbor -----
mkdir -p /opt/harbor
cd /opt/harbor

HARBOR_VERSION="2.10.0"

# Download online installer if not already present
if [ ! -f "harbor-online-installer-v${HARBOR_VERSION}.tgz" ]; then
  curl -L -o harbor-online-installer-v${HARBOR_VERSION}.tgz \
    "https://github.com/goharbor/harbor/releases/download/v${HARBOR_VERSION}/harbor-online-installer-v${HARBOR_VERSION}.tgz"
fi

# Extract if harbor directory not present
if [ ! -d "harbor" ]; then
  tar xvf harbor-online-installer-v${HARBOR_VERSION}.tgz
fi

cd harbor

cp -f harbor.yml.tmpl harbor.yml

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Set hostname + disable HTTPS (HTTP only for now)
sed -i "s/^hostname:.*/hostname: ${PUBLIC_IP}/" harbor.yml
sed -i 's/^https:/#https:/g' harbor.yml
sed -i 's/^  port: 443/#  port: 443/g' harbor.yml
sed -i 's/^  certificate:/#  certificate:/g' harbor.yml
sed -i 's/^  private_key:/#  private_key:/g' harbor.yml

# Set a fixed admin password
sed -i 's/^harbor_admin_password:.*/harbor_admin_password: StrongHarborPass123/' harbor.yml

./prepare
./install.sh --with-trivy
