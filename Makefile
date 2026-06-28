# Bio Track EKS Infra
# Required env vars: AWS_ACCOUNT_ID, AWS_REGION (default us-east-1)
AWS_REGION    ?= us-east-1
NAMESPACE      = bio-track
STAGING_CLUSTER = bio-track-staging
PROD_CLUSTER    = bio-track-prod

TF_BACKEND_ARGS = \
  -backend-config="bucket=bio-track-tf-state-$(AWS_ACCOUNT_ID)" \
  -backend-config="dynamodb_table=bio-track-tf-lock" \
  -backend-config="region=$(AWS_REGION)"

.PHONY: bootstrap \
        init-staging plan-staging apply-staging \
        init-prod    plan-prod    apply-prod    \
        kubeconfig-staging kubeconfig-prod      \
        generate-charts lint-charts             \
        deploy-all-staging deploy-all-prod

bootstrap:
	AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID) AWS_REGION=$(AWS_REGION) ./bootstrap.sh

init-staging:
	cd terraform/envs/staging && terraform init -input=false $(TF_BACKEND_ARGS)

plan-staging: init-staging
	cd terraform/envs/staging && \
	  terraform plan -input=false \
	    -var="aws_account_id=$(AWS_ACCOUNT_ID)" \
	    -out=staging.tfplan

apply-staging: plan-staging
	cd terraform/envs/staging && terraform apply -auto-approve -input=false staging.tfplan

init-prod:
	cd terraform/envs/prod && terraform init -input=false $(TF_BACKEND_ARGS)

plan-prod: init-prod
	cd terraform/envs/prod && \
	  terraform plan -input=false \
	    -var="aws_account_id=$(AWS_ACCOUNT_ID)" \
	    -out=prod.tfplan

apply-prod: plan-prod
	cd terraform/envs/prod && terraform apply -auto-approve -input=false prod.tfplan

kubeconfig-staging:
	aws eks update-kubeconfig --name $(STAGING_CLUSTER) --region $(AWS_REGION)

kubeconfig-prod:
	aws eks update-kubeconfig --name $(PROD_CLUSTER) --region $(AWS_REGION)

generate-charts:
	AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID) ./scripts/generate-charts.sh

lint-charts:
	@for chart in charts/usrv-bio-track-*/; do \
	  helm dependency update "$$chart" 2>/dev/null; \
	  helm lint "$$chart" || exit 1; \
	done

deploy-all-staging: kubeconfig-staging lint-charts
	@for chart in charts/usrv-bio-track-*/; do \
	  name=$$(basename "$$chart"); \
	  echo "[deploy] $$name → staging"; \
	  helm upgrade --install "$$name" "$$chart" \
	    --namespace $(NAMESPACE) --create-namespace \
	    -f "$$chart/values.staging.yaml" \
	    --wait --timeout 5m; \
	done

deploy-all-prod: kubeconfig-prod lint-charts
	@for chart in charts/usrv-bio-track-*/; do \
	  name=$$(basename "$$chart"); \
	  echo "[deploy] $$name → prod"; \
	  helm upgrade --install "$$name" "$$chart" \
	    --namespace $(NAMESPACE) --create-namespace \
	    --wait --timeout 5m; \
	done
