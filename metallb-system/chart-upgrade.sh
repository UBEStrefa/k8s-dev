#!/bin/bash
set -euo pipefail

# MetalLB publikuje chart w repozytorium Helm (metallb.github.io/metallb), więc
# odświeżamy go przez helm pull — pobrany chart ma już rozpakowane subcharty
# (crds, frr-k8s), nie trzeba uruchamiać helm dependency update. Chart trzymamy
# zacommitowany w repo, w katalogu <nazwa>-<wersja chartu>.

HELM_REPO="metallb"
CHART="metallb/metallb"
CHART_NAME="metallb"
VERSION="${1:-}"   # np. 0.16.1 (wersja chartu, bez "v"); puste = najnowsza

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Odświeżam repozytorium Helm $HELM_REPO..."
helm repo update "$HELM_REPO"

echo "Pobieram chart $CHART ${VERSION:-(najnowszy)}..."
helm pull "$CHART" ${VERSION:+--version "$VERSION"} --untar --untardir "$TMP"

NEW_VERSION="$(awk '$1=="version:"{print $2; exit}' "$TMP/$CHART_NAME/Chart.yaml")"
DEST="./$CHART_NAME-$NEW_VERSION"

if [ -d "$DEST" ]; then
  echo "Katalog $DEST już istnieje — nadpisuję jego zawartość."
  rm -rf "$DEST"
fi
mv "$TMP/$CHART_NAME" "$DEST"

echo "Chart metallb $NEW_VERSION został pobrany do $DEST. Przejrzyj zmiany: git status"
echo "Ustaw w install.sh: CHART_PATH=\"$DEST\""
