{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Release.Name}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "php-fpm-conf" }}
{{- $global := .Values.global }}
{{- $phpFpmConfig := .Values.phpFpmConfig | default $global.phpFpmConfig }}
{{- $resources:= .Values.resources | default $global.resources}}
{{- $avgWorkerMemory := $phpFpmConfig.avgWorkerMemory }}
{{- $memoryRequestAvailable := floor (mulf 0.9 ($resources.requests.memory | split "Mi" )._0) -}}
{{- $memoryLimitAvailable := floor (mulf 0.9 ($resources.limits.memory | split "Mi" )._0) -}}
[www]
user = 1001
group = 0
{{- $service:= .Values.service | default $global.service}}
listen = {{ $service.port | default ("9000") }}
pm = {{ $phpFpmConfig.pm }}
pm.max_children = {{ floor (divf $memoryLimitAvailable $avgWorkerMemory) | default ("3") }}
pm.start_servers = {{ floor (divf $memoryRequestAvailable $avgWorkerMemory) | default ("2") }}
pm.min_spare_servers = {{ floor (divf $memoryRequestAvailable $avgWorkerMemory) | default ("2") }}
pm.max_spare_servers = {{ floor (mulf 0.75 (divf $memoryLimitAvailable $avgWorkerMemory)) | default ("3") }}
{{- if $phpFpmConfig.additionalWwwConfigs }}
{{ $phpFpmConfig.additionalWwwConfigs }}
{{- end }}
{{- end }} 