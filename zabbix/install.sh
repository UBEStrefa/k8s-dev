#!/bin/bash
set -euo pipefail

RELEASE_NAME="zabbix"
NAMESPACE="zabbix"
# Zwendorowany chart — po uruchomieniu chart-upgrade.sh wskaż tu nowy katalog.
CHART_PATH="${1:-./zabbix-helm-chrt-1.4.7}"

echo "Instaluję/aktualizuję release $RELEASE_NAME w namespace $NAMESPACE z chartu $CHART_PATH..."
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
  --namespace "$NAMESPACE" --create-namespace \
  -f my.values.yaml

# Subchart kube-state-metrics jest włączony (kubeStateMetrics.enabled=true),
# agent wyłączony — wdrażamy tylko proxy + KSM (patrz my.values.yaml).
echo "Gotowe."
