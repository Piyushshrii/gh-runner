#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

sudo bash <<'EOF'
set -euxo pipefail

RUNNER_DIR=/home/ubuntu/actions-runner
RUNNER_VERSION="2.317.0"

# ===== DEPS + RUNNER BINARY =====
apt-get update -y && apt-get install -y curl jq openssl unzip
mkdir -p $RUNNER_DIR
curl -fL -o $RUNNER_DIR/runner.tar.gz \
  https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
tar xzf $RUNNER_DIR/runner.tar.gz -C $RUNNER_DIR
chown -R ubuntu:ubuntu $RUNNER_DIR

# ===== REGISTER SCRIPT =====
cat > /usr/local/bin/github-runner-register.sh <<'SCRIPT'
#!/bin/bash
set -e

source /etc/github-runner.env
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

b64() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

rm -f /tmp/k.pem
aws secretsmanager get-secret-value --region $REGION --secret-id $PRIVATE_KEY_SECRET_NAME \
  --query SecretString --output text > /tmp/k.pem && chmod 600 /tmp/k.pem

CONFIG=$(aws secretsmanager get-secret-value --region $REGION \
  --secret-id $CONFIG_SECRET_NAME --query SecretString --output text)
APP_ID=$(echo $CONFIG | jq -r .app_id)
INSTALLATION_ID=$(echo $CONFIG | jq -r .installation_id)
ORG=$(echo $CONFIG | jq -r .org)

NOW=$(date +%s)
H=$(printf '{"alg":"RS256","typ":"JWT"}' | b64)
P=$(printf '{"iat":%s,"exp":%s,"iss":"%s"}' $NOW $((NOW+540)) $APP_ID | b64)
S=$(printf '%s.%s' $H $P | openssl dgst -sha256 -sign /tmp/k.pem | b64)

IT=$(curl -s -X POST -H "Authorization: Bearer $H.$P.$S" -H "Accept: application/vnd.github+json" \
  https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens | jq -r .token)

RTOKEN=$(curl -s -X POST -H "Authorization: Bearer $IT" -H "Accept: application/vnd.github+json" \
  https://api.github.com/orgs/$ORG/actions/runners/registration-token | jq -r .token)

PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
cd /home/ubuntu/actions-runner
./config.sh --url https://github.com/$ORG --token $RTOKEN \
  --labels $RUNNER_LABELS --unattended --name "non-prod-${PRIVATE_IP}"
SCRIPT

# ===== DEREGISTER SCRIPT =====
cat > /usr/local/bin/github-runner-deregister.sh <<'SCRIPT'
#!/bin/bash
set -e

source /etc/github-runner.env
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

b64() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

rm -f /tmp/k.pem
aws secretsmanager get-secret-value --region $REGION --secret-id $PRIVATE_KEY_SECRET_ARN \
  --query SecretString --output text > /tmp/k.pem && chmod 600 /tmp/k.pem

CONFIG=$(aws ssm get-parameter --region $REGION \
  --name $CONFIG_SECRET_ARN --query Parameter.Value --output text)
APP_ID=$(echo $CONFIG | jq -r .app_id)
INSTALLATION_ID=$(echo $CONFIG | jq -r .installation_id)
ORG=$(echo $CONFIG | jq -r .org)

NOW=$(date +%s)
H=$(printf '{"alg":"RS256","typ":"JWT"}' | b64)
P=$(printf '{"iat":%s,"exp":%s,"iss":"%s"}' $NOW $((NOW+540)) $APP_ID | b64)
S=$(printf '%s.%s' $H $P | openssl dgst -sha256 -sign /tmp/k.pem | b64)

IT=$(curl -s -X POST -H "Authorization: Bearer $H.$P.$S" -H "Accept: application/vnd.github+json" \
  https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens | jq -r .token)

RTOKEN=$(curl -s -X POST -H "Authorization: Bearer $IT" -H "Accept: application/vnd.github+json" \
  https://api.github.com/orgs/$ORG/actions/runners/registration-token | jq -r .token)

cd /home/ubuntu/actions-runner
./config.sh remove --unattended --token $RTOKEN
rm -f /tmp/k.pem
SCRIPT

chmod +x /usr/local/bin/github-runner-{register,deregister}.sh

# ===== SYSTEMD SERVICE =====
cat > /etc/systemd/system/github-runner.service <<'SERVICE'
[Unit]
Description=GitHub Actions Runner
After=network.target
[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/actions-runner
EnvironmentFile=/etc/github-runner.env
ExecStartPre=/usr/local/bin/github-runner-register.sh
ExecStart=/home/ubuntu/actions-runner/run.sh
ExecStop=/usr/local/bin/github-runner-deregister.sh
Restart=on-failure
StandardOutput=journal
[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload && systemctl disable github-runner
EOF