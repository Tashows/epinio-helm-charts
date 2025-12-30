{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "epinio-application.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "epinio-application.labels" -}}
app.kubernetes.io/managed-by: epinio
app.kubernetes.io/part-of: {{ .Release.Namespace | quote }}
helm.sh/chart: {{ include "epinio-application.chart" . }}
{{ include "epinio-application.selectorLabels" . }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "epinio-application.annotations" -}}
epinio.io/created-by: {{ .Values.epinio.username | quote }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "epinio-application.selectorLabels" -}}
app.kubernetes.io/name: {{ include "label-name" . }}
app.kubernetes.io/component: {{ include "label-component" . }}
{{- end }}

{{/*
Removes characters that are invalid for kubernetes resource names from the
given string
*/}}
{{- define "epinio-name-sanitize" -}}
{{ regexReplaceAll "[^-a-z0-9]*" . "" }}
{{- end }}

{{/*
Resource name sanitization and truncation.
- Always suffix the sha1sum (40 characters long)
- Always add an "r" prefix to make sure we don't have leading digits # removed
- The rest of the characters up to 63 are the original string with invalid
character removed.
*/}}
{{- define "epinio-truncate" -}}
{{ print (trunc 21 (include "epinio-name-sanitize" .)) "-" (sha1sum .) }}
{{- end }}

{{/*
Application listening port
*/}}
{{- define "epinio-app-listening-port" -}}
{{ default "" (default (dict "appListeningPort" "") .Values.userConfig).appListeningPort }}
{{- end }}

{{/*
App/Pod component name
*/}}
{{- define "label-component" -}}
{{ printf "%s-process" (default "web" (default (dict "processName" "") .Values.userConfig).processName) | quote }}
{{- end }}

{{/*
App name for label
*/}}
{{- define "label-name" -}}
{{ default .Values.epinio.appName (default (dict "appName" "") .Values.userConfig).appName | quote }}
{{- end }}

{{/*
Define resources for pods
*/}}
{{- define "epinio-application-resources" -}}
resources:
	{{- if or .Values.userConfig.resourcesLimitsCpu .Values.userConfig.resourcesLimitsMemory }}
	limits:
		{{- if .Values.userConfig.resourcesLimitsCpu }}
		cpu: {{ .Values.userConfig.resourcesLimitsCpu | quote }}
		{{- end }}
		{{- if .Values.userConfig.resourcesLimitsMemory }}
		memory: {{ .Values.userConfig.resourcesLimitsMemory | quote }}
		{{- end }}
	{{- end }}
	{{- if or .Values.userConfig.resourcesRequestsCpu .Values.userConfig.resourcesRequestsMemory }}
	requests:
		{{- if .Values.userConfig.resourcesRequestsCpu }}
		cpu: {{ .Values.userConfig.resourcesRequestsCpu | quote }}
		{{- end }}
		{{- if .Values.userConfig.resourcesRequestsMemory }}
		memory: {{ .Values.userConfig.resourcesRequestsMemory | quote }}
		{{- end }}
	{{- end }}
{{- end }}
