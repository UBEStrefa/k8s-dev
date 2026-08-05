#!/bin/bash
set -euo pipefail

# cert-manager publikuje chart w repozytorium Helm (charts.jetstack.io), więc
# odświeżamy go przez helm pull. Chart trzymamy zacommitowany w repo, w katalogu
# nazwanym <nazwa>-<wersja chartu> (obok poprzednich wersji).

HELM_REPO="jetstack"
CHART="jetstack/cert-manager"
CHART_NAME="cert-manager"
VERSION="${1:-}"   # np. v1.22.0; puste = najnowsza stabilna

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

echo "Chart cert-manager $NEW_VERSION został pobrany do $DEST. Przejrzyj zmiany: git status"
echo "Ustaw w install.sh: CHART_PATH=\"$DEST\""
