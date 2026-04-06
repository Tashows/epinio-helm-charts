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
app.kubernetes.io/name: {{ .Values.epinio.appName | quote }}
app.kubernetes.io/component: application
fridaybuilds.com/app-name: {{ include "fridaybuilds-app-name" . }}
fridaybuilds.com/class: {{ include "fridaybuilds-class" . }}
fridaybuilds.com/name: {{ include "fridaybuilds-name" . }}
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
fridaybuilds app name/slug, when applicable
*/}}
{{- define "fridaybuilds-app-name" -}}
{{ default "" (default (dict "fridaybuildsAppName" "") .Values.userConfig).fridaybuildsAppName }}
{{- end }}

{{/*
Fridaybuilds class
*/}}
{{- define "fridaybuilds-class" -}}
{{ printf "%s" (default "AppProcess" (default (dict "fridaybuildsClass" "") .Values.userConfig).fridaybuildsClass) | replace " " "-" | trunc 50 }}
{{- end }}

{{/*
FridayBuilds name/slug
*/}}
{{- define "fridaybuilds-name" -}}
{{ default .Values.epinio.appName (default (dict "fridaybuildsName" "") .Values.userConfig).fridaybuildsName | lower | replace " " "-" | trunc 50 }}
{{- end }}

{{/*
Define resources for pods
*/}}
{{- define "epinio-application-resources" -}}
{{- $uc := default dict .Values.userConfig -}}

{{- $limitsCpu := default "" $uc.resourcesLimitsCpu -}}
{{- $limitsMem := default "" $uc.resourcesLimitsMemory -}}
{{- $reqCpu := default "" $uc.resourcesRequestsCpu -}}
{{- $reqMem := default "" $uc.resourcesRequestsMemory -}}

{{- if or $limitsCpu $limitsMem $reqCpu $reqMem }}
resources:
  {{- if or $limitsCpu $limitsMem }}
  limits:
    {{- if $limitsCpu }}
    cpu: {{ $limitsCpu | quote }}
    {{- end }}
    {{- if $limitsMem }}
    memory: {{ $limitsMem | quote }}
    {{- end }}
  {{- end }}
  {{- if or $reqCpu $reqMem }}
  requests:
    {{- if $reqCpu }}
    cpu: {{ $reqCpu | quote }}
    {{- end }}
    {{- if $reqMem }}
    memory: {{ $reqMem | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Persistent volume settings
*/}}
{{- define "fridaybuilds-volume-name" -}}
{{ default "" (default (dict "volumeName" "") .Values.userConfig).volumeName }}
{{- end }}

{{- define "fridaybuilds-volume-size" -}}
{{ default "1Gi" (default (dict "volumeSize" "") .Values.userConfig).volumeSize }}
{{- end }}

{{- define "fridaybuilds-volume-storage-class" -}}
{{ default "ceph-filesystem" (default (dict "volumeStorageClass" "") .Values.userConfig).volumeStorageClass }}
{{- end }}

{{- define "fridaybuilds-volume-mount-path" -}}
{{ default "/data" (default (dict "volumeMountPath" "") .Values.userConfig).volumeMountPath }}
{{- end }}

{{- define "fridaybuilds-volume-create" -}}
{{ default "false" (default (dict "volumeCreate" "") .Values.userConfig).volumeCreate }}
{{- end }}
