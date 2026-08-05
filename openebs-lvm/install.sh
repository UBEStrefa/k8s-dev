#!/bin/bash
set -euo pipefail

RELEASE_NAME="openebs"
NAMESPACE="openebs"
# Zwendorowany chart — po uruchomieniu chart-upgrade.sh wskaż tu nowy katalog.
CHART_PATH="${1:-./openebs-4.5.1}"

echo "Instaluję/aktualizuję release $RELEASE_NAME w namespace $NAMESPACE z chartu $CHART_PATH..."
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
  --namespace "$NAMESPACE" --create-namespace \
  -f my.values.yaml

# Z całego openebs zostaje tylko lvm-localpv — mayastor, zfs, hostpath
# (localpv-provisioner) oraz stos logowania loki/alloy są wyłączone
# w my.values.yaml. CRD-y lvm-localpv wchodzą z chartu
# (lvm-localpv.crds.lvmLocalPv.enabled=true), CRD-y VolumeSnapshot są wyłączone,
# bo dostarcza je rke2-snapshot-controller-crd.
echo "Gotowe. Grupa woluminów ssd-lvmvg musi istnieć na node'ach (vgs)."
echo "StorageClass aplikuj osobno:"
echo "  kubectl apply -f ssd-xfs.yaml"
