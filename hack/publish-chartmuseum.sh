#!/usr/bin/env bash
# Packages the chart and pushes it to a ChartMuseum (helm.mogenius.com).
#
#   CHARTMUSEUM_URL=https://helm.mogenius.com \
#   CHARTMUSEUM_USER=... CHARTMUSEUM_PASSWORD=... hack/publish-chartmuseum.sh
#
# The GitHub workflow publishes to GitHub Pages instead; this is the manual
# path for the mogenius chart repository the blueprints point to.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${CHARTMUSEUM_URL:?set CHARTMUSEUM_URL}"
: "${CHARTMUSEUM_USER:?set CHARTMUSEUM_USER}"
: "${CHARTMUSEUM_PASSWORD:?set CHARTMUSEUM_PASSWORD}"

OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT
helm lint "$ROOT/helm/mogenius-agent-sandbox"
helm package "$ROOT/helm/mogenius-agent-sandbox" -d "$OUT" >/dev/null
TGZ="$(ls "$OUT"/*.tgz)"
echo "pushing $(basename "$TGZ") to $CHARTMUSEUM_URL"
curl --fail-with-body -sS -u "$CHARTMUSEUM_USER:$CHARTMUSEUM_PASSWORD" \
  --data-binary "@$TGZ" "$CHARTMUSEUM_URL/api/charts"
echo
