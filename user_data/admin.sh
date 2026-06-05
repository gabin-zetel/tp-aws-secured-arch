#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y openssh-client curl wget jq awscli ansible git tmux vim
cat > /etc/ssh/ssh_config.d/jump.conf <<EOF
Host 10.1.*
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
Host 10.2.*
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
EOF
echo "Admin ready" > /var/log/bootstrap.log
