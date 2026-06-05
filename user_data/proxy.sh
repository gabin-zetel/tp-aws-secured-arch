#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y squid
cat > /etc/squid/squid.conf <<'EOF'
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 443
acl CONNECT method CONNECT
acl clients_vpc src 10.1.0.0/16
acl clients_vpc src 10.2.0.0/16
acl pkg_repos dstdomain .ubuntu.com
acl pkg_repos dstdomain .debian.org
acl pkg_repos dstdomain security.ubuntu.com
acl pkg_repos dstdomain archive.ubuntu.com
acl pkg_repos dstdomain esm.ubuntu.com
acl pkg_repos dstdomain .pypi.org
acl pkg_repos dstdomain files.pythonhosted.org
acl pkg_repos dstdomain .npmjs.org
acl pkg_repos dstdomain registry.npmjs.org
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow clients_vpc pkg_repos
http_access deny all
http_port 3128
access_log /var/log/squid/access.log
cache deny all
EOF
systemctl enable squid
systemctl restart squid
