#!/usr/bin/env bash
# Refreshes helm/mogenius-agent-sandbox/crds/ from an upstream agent-sandbox
# release and bumps appVersion in Chart.yaml. RBAC and the controller Deployment
# are templated by hand — diff them against the printed upstream objects.
#
#   hack/update-upstream.sh v1.0.2
set -euo pipefail

VERSION="${1:?usage: hack/update-upstream.sh <upstream version, e.g. v1.0.2>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHART="$ROOT/helm/mogenius-agent-sandbox"
URL="https://github.com/kubernetes-sigs/agent-sandbox/releases/download/${VERSION}/sandbox-with-extensions.yaml"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "downloading $URL"
curl -fsSL -o "$TMP/upstream.yaml" "$URL"

# Split the multi-document manifest; keep CRDs, print everything else for review.
python3 - "$TMP/upstream.yaml" "$CHART/crds" "$TMP" <<'EOF'
import re, sys, pathlib
raw = pathlib.Path(sys.argv[1]).read_text()
crd_dir = pathlib.Path(sys.argv[2]); other = pathlib.Path(sys.argv[3]) / "other.yaml"
docs = [d.strip("\n") for d in re.split(r"^---\s*$", raw, flags=re.M) if d.strip()]
for f in crd_dir.glob("*.yaml"):
    f.unlink()
rest = []
for d in docs:
    kind = re.search(r"^kind:\s*(\S+)", d, re.M).group(1)
    name = re.search(r"^  name:\s*(\S+)", d, re.M).group(1)
    if kind == "CustomResourceDefinition":
        (crd_dir / f"{name}.yaml").write_text(d + "\n")
        print(f"crds/{name}.yaml")
    else:
        rest.append(d)
other.write_text("\n---\n".join(rest) + "\n")
EOF

# Bump appVersion; the chart version is bumped by hand (semver of the chart, not upstream).
sed -i.bak -E "s/^appVersion: .*/appVersion: ${VERSION}/" "$CHART/Chart.yaml" && rm -f "$CHART/Chart.yaml.bak"

echo
echo "appVersion set to ${VERSION}. Review the non-CRD upstream objects against the templates:"
echo "  $TMP/other.yaml   (copied to /tmp/agent-sandbox-${VERSION}-other.yaml)"
cp "$TMP/other.yaml" "/tmp/agent-sandbox-${VERSION}-other.yaml"
echo "Then: bump 'version' in Chart.yaml, run 'helm lint helm/mogenius-agent-sandbox'."
