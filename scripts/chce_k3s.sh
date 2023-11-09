#!/bin/bash
# instalacja k3s (lLghtweight Kubernetes) na mikrusie
# Autor: Maciej Loper @2023.05
# Edytowane przez: Andrzej Szczepaniak @2023.11
# Edytowane, ze wzgledu na to, ze dual-stack nie dziala na najnowszej wersji K3s

# pobranie binarki K3s w wersji 1.27.6+k3s1
wget -O /usr/local/bin/k3s https://github.com/k3s-io/k3s/releases/download/v1.27.6%2Bk3s1/k3s

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
ExecStartPre=-/sbin/modprobe br_netfilter
ExecStartPre=-/sbin/modprobe overlay
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
systemctl enable --now k3s.service

exit
