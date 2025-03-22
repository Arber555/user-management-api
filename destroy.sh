#!/bin/bash

set -e

# Configuration
STACK_NAME="user-management-api"
S3_BUCKET="arber-user-api-bucket-3249"
S3_PREFIX="lambda-code"

echo "🧨 Deleting CloudFormation stack: $STACK_NAME..."
aws cloudformation delete-stack --stack-name $STACK_NAME

echo "⏳ Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME
echo "✅ Stack successfully deleted!"

echo "🧹 Cleaning up Lambda zip files in S3..."
aws s3 rm s3://$S3_BUCKET/$S3_PREFIX/ --recursive

echo "✅ Cleanup complete!"
