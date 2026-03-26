#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo bash <<'EOF'
apt-get update 
apt-get upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"
rm -f /etc/ssh/ssh_host_*

cloud-init clean --logs || true

rm -rf /tmp/* /var/tmp/*
history -c
unset HISTFILE

rm -f /etc/machine-id
rm -f /var/lib/dbus/machine-id

# Initialize a fresh machine ID
if [ "$(pidof systemd)" ]; then
    systemd-machine-id-setup
fi

find /var/log -type f -exec truncate -s 0 {} \; || true

apt-get autoremove -y
apt-get autoclean -y
apt-get clean -y
rm -rf /var/lib/apt/lists/*

echo "Instance preparation complete. Ready for AMI creation."
EOF