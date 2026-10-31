# Brazil WireGuard VPN

Android WireGuard VPN client with a GitHub Actions debug APK build and Ubuntu WireGuard server provisioning script.

## Setup

1. Provision an Ubuntu 24.04 VPS hosted in Brazil with a public IPv4 address.
2. Run `sudo PUBLIC_ENDPOINT=YOUR_SERVER_IPV4 bash server/setup.sh` on that server.
3. Keep `/root/brazil-vpn/client.conf` secret and import its contents into the Android app.
4. Build via GitHub Actions (`Build Android APK`) and download the debug APK artifact.

**Security:** Never commit private keys or `client.conf`. This app is not a commercial VPN service. A Brazilian IP is only possible with a functioning Brazilian exit server.
