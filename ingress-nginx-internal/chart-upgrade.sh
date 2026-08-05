#!/bin/bash
set -euo pipefail

# Fork forkline/ingress-nginx (upstream kubernetes/ingress-nginx jest wycofany)
# nie publikuje chartu w repozytorium Helm — chart żyje w repo git (katalog
# charts/ingress-nginx). Odświeżamy go więc przez sparse clone i kopiujemy do
# katalogu <nazwa>-<wersja chartu>, obok poprzednich wersji.

REPO_URL="https://github.com/forkline/ingress-nginx"
CHART_SUBDIR="charts/ingress-nginx"
CHART_NAME="ingress-nginx"
REF="${1:-main}"   # najlepiej podać tag, np. ./chart-upgrade.sh v2026.7.20

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Klonuję $REPO_URL ($REF)..."
git clone --depth 1 --branch "$REF" --filter=blob:none --sparse "$REPO_URL" "$TMP/repo"
git -C "$TMP/repo" sparse-checkout set "$CHART_SUBDIR"

NEW_VERSION="$(awk '$1=="version:"{print $2; exit}' "$TMP/repo/$CHART_SUBDIR/Chart.yaml")"
DEST="./$CHART_NAME-$NEW_VERSION"

if [ -d "$DEST" ]; then
  echo "Katalog $DEST już istnieje — nadpisuję jego zawartość."
  rm -rf "$DEST"
fi
cp -r "$TMP/repo/$CHART_SUBDIR" "$DEST"

echo "Chart ingress-nginx $NEW_VERSION został pobrany do $DEST. Przejrzyj zmiany: git status"
echo "Ustaw w install.sh: CHART_PATH=\"$DEST\""
