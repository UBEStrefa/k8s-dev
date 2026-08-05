#!/bin/bash
set -euo pipefail

RELEASE_NAME="ingress-nginx-internal"
NAMESPACE="ingress-nginx-internal"
# Zwendorowany chart — po uruchomieniu chart-upgrade.sh wskaż tu nowy katalog.
CHART_PATH="${1:-./ingress-nginx-2026.7.20}"

echo "Instaluję/aktualizuję release $RELEASE_NAME w namespace $NAMESPACE z chartu $CHART_PATH..."
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
  --namespace "$NAMESPACE" --create-namespace \
  -f my.values.yaml

echo "Gotowe."
