#!/bin/bash
# Autor skryptu: Andrzej Szczepaniak
# Poprawki: Jakub 'unknow' Mrugalski

# Check if user is root
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	echo "Try: sudo $0" 1>&2
	exit 1
fi

apt update
apt install -y --no-install-recommends libmnl-dev make qrencode wireguard-tools resolvconf

git -c http.sslVerify=false clone https://git.zx2c4.com/wireguard-go /tmp/wireguard-go
git -c http.sslVerify=false clone https://git.zx2c4.com/wireguard-tools /tmp/wireguard-tools


wget https://dl.google.com/go/go1.16.4.linux-amd64.tar.gz -O /tmp/go1.16.4.linux-amd64.tar.gz

cd /tmp/ && tar -zxvf go1.16.4.linux-amd64.tar.gz
mv /tmp/go /usr/local
export GOROOT=/usr/local/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
cd /tmp/wireguard-go
make
make install

cd /tmp/wireguard-tools/src/
make
make install

wg genkey > /etc/wireguard/privatekey
wg genkey > /etc/wireguard/client-privatekey

chmod 600 /etc/wireguard/*privatekey*

cat /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
cat /etc/wireguard/client-privatekey | wg pubkey > /etc/wireguard/client-publickey
srv=`hostname`
privkey=$(cat /etc/wireguard/privatekey)
pubkey=$(cat /etc/wireguard/publickey)
cliprivkey=$(cat /etc/wireguard/client-privatekey)
clipubkey=$(cat /etc/wireguard/client-publickey)

# generator configa umieszczony na serwerze Mikrusa
curl -s -d "mode=wireguard-server&srv=$srv&privkey=$privkey&pubkey=$clipubkey" https://mikr.us/generator.php >/etc/wireguard/wg0.conf

echo -e "\n\n==============\n\nKonfiguracja klienta:\n\n"
curl -s -d "mode=wireguard-client&srv=$srv&privkey=$cliprivkey&pubkey=$pubkey" https://mikr.us/generator.php | tee /etc/wireguard/wg-client1.conf

systemctl stop "wg-quick@wg0"
sed -i '/RETRIES=infinity/{n;s/.*/Environment=WG_I_PREFER_BUGGY_USERSPACE_TO_POLISHED_KMOD=1/}' /lib/systemd/system/wg-quick@.service
systemctl daemon-reload
echo "export WG_I_PREFER_BUGGY_USERSPACE_TO_POLISHED_KMOD=1" >> ~/.profile
echo "export WG_I_PREFER_BUGGY_USERSPACE_TO_POLISHED_KMOD=1" >> ~/.bashrc
systemctl start "wg-quick@wg0"

qrencode -t ansiutf8 </etc/wireguard/wg-client1.conf

rm -rf /tmp/wireguard-tools
rm -rf /tmp/wireguard-go
