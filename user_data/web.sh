#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Forcer IPv4 AVANT apt-get
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

apt-get update -y
apt-get install -y nginx

cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>${client_name}</title>
  <style>
    body{font-family:sans-serif;background:#1a1a2e;color:#e0e0e0;display:flex;align-items:center;justify-content:center;height:100vh;margin:0}
    .card{background:#16213e;border:1px solid #0f3460;border-radius:12px;padding:48px 64px;text-align:center}
    h1{color:#4fc3f7}
  </style>
</head>
<body>
  <div class="card">
    <h1>${client_name}</h1>
    <p>Serveur web opérationnel</p>
  </div>
</body>
</html>
HTML

systemctl enable nginx
systemctl restart nginx
