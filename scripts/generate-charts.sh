#!/usr/bin/env bash
# Usage: AWS_ACCOUNT_ID=123456789012 ./scripts/generate-charts.sh
set -euo pipefail
: "${AWS_ACCOUNT_ID:?Need AWS_ACCOUNT_ID}"

declare -A PATHS=(
  ["usrv-bio-track-users"]="/api/users"
  ["usrv-bio-track-garmin"]="/api/garmin"
  ["usrv-bio-track-connections"]="/api/connections"
  ["usrv-bio-track-calendar"]="/api/calendar"
  ["usrv-bio-track-ai"]="/ai"
  ["usrv-bio-track-training"]="/api/training"
  ["usrv-bio-track-health"]="/health"
)

for SVC in "${!PATHS[@]}"; do
  P="${PATHS[$SVC]}"
  D="charts/$SVC"
  T="$D/templates"
  mkdir -p "$T"

  cat > "$D/Chart.yaml" << EOF
apiVersion: v2
name: $SVC
version: 0.1.0
description: Bio Track microservice — $SVC
dependencies:
  - name: bio-track-base
    version: "0.1.0"
    repository: "file://../_base"
EOF

  cat > "$D/values.yaml" << EOF
image:
  repository: ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/$SVC
  tag: latest

replicaCount: 2

service:
  port: 8080

hpa:
  minReplicas: 2
  maxReplicas: 8
  cpuThreshold: 70

resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "500m"

secrets:
  awsSecretName: bio-track/prod/$SVC

ingress:
  host: api.eks.biotrackai.com
  path: $P
EOF

  cat > "$D/values.staging.yaml" << EOF
replicaCount: 1
hpa:
  minReplicas: 1
  maxReplicas: 3
secrets:
  awsSecretName: bio-track/staging/$SVC
EOF

  printf '{{ include "bio-track-base.deployment" . }}\n'    > "$T/deployment.yaml"
  printf '{{ include "bio-track-base.service" . }}\n'       > "$T/service.yaml"
  printf '{{ include "bio-track-base.hpa" . }}\n'           > "$T/hpa.yaml"
  printf '{{ include "bio-track-base.externalsecret" . }}\n' > "$T/externalsecret.yaml"
  printf '{{ include "bio-track-base.ingress" . }}\n'       > "$T/ingress.yaml"

  echo "Generated: $D"
done
echo "Done. Run: make lint-charts"
