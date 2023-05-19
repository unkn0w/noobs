#!/bin/bash
# instalacja k3s (lLghtweight Kubernetes) na mikrusie
# Maciej Loper @2023.05

# ustawienia
SERVICE_FILE="/etc/systemd/system/k3s.service"
SERVICE_NAME="k3s"

# zaintaluj wg dokumentacji
# https://docs.k3s.io/quick-start
curl -sfL https://get.k3s.io | sh -

# zatrzymanie uslugi
/bin/systemctl disable --now "$SERVICE_NAME"

# kopia zapasowa
cp "$SERVICE_FILE" "${SERVICE_FILE}.bak"

# dodanie poprawki do pliku
sed -i '$d' "$SERVICE_FILE"
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

# rollback
/bin/systemctl disable --now k3s
cp /etc/systemd/system/k3s.service.bak /etc/systemd/system/k3s.service
/usr/local/bin/k3s-uninstall.sh
