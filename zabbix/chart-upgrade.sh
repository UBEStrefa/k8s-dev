#!/bin/bash
set -euo pipefail

# Zabbix publikuje chart w repozytorium Helm na swoim CDN, ale osobnym dla każdej
# gałęzi produktu (.../kubernetes-helm/7.2, /7.4 itd.) — dlatego URL składamy
# z ZBX_BRANCH i dodajemy repo z --force-update (idempotentnie, obsługuje też
# przejście na nowszą gałąź). Chart trzymamy zacommitowany w repo, w katalogu
# <nazwa>-<wersja chartu>.

ZBX_BRANCH="${ZBX_BRANCH:-7.2}"
HELM_REPO="zabbix-chart-$ZBX_BRANCH"
REPO_URL="https://cdn.zabbix.com/zabbix/integrations/kubernetes-helm/$ZBX_BRANCH"
CHART_NAME="zabbix-helm-chrt"
VERSION="${1:-}"   # np. 1.4.7 (wersja chartu, nie Zabbixa); puste = najnowsza

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Konfiguruję repozytorium Helm $HELM_REPO ($REPO_URL)..."
helm repo add "$HELM_REPO" "$REPO_URL" --force-update
helm repo update "$HELM_REPO"

echo "Pobieram chart $HELM_REPO/$CHART_NAME ${VERSION:-(najnowszy)}..."
helm pull "$HELM_REPO/$CHART_NAME" ${VERSION:+--version "$VERSION"} --untar --untardir "$TMP"

NEW_VERSION="$(awk '$1=="version:"{print $2; exit}' "$TMP/$CHART_NAME/Chart.yaml")"
APP_VERSION="$(awk '$1=="appVersion:"{print $2; exit}' "$TMP/$CHART_NAME/Chart.yaml")"
DEST="./$CHART_NAME-$NEW_VERSION"

if [ -d "$DEST" ]; then
  echo "Katalog $DEST już istnieje — nadpisuję jego zawartość."
  rm -rf "$DEST"
fi
mv "$TMP/$CHART_NAME" "$DEST"

echo "Chart zabbix-helm-chrt $NEW_VERSION (Zabbix $APP_VERSION) został pobrany do $DEST. Przejrzyj zmiany: git status"
echo "Ustaw w install.sh: CHART_PATH=\"$DEST\""
echo "Uwaga: tag obrazu proxy jest przypięty w my.values.yaml (zabbixProxy.image.tag) — zweryfikuj go po podbiciu wersji."
