#!/usr/bin/env bash
# Helm installs crds/ once and never updates them. Run this before
# `helm upgrade` whenever appVersion changed. Server-side apply: the CRDs are
# ~200 KB and exceed the client-side last-applied annotation limit.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
kubectl apply --server-side --force-conflicts -f "$ROOT/helm/mogenius-agent-sandbox/crds/"
kubectl wait --for=condition=Established --timeout=60s \
  crd/sandboxes.agents.x-k8s.io \
  crd/sandboxclaims.extensions.agents.x-k8s.io \
  crd/sandboxtemplates.extensions.agents.x-k8s.io \
  crd/sandboxwarmpools.extensions.agents.x-k8s.io
