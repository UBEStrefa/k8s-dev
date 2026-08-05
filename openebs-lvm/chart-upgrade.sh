#!/bin/bash
set -euo pipefail

# OpenEBS publikuje chart w repozytorium Helm (openebs.github.io/openebs), więc
# odświeżamy go przez helm pull — pobrany chart ma już rozpakowane subcharty
# (lvm-localpv, zfs-localpv, mayastor, localpv-provisioner, openebs-crds, ...),
# nie trzeba uruchamiać helm dependency update. Chart trzymamy zacommitowany
# w repo, w katalogu <nazwa>-<wersja chartu>.

HELM_REPO="openebs"
CHART="openebs/openebs"
CHART_NAME="openebs"
VERSION="${1:-}"   # np. 4.5.1 (wersja chartu, bez "v"); puste = najnowsza

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Odświeżam repozytorium Helm $HELM_REPO..."
helm repo update "$HELM_REPO"

echo "Pobieram chart $CHART ${VERSION:-(najnowszy)}..."
helm pull "$CHART" ${VERSION:+--version "$VERSION"} --untar --untardir "$TMP"

# Kotwica ^ jest istotna: Chart.yaml openebs ma sekcję dependencies z własnymi
# liniami "version:" przed wersją samego chartu.
NEW_VERSION="$(awk '/^version:/{print $2; exit}' "$TMP/$CHART_NAME/Chart.yaml")"
DEST="./$CHART_NAME-$NEW_VERSION"

if [ -d "$DEST" ]; then
  echo "Katalog $DEST już istnieje — nadpisuję jego zawartość."
  rm -rf "$DEST"
fi
mv "$TMP/$CHART_NAME" "$DEST"

echo "Chart openebs $NEW_VERSION został pobrany do $DEST. Przejrzyj zmiany: git status"
echo "Ustaw w install.sh: CHART_PATH=\"$DEST\""
