#!/bin/bash
set -euo pipefail

RELEASE_NAME="cert-manager"
NAMESPACE="cert-manager"
# Zwendorowany chart — po uruchomieniu chart-upgrade.sh wskaż tu nowy katalog.
CHART_PATH="${1:-./cert-manager-v1.21.1}"

echo "Instaluję/aktualizuję release $RELEASE_NAME w namespace $NAMESPACE z chartu $CHART_PATH..."
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
  --namespace "$NAMESPACE" --create-namespace \
  -f my.values.yaml

# CRD-y instaluje sam chart (crds.enabled=true, crds.keep=true w my.values.yaml).
echo "Gotowe. ClusterIssuer aplikuj osobno: kubectl apply -f ubestrefa.issuer.yaml"
