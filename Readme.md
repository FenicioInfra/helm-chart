Instalar nuevo

helm lint helm-chart-sources/*

helm package helm-chart-sources/*

helm repo index --url https://fenicioinfra.github.io/helm-chart/ .