#!/bin/bash
set -euo pipefail

# Rancher publikuje chart w swoim repozytorium Helm — osobnym dla każdego kanału
# (stable, latest, alpha); używamy stable. Repo dodajemy z --force-update
# (idempotentnie, obsługuje też zmianę kanału przez RANCHER_CHANNEL). Chart
# trzymamy zacommitowany w repo, w katalogu <nazwa>-<wersja chartu>, obok
# poprzednich wersji.

RANCHER_CHANNEL="${RANCHER_CHANNEL:-stable}"
HELM_REPO="rancher-$RANCHER_CHANNEL"
REPO_URL="https://releases.rancher.com/server-charts/$RANCHER_CHANNEL"
CHART_NAME="rancher"
VERSION="${1:-}"   # np. 2.14.3 (wersja chartu = wersja Ranchera); puste = najnowsza

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Konfiguruję repozytorium Helm $HELM_REPO ($REPO_URL)..."
helm repo add "$HELM_REPO" "$REPO_URL" --force-update
helm repo update "$HELM_REPO"

echo "Pobieram chart $HELM_REPO/$CHART_NAME ${VERSION:-(najnowszy)}..."
helm pull "$HELM_REPO/$CHART_NAME" ${VERSION:+--version "$VERSION"} --untar --untardir "$TMP"

NEW_VERSION="$(awk '$1=="version:"{print $2; exit}' "$TMP/$CHART_NAME/Chart.yaml")"
DEST="./$CHART_NAME-$NEW_VERSION"

if [ -d "$DEST" ]; then
  echo "Katalog $DEST już istnieje — nadpisuję jego zawartość."
  rm -rf "$DEST"
fi
mv "$TMP/$CHART_NAME" "$DEST"

echo "Chart rancher $NEW_VERSION został pobrany do $DEST. Przejrzyj zmiany: git status"
echo "Ustaw w install.sh: CHART_PATH=\"$DEST\""
echo "Uwaga: Rancher wspiera tylko upgrade o jedną gałąź minor naprzód — sprawdź support matrix przed podbiciem."
