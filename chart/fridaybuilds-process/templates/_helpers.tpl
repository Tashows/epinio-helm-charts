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

{{- define "fridaybuilds-volume-claim-name-setting" -}}
{{ default "" (default (dict "volumeClaimName" "") .Values.userConfig).volumeClaimName }}
{{- end }}

{{/*
PVC to mount. volumeClaimName is used as is. Without it, the claim name is derived from volumeName (kept for
releases deployed before volumeClaimName existed).
*/}}
{{- define "fridaybuilds-volume-claim-name" -}}
{{- if include "fridaybuilds-volume-claim-name-setting" . | trim -}}
{{ include "fridaybuilds-volume-claim-name-setting" . | trim }}
{{- else if include "fridaybuilds-volume-name" . | trim -}}
{{ include "epinio-truncate" (include "fridaybuilds-volume-name" . | trim) }}
{{- end -}}
{{- end }}

{{/*
Name of the volume in the pod spec. Fixed when volumeClaimName is given, so it doesn't depend on user chosen names
(pod volume names are limited to 63 characters).
*/}}
{{- define "fridaybuilds-pod-volume-name" -}}
{{- if include "fridaybuilds-volume-claim-name-setting" . | trim -}}
fridaybuilds-volume
{{- else -}}
{{ include "fridaybuilds-volume-name" . | trim }}
{{- end -}}
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

{{/*
Scale to zero with KEDA's HTTP add-on (keda.* values). userConfig.sleepAfterSeconds > 0 lets the workload sleep: KEDA
scales it to 0 pods once no request arrived for that long, and back to replicaCount on the next request, which the
KEDA interceptor holds meanwhile. fridaybuilds-sleep-mode is
- "route": the release has a listening port and routes, and sends its own traffic through the interceptor
- "follow": userConfig.sleepWithApp names another app in the namespace, whose traffic wakes this one and keeps it awake
- "" otherwise, and always while replicaCount is 0 (stopped)
*/}}
{{- define "fridaybuilds-sleep-after-seconds" -}}
{{ int (default 0 (default dict .Values.userConfig).sleepAfterSeconds) }}
{{- end }}

{{- define "fridaybuilds-sleep-with-app" -}}
{{ default "" (default dict .Values.userConfig).sleepWithApp }}
{{- end }}

{{- define "fridaybuilds-sleep-mode" -}}
{{- if and (gt (int (include "fridaybuilds-sleep-after-seconds" .)) 0) (gt (int .Values.epinio.replicaCount) 0) -}}
{{- if and (include "epinio-app-listening-port" .) .Values.epinio.routes -}}
route
{{- else if include "fridaybuilds-sleep-with-app" . | trim -}}
follow
{{- end -}}
{{- end -}}
{{- end }}

{{/*
InterceptorRoute whose traffic wakes the workload: its own, or the one of the app it follows. Named like the app's
Deployment and Service.
*/}}
{{- define "fridaybuilds-sleep-route-name" -}}
{{- if eq (include "fridaybuilds-sleep-mode" .) "follow" -}}
{{ include "epinio-truncate" (include "fridaybuilds-sleep-with-app" . | trim) }}
{{- else -}}
{{ include "epinio-truncate" .Values.epinio.appName }}
{{- end -}}
{{- end }}

{{/*
ExternalName Service aliasing the KEDA interceptor in the release's namespace (an Ingress can only reference Services
of its own namespace)
*/}}
{{- define "fridaybuilds-interceptor-service-name" -}}
{{ include "epinio-truncate" (print .Values.epinio.appName "-interceptor") }}
{{- end }}

{{/*
Values added after 0.1.44. Epinio upgrades releases with helm's --reuse-values, which keeps the chart defaults of the
version a release was installed with, so values.yaml defaults added later are missing on upgrades. These helpers hold
the defaults instead.
*/}}
{{- define "fridaybuilds-init-container-image" -}}
{{ (default dict .Values.initContainers).image | default "busybox:1.37.0" }}
{{- end }}

{{- define "fridaybuilds-keda-interceptor-service" -}}
{{ (default dict .Values.keda).interceptorService | default "keda-add-ons-http-interceptor-proxy.keda.svc.cluster.local" }}
{{- end }}

{{- define "fridaybuilds-keda-interceptor-port" -}}
{{ (default dict .Values.keda).interceptorPort | default 8080 }}
{{- end }}

{{- define "fridaybuilds-keda-external-scaler-address" -}}
{{ (default dict .Values.keda).externalScalerAddress | default "keda-add-ons-http-external-scaler.keda:9090" }}
{{- end }}

{{- define "fridaybuilds-keda-wake-timeout" -}}
{{ (default dict .Values.keda).wakeTimeout | default "60s" }}
{{- end }}
