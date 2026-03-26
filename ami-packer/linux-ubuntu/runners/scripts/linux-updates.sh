#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo bash <<'EOF'
echo "Updating and upgrading Ubuntu packages..."
apt-get update -y
apt-get upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"

apt-get autoremove -y
apt-get autoclean -y
apt-get clean -y
rm -rf /var/lib/apt/lists/*

echo "Ubuntu updates complete!"
EOF