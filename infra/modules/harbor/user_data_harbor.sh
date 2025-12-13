#!/bin/bash
set -euxo pipefail

# ----- Basic setup -----
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release \
                   docker.io docker-compose openssl

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

PUBLIC_IP="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

# ----- TLS cert (self-signed) -----
mkdir -p /data/cert
cd /data/cert

cat > openssl.cnf <<EOF
[req]
default_bits       = 4096
prompt             = no
default_md         = sha256
distinguished_name = dn
x509_extensions    = v3_req

[dn]
C=DE
ST=Bavaria
L=Munich
O=DevOps
OU=Harbor
CN=${PUBLIC_IP}

[v3_req]
subjectAltName = @alt_names

[alt_names]
IP.1 = ${PUBLIC_IP}
EOF

openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
  -keyout /data/cert/harbor.key \
  -out /data/cert/harbor.crt \
  -config /data/cert/openssl.cnf

chmod 600 /data/cert/harbor.key

# ----- Configure Harbor -----
cd /opt/harbor/harbor

# Set hostname to public IP
sed -i "s/^hostname:.*/hostname: ${PUBLIC_IP}/" harbor.yml

# Ensure HTTP stays enabled on port 80 (default in template usually)
# (no change needed unless you previously edited it)

# Enable HTTPS on 443 and point to our certs
# If template already has https block, this will set the values.
# If lines are missing, the sed won't add them (template normally includes them).
sed -i 's/^#\?https:/https:/g' harbor.yml
sed -i 's/^#\?  port: 443/  port: 443/g' harbor.yml
sed -i "s|^#\?  certificate:.*|  certificate: /data/cert/harbor.crt|g" harbor.yml
sed -i "s|^#\?  private_key:.*|  private_key: /data/cert/harbor.key|g" harbor.yml

# Set a fixed admin password
sed -i 's/^harbor_admin_password:.*/harbor_admin_password: StrongHarborPass123/' harbor.yml

# ----- Install Harbor -----
./prepare
./install.sh --with-trivy
