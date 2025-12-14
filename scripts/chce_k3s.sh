#!/usr/bin/env bash
# instalacja k3s (lLghtweight Kubernetes) na mikrusie
# Autor: Maciej Loper @2023.05
# Edytowane przez: Andrzej Szczepaniak @2023.11
# Edytowane, ze wzgledu na to, ze dual-stack nie dziala na najnowszej wersji K3s
# Edytowane przez: TORGiren @2025.06
# Edytowane, dodanie możliwości wyboru wersji K3s i ustawienie domyślnej wersji na "stable"

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

VERSION=${1:-"stable"}

function get_release() {
    local version="$1"
    # Sprawdzenie, czy wersja zawiera "+k3s" (np. "1.27.6+k3s1"). Jeśli tak, to zwróć ją bez zmian.
    if [[ "$version" =~ \+k3s ]]; then
        echo "$version"
        return
    fi
    local latest_version=$(curl -s https://update.k3s.io/v1-release/channels | python3 -c "import sys, json; print(list(filter(lambda x: x['id'] == '$version',json.load(sys.stdin)['data']))[0]['latest'])" 2>/dev/null)
    if [[ -z "$latest_version" ]]; then
            echo "Error: Version '$version' not found in release channels."
            exit 1
    fi
    echo "$latest_version"
}

RELEASE=$(get_release "$VERSION")
if [[ $? -ne 0 ]]; then
    echo "$RELEASE"
    exit 1
fi

echo "Instalacja K3s w wersji: $RELEASE"

# pobranie binarki K3s w wersji 1.27.6+k3s1
wget -O /usr/local/bin/k3s "https://github.com/k3s-io/k3s/releases/download/$RELEASE/k3s"

# nadanie uprawnien binarce k3s
chmod +x /usr/local/bin/k3s

# przygotowanie serwisu k3s
cat <<EOF >"/etc/systemd/system/k3s.service"
[Unit]
Description=Lightweight Kubernetes
Documentation=https://k3s.io
Wants=network-online.target
After=network-online.target

[Install]
WantedBy=multi-user.target

[Service]
Type=notify
EnvironmentFile=-/etc/default/%N
EnvironmentFile=-/etc/sysconfig/%N
EnvironmentFile=-/etc/systemd/system/k3s.service.env
KillMode=process
Delegate=yes
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=always
RestartSec=5s
ExecStartPre=/bin/sh -xc '! /usr/bin/systemctl is-enabled --quiet nm-cloud-setup.service'
ExecStart=/usr/local/bin/k3s \\
    server \\
    --cluster-cidr=10.42.0.0/16,2001:cafe:42:0::/56 \\
    --service-cidr=10.43.0.0/16,2001:cafe:42:1::/112 \\
    --kubelet-arg=feature-gates=KubeletInUserNamespace=true \\
    --kube-controller-manager-arg=feature-gates=KubeletInUserNamespace=true \\
    --kube-apiserver-arg=feature-gates=KubeletInUserNamespace=true \\
    --cluster-init
EOF

# odswiezenie systemd
/bin/systemctl daemon-reload

# wlaczenie serwisu k3s oraz start uslugi k3s
service_enable_now k3s.service

exit
