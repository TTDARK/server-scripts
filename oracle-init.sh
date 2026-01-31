#!/bin/bash
# oracle-optimized-init.sh - Simplified version

set -e

export SSHKEY_URL="https://sshid.io/ttdark"  # REPLACE THIS WITH YOUR SSH.ID URL

echo "=== Oracle Cloud Server Initialization ==="
echo "Installing latest Debian LTS with Docker pre-configured"
echo ""

# Download debi.sh
curl -fLO https://raw.githubusercontent.com/bohanyang/debi/master/debi.sh
chmod +x debi.sh

# Create systemd service for Tailscale post-reboot setup
sudo mkdir -p /tmp/debi-post-install
sudo tee /tmp/debi-post-install/tailscale-setup.service > /dev/null << 'SYSTEMD_EOF'
[Unit]
Description=Tailscale Post-Install Setup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'curl -fsSL https://tailscale.com/install.sh | sh && echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.d/99-tailscale.conf && echo "net.ipv6.conf.all.forwarding = 1" | tee -a /etc/sysctl.d/99-tailscale.conf && sysctl -p /etc/sysctl.d/99-tailscale.conf && systemctl disable tailscale-setup.service'

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

# Run debi installation with optimal settings
sudo ./debi.sh \
  --user root \
  --authorized-keys-url "$SSHKEY_URL" \
  --timezone Europe/Berlin \
  --install 'curl ca-certificates docker.io docker-compose' \
  --bbr \
  --cdn \
  --firmware

echo ""
echo "=== Debian installation initiated ==="
echo "System will reboot into fresh Debian with Docker pre-installed"
echo "After reboot: SSH as root, then run 'tailscale up --advertise-exit-node --accept-routes --ssh'"
