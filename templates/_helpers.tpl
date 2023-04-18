{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "drupal.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "drupal.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "drupal.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "drupal.labels" -}}
helm.sh/chart: {{ include "drupal.chart" . }}
{{ include "drupal.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "drupal.selectorLabels" -}}
app.kubernetes.io/name: {{ include "drupal.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "drupal.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "drupal.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "imagePullSecret" }}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}


{{/* 
Drupal Volumes
*/}}
{{- define "drupal.volumes" -}}
- name: files-vol
  persistentVolumeClaim:
    claimName: {{.Release.Name}}
- name: private-files-vol
  persistentVolumeClaim:
    claimName: "{{.Release.Name}}-private"
- name: tmp-files-vol
  persistentVolumeClaim:
    claimName: "{{.Release.Name}}-tmp"
- name: dump-files-vol
  persistentVolumeClaim:
    claimName: "{{.Release.Name}}-dump"
- name: php-ini
  configMap:
    name: php-ini
    defaultMode: 0644
    items:
      - key: php.ini
        path: php.ini
{{ if eq .Values.DYNATRACE.enabled true }}
- name: oneagent
  emptyDir: {}
{{ end }}
{{- end -}}

{{/* 
Drupal mounts
*/}}
{{- define "drupal.mounts" -}}
- mountPath: /mnt/dumps
  name: dump-files-vol
- mountPath: /var/www/drupal/docroot/sites/default/files
  name: files-vol
- mountPath: /var/www/drupal/private/files
  name: private-files-vol
- mountPath: /tmp/drupal
  name: tmp-files-vol
- mountPath: /tmp/php.ini
  name: php-ini
  subPath: php.ini
  readOnly: true
{{ if eq .Values.DYNATRACE.enabled true }}
- name: oneagent
  mountPath: /opt/dynatrace/oneagent
{{ end }}
{{- end -}}

{{/*
Drupal env vars
*/}}
{{- define "drupal.envvars" -}}
- name: DRUPAL_HASH_SALT
  valueFrom:
    secretKeyRef:
        name: credentials
        key: DRUPAL_HASH_SALT
- name: MYSQL_DATABASE
  valueFrom:
    secretKeyRef:
        name: credentials
        key: MYSQL_DATABASE
- name: MYSQL_USERNAME
  valueFrom:
    secretKeyRef:
        name: credentials
        key: MYSQL_USERNAME
- name: MYSQL_PASSWORD
  valueFrom:
    secretKeyRef:
        name: credentials
        key: MYSQL_PASSWORD
- name: MYSQL_HOSTNAME
  valueFrom:
    secretKeyRef:
        name: credentials
        key: MYSQL_HOSTNAME
- name: DRUSH_OPTIONS_URI
  value: https://{{ .Values.ingress_hostname }}      
- name: DEPLOY_VERSION
  value: {{ .Values.image.version }}
- name: DEPLOY_RELEASE
  value: {{ .Release.Name }}
- name: DEPLOY_UNIQUE_RUN_ID
  value: "{{ .Values.deploy.runid }}"
- name: ROCKETSHIP_PROJECT_ENVIRONMENT
  value: "{{ .Values.ROCKETSHIP_PROJECT_ENVIRONMENT }}"
- name: NEWRELIC_LICENSE_KEY
  value: "{{ .Values.NEWRELIC_LICENSE_KEY }}"
- name: NEWRELIC_ENABLED
  value: "{{ .Values.NEWRELIC_ENABLED }}"
- name: NEWRELIC_APPNAME
  value: "{{ .Values.NEWRELIC_APPNAME }}"
{{ if eq .Values.DYNATRACE.enabled true }}
- name: LD_PRELOAD
  value: /opt/dynatrace/oneagent/agent/lib64/liboneagentproc.so
{{ end }}
{{ if eq .Values.service_bus.sb_enabled true }}
- name: SB_CONN_STRING_TOPIC
  valueFrom:
    secretKeyRef:
        name: sb-events-topic
        key: connection_string
- name: SB_CONN_STRING_QUEUE
  valueFrom:
    secretKeyRef:
        name: sb-events-queue
        key: connection_string
{{ end }}
{{- end -}}

{{/*
Drupal exporter.resources
*/}}
{{- define "drupal.exporter.resources" -}}
requests: 
  cpu: 15m
  memory: "128Mi"
limits:   
  cpu: 50m
  memory: "512Mi"
{{- end -}}
