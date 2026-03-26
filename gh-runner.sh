#!/bin/bash
set -e

cat > /etc/github-runner.env <<EOF
RUNNER_LABELS=non-prod
PRIVATE_KEY_SECRET_NAME=github-runner-private-key
CONFIG_SECRET_NAME=/github-runner/config
EOF

systemctl start github-runner
