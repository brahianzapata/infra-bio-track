# Guía para agentes — infra-bio-track

No hay CLAUDE.md local. Inspecciona manifiestos, README y estado de despliegue antes de proponer cambios.

Infraestructura compartida: trata cualquier cambio como potencialmente productivo; usa entornos explícitos y nunca imprimas o versiones secretos.

- Realiza validaciones no mutantes primero.
- No apliques, destruyas ni alteres recursos remotos sin autorización explícita.
- Usa rama y PR; nunca main directamente.
## Contexto operativo detallado

### Estructura y alcance
- terraform/envs contiene shared, staging y prod; terraform/modules contiene VPC, EKS, ECR, secrets e IAM GitHub.
- charts contiene Helm charts de AI, Garmin, Calendar, Connections, Training, Users y Health, con una base compartida en charts/_base.
- scripts y workflows automatizan infraestructura; revisa inputs, backend/state y entorno antes de cualquier acción.

### Reglas de cambio
- Un cambio de módulo puede afectar staging y producción. Mantén compatibilidad de inputs/outputs y versiona migraciones de infraestructura de forma incremental.
- Secretos se referencian, nunca se codifican en Terraform values, Helm values, manifests o logs.
- Un chart debe declarar recursos, probes, env vars y service ports coherentes con el microservicio y gateway.
- No ejecutes terraform apply/destroy, helm upgrade, kubectl apply/delete ni rotación de secretos sin autorización explícita, plan revisado y entorno confirmado.

### Validación
- Ejecuta fmt/validate/plan o helm template solo cuando el estado y credenciales sean correctos; informa el alcance del plan.
- Revisar drift y cambios de IAM/red requiere especial cuidado y revisión humana.
