# agent-sandbox-blueprint

mogenius blueprints and the Helm chart behind the **Agent Sandbox** blueprint.

```
charts/*.yaml                  HelmBlueprint definitions (what the platform lists)
index.yaml                     blueprint index (what the platform reads first)
helm/mogenius-agent-sandbox/   the chart the agent-sandbox blueprint installs
hack/                          update-upstream, upgrade-crds, publish-chartmuseum
.github/workflows/chart.yaml   lint, kind install test, release to GitHub Pages
```

Point a platform API at this repo with `HELM_BLUEPRINTS_DEFAULT_REPO_URL=https://github.com/<owner>/agent-sandbox-blueprint`;
it reads `index.yaml` and `charts/<id>.yaml` from the `main` branch.

## The chart: `mogenius-agent-sandbox`

One release brings up the whole system, modelled on the paralov PoC
(`paralov-poc/kubernetes/agent-sandbox`) but generic:

| Part | What it installs |
| --- | --- |
| `controller.*` | kubernetes-sigs/agent-sandbox controller **with extensions**, RBAC, metrics Service — into the release namespace (`agent-sandbox-system`, upstream expects it there) |
| `crds/` | the four v1beta1 CRDs of the pinned upstream release (`appVersion`) |
| `sandboxes.namespace` | the namespace sandbox pods run in |
| `sandboxes.serviceAccount` | `sandbox-runtime`: no RBAC, no token — sandboxes reach the apiserver as nobody |
| `sandboxes.profiles.<name>` | a `SandboxTemplate` per profile and a `SandboxWarmPool` when `warmPool.replicas > 0` |

Profiles are the knobs the platform UI edits: image, resources, storage, port and probes,
RuntimeClass (`gvisor` where available), security contexts, and the warm pool size.
`default` is what the mogenius Sandbox SDK claims from; `opencode` is a ready-made second
profile, disabled by default.

Network policy follows upstream's managed default (internet egress only, RFC1918 and
link-local denied, ingress only from the upstream router). Two values change it:
`networkPolicy.additionalBlockedCidrs` for service CIDRs outside RFC1918 (GKE:
`34.118.224.0/20`) and `networkPolicy.ingressFrom` for extra peers such as a router.

Not in the chart: the sandbox-router, kgateway and cert-manager from the GKE PoC. On a
mogenius cluster the operator provides terminal, SSH and port-forward to every sandbox, so
no in-cluster router or public gateway is needed.

### Try it

```sh
helm install agent-sandbox helm/mogenius-agent-sandbox -n agent-sandbox-system --create-namespace --wait
kubectl -n agent-sandbox get sandboxwarmpool,sandboxes,pods      # pool pre-warms one sandbox
helm upgrade agent-sandbox helm/mogenius-agent-sandbox -n agent-sandbox-system \
  --reuse-values --set sandboxes.profiles.default.warmPool.replicas=3
```

Clusters that still carry agent-sandbox **< v0.5.0** must drop the old CRDs first; there is
no in-place upgrade (upstream removed `v1alpha1` and the conversion webhook in 1.0).

### Upgrading

Helm installs `crds/` once and never touches them again. When `appVersion` changes:

```sh
hack/upgrade-crds.sh                                   # server-side apply of crds/, waits for Established
helm upgrade agent-sandbox helm/mogenius-agent-sandbox -n agent-sandbox-system --reuse-values
```

To move the chart to a new upstream release: `hack/update-upstream.sh v1.0.3`, then diff
`/tmp/agent-sandbox-v1.0.3-other.yaml` against `templates/controller/`, bump `version` in
`Chart.yaml`, commit.

### Publishing

* **GitHub Pages** (automatic, what `charts/agent-sandbox.yaml` points at today): the
  `release` job runs chart-releaser on pushes to `main` that touch `helm/**`, creates the
  `gh-pages` branch and the Pages site on first run, and serves the Helm repository at
  `https://behrangalavi.github.io/agent-sandbox-blueprint`. Packages live in GitHub
  Releases; only `index.yaml` is on the branch.
* **helm.mogenius.com** (manual, target for customers): `hack/publish-chartmuseum.sh` with
  the ChartMuseum credentials in the environment, then switch `repository` in
  `charts/agent-sandbox.yaml` back to the `mogenius` alias.

Keep `spec.chart.version` in `charts/agent-sandbox.yaml` in step with `Chart.yaml`.

## Other blueprints in this repo

`claude-sandbox` renders a single `Sandbox` with code-server and Claude Code via the generic
`bedag/raw` chart and requires the Agent Sandbox blueprint. `keycloak` and `authentik` are
unrelated identity blueprints kept here for convenience.
