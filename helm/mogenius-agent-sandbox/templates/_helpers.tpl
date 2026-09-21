{{/*
Chart name, truncated to a DNS label.
*/}}
{{- define "mogenius-agent-sandbox.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels for controller objects.
*/}}
{{- define "mogenius-agent-sandbox.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
app.kubernetes.io/name: {{ include "mogenius-agent-sandbox.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ include "mogenius-agent-sandbox.controllerTag" . | quote }}
app.kubernetes.io/part-of: agent-sandbox
{{- end }}

{{/*
Selector labels for the controller Deployment and Service. `app` is kept for
compatibility with upstream tooling that selects on it.
*/}}
{{- define "mogenius-agent-sandbox.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mogenius-agent-sandbox.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: agent-sandbox-controller
{{- end }}

{{/*
Controller image tag: explicit tag or the chart's appVersion.
*/}}
{{- define "mogenius-agent-sandbox.controllerTag" -}}
{{- default .Chart.AppVersion .Values.controller.image.tag }}
{{- end }}

{{- define "mogenius-agent-sandbox.controllerImage" -}}
{{- printf "%s:%s" .Values.controller.image.repository (include "mogenius-agent-sandbox.controllerTag" .) }}
{{- end }}

{{/*
Controller arguments, mirroring the upstream manifest plus opt-in extras.
*/}}
{{- define "mogenius-agent-sandbox.controllerArgs" -}}
- --leader-elect={{ .Values.controller.leaderElect }}
{{- if .Values.controller.extensions }}
- --extensions
{{- end }}
{{- range .Values.controller.extraArgs }}
- {{ . | quote }}
{{- end }}
{{- end }}

{{/*
Namespace the sandbox pods live in.
*/}}
{{- define "mogenius-agent-sandbox.sandboxNamespace" -}}
{{- .Values.sandboxes.namespace.name }}
{{- end }}

{{/*
Whether an explicit NetworkPolicy must be rendered into the template: only when
the operator adds ingress peers or blocks extra CIDRs. Otherwise the controller's
built-in default policy applies, which is what upstream tests against.
*/}}
{{- define "mogenius-agent-sandbox.explicitNetworkPolicy" -}}
{{- $np := .Values.sandboxes.networkPolicy -}}
{{- if and $np.managed (or $np.ingressFrom $np.additionalBlockedCidrs) -}}true{{- end -}}
{{- end }}
