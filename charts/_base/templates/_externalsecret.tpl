{{- define "bio-track-base.externalsecret" -}}
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ .Release.Name }}-secrets
  namespace: {{ .Release.Namespace }}
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: {{ .Release.Name }}-secrets
    creationPolicy: Owner
  dataFrom:
    - extract:
        key: {{ .Values.secrets.awsSecretName }}
{{- end }}
