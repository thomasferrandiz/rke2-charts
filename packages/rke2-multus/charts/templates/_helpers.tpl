# Copyright 2020 K8s Network Plumbing Group
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

{{/* Generate basic labels */}}
{{- define "multus.labels" }}
tier: node
app: {{ .Chart.Name }}
{{- end }}

{{- define "dynamicNetworksController.labels" }}
tier: node
app: {{ .Chart.Name }}-dnc
{{- end }}

{{- define "multiNetworkPolicy.labels" }}
tier: node
app: {{ .Chart.Name }}-mnp
{{- end }}

{{- define "system_default_registry" -}}
{{- if .Values.global.systemDefaultRegistry -}}
{{- printf "%s/" .Values.global.systemDefaultRegistry -}}
{{- else -}}
{{- "" -}}
{{- end -}}
{{- end -}}

{{/*
Render an image reference from an image dict with repository/tag and
primeRepository/primeTag. Usage:
  include "rke2-multus.image" (dict "root" $ "image" .Values.foo.image "name" "foo.image")
*/}}
{{- define "rke2-multus.image" -}}
{{- $root := .root -}}
{{- $image := .image -}}
{{- if and $root.Values.global.prime $root.Values.global.prime.enabled -}}
{{ template "system_default_registry" $root }}{{ required (printf "%s.primeRepository is required when global.prime.enabled=true" .name) $image.primeRepository }}:{{ required (printf "%s.primeTag is required when global.prime.enabled=true" .name) $image.primeTag }}
{{- else -}}
{{ template "system_default_registry" $root }}{{ required (printf "%s.repository is required" .name) $image.repository }}:{{ required (printf "%s.tag is required" .name) $image.tag }}
{{- end -}}
{{- end -}}
