#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y openvpn easy-rsa iptables-persistent
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p
mkdir -p /etc/openvpn/easy-rsa
cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
cd /etc/openvpn/easy-rsa
cat > vars <<EOF
set_var EASYRSA_ALGO       ec
set_var EASYRSA_CURVE      prime256v1
set_var EASYRSA_CA_EXPIRE  3650
set_var EASYRSA_CERT_EXPIRE 825
EOF
./easyrsa init-pki
echo "SecuredArch-CA" | ./easyrsa build-ca nopass
./easyrsa gen-dh
./easyrsa build-server-full server nopass
openvpn --genkey secret /etc/openvpn/ta.key
cp pki/ca.crt            /etc/openvpn/
cp pki/issued/server.crt /etc/openvpn/
cp pki/private/server.key /etc/openvpn/
cp pki/dh.pem            /etc/openvpn/
cat > /etc/openvpn/server.conf <<EOF
port 1194
proto udp
dev tun
ca   /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key  /etc/openvpn/server.key
dh   /etc/openvpn/dh.pem
tls-auth /etc/openvpn/ta.key 0
cipher AES-256-GCM
auth   SHA256
server ${vpn_subnet} ${vpn_mask}
push "route 10.0.2.0 255.255.255.0"
push "route 10.0.3.0 255.255.255.0"
keepalive 10 120
persist-key
persist-tun
user  nobody
group nogroup
status /var/log/openvpn-status.log
verb 3
EOF
iptables -t nat -A POSTROUTING -s ${vpn_subnet}/24 -o eth0 -j MASQUERADE
iptables-save > /etc/iptables/rules.v4
systemctl enable openvpn@server
systemctl start  openvpn@server
