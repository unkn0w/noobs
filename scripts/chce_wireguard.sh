#!/bin/bash
# Autor skryptu: Andrzej Szczepaniak
# Współautor: Jakub 'unknow' Mrugalski
# Aktualizacja paczek go, wg: Dawid Kasza

# Backup the current resolv.conf file
cp /etc/resolv.conf /etc/resolv.back

# Update the package list and install necessary packages
apt update
apt install -y --no-install-recommends libmnl-dev make qrencode wireguard-tools resolvconf git iptables

# Stop and disable resolvconf
systemctl stop resolvconf
systemctl disable resolvconf

# Restore the original resolv.conf file
mv /etc/resolv.back /etc/resolv.conf

# Check for the presence of TUN/TAP device
if [ ! -e /dev/net/tun ]; then
   echo "To use Wireguard, you must enable TUN/TAP on your server."
   exit 1
fi

# Download and install Wireguard-Go
cd /tmp/ || exit
wget https://github.com/WireGuard/wireguard-go/archive/refs/heads/master.zip
unzip master.zip -d wireguard-go
rm master.zip

# Clone the Wireguard tools repository
git -c http.sslVerify=false clone https://git.zx2c4.com/wireguard-tools /tmp/wireguard-tools

# Download and install Go
wget https://go.dev/dl/go1.21.1.linux-amd64.tar.gz -O /tmp/go1.21.1.linux-amd64.tar.gz

tar -zxf go1.21.1.linux-amd64.tar.gz
mv /tmp/go /usr/local
export GOROOT=/usr/local/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Create a symlink for Go
ln -s /usr/local/go/bin/go /usr/bin/

# Build and install Wireguard tools
cd /tmp/wireguard-tools/src/ || exit
make
make install

# Build Wireguard-Go
cd /tmp/wireguard-go || exit
make

# Copy Wireguard-Go binary to /usr/bin
cp /tmp/wireguard-go/wireguard-go /usr/bin

# Generate Wireguard keys and set permissions
wg genkey > /etc/wireguard/privatekey
wg genkey > /etc/wireguard/client-privatekey
chmod 600 /etc/wireguard/*privatekey*

# Generate Wireguard public keys
wg pubkey < /etc/wireguard/privatekey > /etc/wireguard/publickey
wg pubkey < /etc/wireguard/client-privatekey > /etc/wireguard/client-publickey

# Generate server configuration using a generator script
srv=$(hostname)
privkey=$(cat /etc/wireguard/privatekey)
pubkey=$(cat /etc/wireguard/publickey)
cliprivkey=$(cat /etc/wireguard/client-privatekey)
clipubkey=$(cat /etc/wireguard/client-publickey)

# Use the generator script to create the server configuration
curl -s -d "mode=wireguard-server&srv=$srv&privkey=$privkey&pubkey=$clipubkey" https://mikr.us/generator.php >/etc/wireguard/wg0.conf

echo -e "\n\n==============\n\nClient Configuration:\n\n"

# Use the generator script to create the client configuration and display it
curl -s -d "mode=wireguard-client&srv=$srv&privkey=$cliprivkey&pubkey=$pubkey" https://mikr.us/generator.php | tee /etc/wireguard/wg-client1.conf

# Restart Wireguard with the modified configuration
systemctl stop "wg-quick@wg0"
sed -i '/RETRIES=infinity/{n;s/.*/Environment=WG_I_PREFER_BUGGY_USERSPACE_TO_POLISHED_KMOD=1/}' /lib/systemd/system/wg-quick@.service
systemctl daemon-reload
echo "export WG_I_PREFER_BUGGY_USERSPACE_TO_POLISHED_KMOD=1" >> ~/.profile
echo "export WG_I_PREFER_BUGGY_USERSPACE_TO_POLISHED_KMOD=1" >> ~/.bashrc
systemctl start "wg-quick@wg0"

# Generate a QR code for the client configuration
qrencode -t ansiutf8 </etc/wireguard/wg-client1.conf

# Clean up temporary files
rm -rf /tmp/wireguard-tools
rm -rf /tmp/wireguard-go
