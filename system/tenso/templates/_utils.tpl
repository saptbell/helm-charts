{{- define "openstack_region" -}}
  {{ .Values.tenso.openstack_region | default .Values.global.region }}
{{- end -}}

{{- define "tenso_image" -}}
  {{ $.Values.global.registry }}/tenso:{{ $.Values.tenso.image_tag | required ".Values.tenso.image_tag is missing" }}
{{- end -}}

{{- define "tenso_environment" }}
- name:  TENSO_DEBUG
  value: 'false'
- name:  OS_AUTH_URL
  value: "https://identity-3.{{ include "openstack_region" $ }}.{{ $.Values.global.tld }}/v3"
- name:  OS_AUTH_VERSION
  value: '3'
- name:  OS_IDENTITY_API_VERSION
  value: '3'
- name:  OS_INTERFACE
  value: public # Tenso lives in scaleout and thus needs to go through the public API endpoints
- name:  OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: tenso-secret
      key: service_user_password
- name:  OS_PROJECT_DOMAIN_NAME
  value: 'ccadmin'
- name:  OS_PROJECT_NAME
  value: 'master'
- name:  OS_REGION_NAME
  value: {{ quote (include "openstack_region" $) }}
- name:  OS_USER_DOMAIN_NAME
  value: 'Default'
- name:  OS_USERNAME
  value: 'tenso'
- name:  TENSO_API_LISTEN_ADDRESS
  value: ':80'
- name: TENSO_AWX_WORKFLOW_SWIFT_CONTAINER
  value: tenso-awx-workflow-events
- name:  TENSO_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: tenso-secret
      key: postgres_password
- name: TENSO_DB_HOSTNAME
  value: "{{ .Release.Name }}-postgresql"
- name: TENSO_DB_CONNECTION_OPTIONS
  value: 'sslmode=disable'
- name: TENSO_HELM_DEPLOYMENT_LOGSTASH_HOST
  value: {{ quote $.Values.tenso.elk_logstash_host }}
- name: TENSO_HELM_DEPLOYMENT_SWIFT_CONTAINER
  value: tenso-deployment-events
- name: TENSO_OSLO_POLICY_PATH
  value: '/etc/tenso/policy.yaml'
- name: TENSO_ROUTES
  value: >
    helm-deployment-from-concourse.v1 -> helm-deployment-to-elk.v1,
    helm-deployment-from-concourse.v1 -> helm-deployment-to-swift.v1,
    infra-workflow-from-awx.v1 -> infra-workflow-to-swift.v1,
    {{- if .Values.tenso.servicenow.create_change_url }}
    helm-deployment-from-concourse.v1 -> helm-deployment-to-servicenow.v1,
    infra-workflow-from-awx.v1 -> infra-workflow-to-servicenow.v1,
    {{- if hasPrefix "qa" .Values.global.region }}{{/* NOTE: Do not enable in prod until validation/translation/delivery is fully implemented in Tenso. */}}
    terraform-deployment-from-concourse.v1 -> terraform-deployment-to-servicenow.v1,
    {{- end }}
    {{- end }}
{{- if .Values.tenso.servicenow.create_change_url }}
- name:  TENSO_SERVICENOW_CREATE_CHANGE_URL
  value: {{ quote $.Values.tenso.servicenow.create_change_url }}
- name:  TENSO_SERVICENOW_MAPPING_CONFIG_PATH
  value: /etc/tenso/servicenow-mapping.yaml
{{- if .Values.tenso.servicenow.auth_url }}
- name:  TENSO_SERVICENOW_TOKEN_URL
  value: {{ quote $.Values.tenso.servicenow.auth_url }}
- name:  TENSO_SERVICENOW_USERNAME
  value: {{ quote $.Values.tenso.servicenow.username }}
- name:  TENSO_SERVICENOW_PASSWORD
  valueFrom:
    secretKeyRef:
      name: tenso-secret
      key: servicenow_password
{{- end }}
{{- if .Values.tenso.servicenow.client_cert }}
- name:  TENSO_SERVICENOW_CLIENT_CERT
  value: /etc/tenso/servicenow-client-cert.pem
- name:  TENSO_SERVICENOW_PRIVATE_KEY
  value: /etc/tenso/servicenow-private-key.pem
{{- end }}
{{- end }}
- name:  TENSO_WORKER_LISTEN_ADDRESS
  value: ':80'
{{- end -}}
