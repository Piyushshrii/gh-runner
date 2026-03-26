#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Run as root properly (keep your structure but safe)
sudo bash <<'EOF'
# Install AWS CLI
curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

echo "===== Installing CloudWatch Agent ====="

curl -sSL -o /tmp/cloudwatch.deb \
"https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb"

dpkg -i /tmp/cloudwatch.deb || apt-get install -f -y
rm -f /tmp/cloudwatch.deb

# PATH fix
echo 'export PATH=/usr/local/bin:/usr/bin:/bin' > /etc/profile.d/custom_path.sh
chmod +x /etc/profile.d/custom_path.sh

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/*

echo "===== Installation complete! ====="

EOF