#!/bin/bash
set -euo pipefail

RELEASE_NAME="rancher"
# Rancher wymaga namespace cattle-system (nazwa jest zaszyta w jego komponentach).
NAMESPACE="cattle-system"
# Zwendorowany chart — po uruchomieniu chart-upgrade.sh wskaż tu nowy katalog.
CHART_PATH="${1:-./rancher-2.15.0}"

echo "Instaluję/aktualizuję release $RELEASE_NAME w namespace $NAMESPACE z chartu $CHART_PATH..."
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
  --namespace "$NAMESPACE" --create-namespace \
  -f my.values.yaml

# Certyfikat wystawia cert-manager przez adnotację ingressu
# (cert-manager.io/cluster-issuer: ubestrefa-issuer w my.values.yaml), więc
# cert-manager i ClusterIssuer muszą już być w klastrze. Chart sam nie tworzy
# sekretu tls-rancher-ingress (ingress.tls.source=secret).
echo "Gotowe. Panel: https://rancher.srv.ubestrefa.pl (hasło startowe: bootstrapPassword z my.values.yaml)"
