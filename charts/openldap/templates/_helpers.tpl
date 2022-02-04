{{/*
Expand the name of the chart.
*/}}
{{- define "openldap.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "openldap.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "openldap.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openldap.labels" -}}
helm.sh/chart: {{ include "openldap.chart" . }}
{{ include "openldap.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openldap.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openldap.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "openldap.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "openldap.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate certificates for openldap
*/}}
{{- define "openldap.cert" -}}
{{- $namePrefix := ( include "openldap.fullname" . ) -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace (print ( include "openldap.fullname" . ) "-tls") -}}
{{- if $secret -}}
ca: {{ index $secret.data "ca.crt" }}
cert: {{ index $secret.data "tls.crt" }}
key: {{ index $secret.data "tls.key" }}
{{- else -}}
{{- $altNames := list ( printf "%s-%s.%s" $namePrefix "ldap" .Release.Namespace ) ( printf "%s-%s.%s.svc" $namePrefix "ldaps" .Release.Namespace ) -}}
{{- $ca := genCA "openldap-ca" 3650 -}}
{{- $cert := genSignedCert ( include "openldap.fullname" . ) nil $altNames 3650 $ca -}}
ca: {{ $ca.Cert | b64enc }}
cert: {{ $cert.Cert | b64enc }}
key: {{ $cert.Key | b64enc }}
{{- end -}}
{{- end -}}

{{/* generate admin password */}}
{{- define "openldap.admin-password" -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace (printf "%s-admin" ( include "openldap.fullname" . )) -}}
{{- if $secret -}}
{{ $secret.data.password | b64dec }}
{{- else -}}
{{ randAlphaNum 32 }}
{{- end -}}
{{- end -}}

{{/* generate ldap user passwords */}}
{{- define "openldap.generate-passwords" -}}
{{- range .Values.ldap.users }}
{{ .dn | quote }}: {{ randAlphaNum 32 | quote }} 
{{- end -}}
{{- end -}}