#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx
rm -f /etc/nginx/sites-enabled/default
mkdir -p /etc/nginx/sites-clients
cat > /etc/nginx/sites-available/base.conf <<'EOF'
server {
    listen 80 default_server;
    server_name _;
    location /health {
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
    location / { return 444; }
}
EOF
ln -s /etc/nginx/sites-available/base.conf /etc/nginx/sites-enabled/base.conf
echo 'include /etc/nginx/sites-clients/*.conf;' >> /etc/nginx/nginx.conf
nginx -t
systemctl enable nginx
systemctl restart nginx
