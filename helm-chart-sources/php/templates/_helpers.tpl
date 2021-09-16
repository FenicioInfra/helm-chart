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

{{/*
Snippet para location y configurar cache (de ser indicado).
*/}}
{{- define "php.location_snippet" -}}
location {{ .Values.ingress.path }} {
index  index.php;
fastcgi_pass    {{ template "fullname" . }}-svc.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.port }};
fastcgi_index   index.php;
fastcgi_split_path_info ^(.+\.php)(/.+)$;
include fastcgi_params;
fastcgi_param   PATH_INFO $fastcgi_path_info;
fastcgi_param   SCRIPT_FILENAME  /usr/src/app/public/index.php;
fastcgi_param   SCRIPT_NAME index.php;
{{- if .Values.ingress.annotations.snippets.extra_parameters_location }}
{{ .Values.annotations.extra_parameters_location }}
{{- end }}

{{- if eq .Values.ingress.annotations.snippets.cache_enabled true }}
{{ template "php.cache_config" .Values.ingress.annotations.snippets.cache_config }}
{{- end }}
} 
{{- end -}}

{{/*
Un snippet para configurar el cache.
Nota: Pasar como scope la direccion en el values.yaml
de la configuracion del cache
*/}}
{{- define "php.cache_config" -}}
add_header X-Cache-Status
    $upstream_cache_status; 
      expires {{ .expires }};
      fastcgi_cache {{ .fastcgi_cache }}; 
      fastcgi_ignore_headers {{ .fastcgi_ignore_headers }}; 
      fastcgi_cache_valid {{ .fastcgi_cache_valid }};
      fastcgi_cache_revalidate {{ .fastcgi_cache_revalidate | toString }}; 
      fastcgi_cache_use_stale {{ .fastcgi_cache_use_stale }}; 
      fastcgi_cache_background_update {{ .fastcgi_cache_background_update | toString }};
{{- end -}}

{{/*
Un snippet para configurar el 
node exporter de nginx.
*/}}
{{- define "node-exporter.config" -}}
listen {
  port = {{ .Values.metrics.port }}
}

namespace "nginx_exporter" {
  source = {
    syslog {
      listen_address = "udp://127.0.0.1:5531"
      format = "rfc3164"
    }
  }

  format = {{ .Values.metrics.format }}

  labels {
    app = "{{ template "fullname" . }}"
  }
}
{{- end -}}