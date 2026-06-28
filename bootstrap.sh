#!/usr/bin/env bash
# One-time: create S3 bucket + DynamoDB table for Terraform remote state.
# Usage: AWS_ACCOUNT_ID=123456789012 ./bootstrap.sh
set -euo pipefail

: "${AWS_ACCOUNT_ID:?Need AWS_ACCOUNT_ID}"
AWS_REGION="${AWS_REGION:-us-east-1}"
BUCKET="bio-track-tf-state-${AWS_ACCOUNT_ID}"
TABLE="bio-track-tf-lock"

echo "[bootstrap] Creating S3 bucket: $BUCKET"
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$AWS_REGION" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION" 2>/dev/null || echo "  already exists"

aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "[bootstrap] Creating DynamoDB table: $TABLE"
aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$AWS_REGION" 2>/dev/null || echo "  already exists"

echo ""
echo "[bootstrap] Done. Use these values in terraform init:"
echo "  bucket         = \"$BUCKET\""
echo "  dynamodb_table = \"$TABLE\""
echo "  region         = \"$AWS_REGION\""
