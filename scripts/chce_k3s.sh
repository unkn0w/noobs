#!/bin/bash
# instalacja k3s (lLghtweight Kubernetes) na mikrusie
# Maciej Loper @2023.05

# ustawienia
SERVICE_FILE="/etc/systemd/system/k3s.service"
SERVICE_NAME="k3s"

# zaintaluj wg dokumentacji
# https://docs.k3s.io/quick-start
/bin/curl -sfL https://get.k3s.io | sh -

# zatrzymanie uslugi
/bin/systemctl disable --now "$SERVICE_NAME"
cp "$SERVICE_FILE" "${SERVICE_FILE}.bak"

cat <<EOF >>"$SERVICE_FILE"
    --kubelet-arg=feature-gates=KubeletInUserNamespace=true \\
    --kube-controller-manager-arg=feature-gates=KubeletInUserNamespace=true \\
    --kube-apiserver-arg=feature-gates=KubeletInUserNamespace=true \\
    --cluster-init
EOF

# odswiezenie systemd
/bin/systemctl daemon-reload

# uruchamienie uslugi + dodanie do autostartu
/bin/systemctl enable --now "$SERVICE_NAME"

exit
