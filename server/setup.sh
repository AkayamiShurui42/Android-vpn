#!/usr/bin/env bash
set -euo pipefail
# Ubuntu 24.04 server with a public IPv4 address hosted in Brazil.
if [[ $EUID -ne 0 ]]; then echo 'Run as root' >&2; exit 1; fi
if [[ -z "${PUBLIC_ENDPOINT:-}" ]]; then echo 'Set PUBLIC_ENDPOINT to the Brazilian server public IPv4 address' >&2; exit 1; fi
if [[ ! "$PUBLIC_ENDPOINT" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then echo 'PUBLIC_ENDPOINT must be IPv4' >&2; exit 1; fi
if [[ -e /etc/wireguard/wg0.conf ]]; then echo 'Refusing to overwrite existing WireGuard configuration' >&2; exit 1; fi
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y wireguard iptables curl
umask 077
install -d -m 700 /etc/wireguard /root/brazil-vpn
server_private=$(wg genkey)
server_public=$(printf '%s' "$server_private" | wg pubkey)
client_private=$(wg genkey)
client_public=$(printf '%s' "$client_private" | wg pubkey)
iface=$(ip -4 route show default | awk '/default/ {print $5; exit}')
if [[ -z "$iface" ]]; then echo 'No default IPv4 interface' >&2; exit 1; fi
cat > /etc/wireguard/wg0.conf <<CONFIG
[Interface]
Address = 10.77.0.1/24
ListenPort = 51820
PrivateKey = $server_private
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -s 10.77.0.0/24 -o $iface -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -s 10.77.0.0/24 -o $iface -j MASQUERADE

[Peer]
PublicKey = $client_public
AllowedIPs = 10.77.0.2/32
CONFIG
cat > /root/brazil-vpn/client.conf <<CONFIG
[Interface]
PrivateKey = $client_private
Address = 10.77.0.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = $server_public
Endpoint = $PUBLIC_ENDPOINT:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
CONFIG
chmod 600 /etc/wireguard/wg0.conf /root/brazil-vpn/client.conf
printf 'net.ipv4.ip_forward=1\n' >/etc/sysctl.d/99-brazil-wireguard.conf
sysctl --system >/dev/null
systemctl enable --now wg-quick@wg0
printf 'Client config: /root/brazil-vpn/client.conf\nOpen UDP 51820 in provider firewall. Never upload client config to GitHub.\n'
