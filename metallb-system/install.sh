#!/bin/bash
set -euo pipefail

RELEASE_NAME="metallb-system"
NAMESPACE="metallb-system"
# Zwendorowany chart — po uruchomieniu chart-upgrade.sh wskaż tu nowy katalog.
CHART_PATH="${1:-./metallb-0.16.1}"

echo "Instaluję/aktualizuję release $RELEASE_NAME w namespace $NAMESPACE z chartu $CHART_PATH..."
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
  --namespace "$NAMESPACE" --create-namespace \
  -f my.values.yaml

# Subchart frr-k8s jest wyłączony (frrk8s.enabled=false w my.values.yaml),
# CRD-y wchodzą z subchartu crds.
echo "Gotowe. Pule adresów i L2Advertisement aplikuj osobno:"
echo "  kubectl apply -f auto.yaml -f external.yaml -f internal.yaml"
