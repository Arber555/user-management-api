#!/bin/bash

set -e

# Load .env
if [ -f .env ]; then
  source .env
else
  echo "❌ .env file not found!"
  exit 1
fi

STACK_NAME="user-management-api"

echo "🧨 Deleting CloudFormation stack: $STACK_NAME..."
aws cloudformation delete-stack --stack-name $STACK_NAME

echo "⏳ Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME
echo "✅ Stack successfully deleted!"

# Delete entire S3 bucket and its contents
echo "🪓 Deleting S3 bucket: $S3_BUCKET (including all contents)"
aws s3 rb s3://$S3_BUCKET --force || true

echo "✅ Cleanup complete!"
