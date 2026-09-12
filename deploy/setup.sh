#!/usr/bin/env bash
# First-time server bootstrap for PulseChat on a fresh Ubuntu 24.04 VPS.
# Run this ONCE, as root, right after your first SSH login:
#   bash setup.sh
set -euo pipefail

echo "== Updating the system =="
apt update && apt upgrade -y

echo "== Installing Node.js 20 LTS =="
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs git ufw

echo "== Installing Caddy (automatic HTTPS) =="
apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install -y caddy

echo "== Creating a dedicated, unprivileged app user =="
id -u pulsechat &>/dev/null || useradd -r -m -d /opt/pulsechat -s /usr/sbin/nologin pulsechat

echo "== Creating persistent data directory (survives redeploys) =="
mkdir -p /data
chown -R pulsechat:pulsechat /data

echo "== Firewall: allow SSH, HTTP, HTTPS only =="
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo ""
echo "Done. Node: $(node -v)   Caddy: $(caddy version)"
echo "Next: copy your app code to /opt/pulsechat, then follow VPS_DEPLOY.md step 3 onward."
