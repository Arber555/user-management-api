#!/bin/bash

set -e

# Timestamp to version S3 uploads (ensures Lambda update)
TIMESTAMP=$(date +%s)

# Configuration
S3_BUCKET="arber-user-api-bucket-3249"
S3_PREFIX="lambda-code/$TIMESTAMP"
STACK_NAME="user-management-api"
TEMPLATE_FILE="cloudformation/user-management-api.yaml"

# Clean up old zip files
echo "🧹 Cleaning up old zip files..."
rm -f registerUser.zip loginUser.zip getUserInfo.zip

# Install Lambda dependencies
echo "🔧 Installing Lambda dependencies..."
for dir in lambdas/*; do
  echo "Installing in $dir..."
  (cd "$dir" && npm install --omit=dev)
done

# Create fresh ZIPs
echo "📦 Zipping Lambda functions..."

cd lambdas/registerUser
zip -r ../../registerUser.zip . > /dev/null
cd -

cd lambdas/loginUser
zip -r ../../loginUser.zip . > /dev/null
cd -

cd lambdas/getUserInfo
zip -r ../../getUserInfo.zip . > /dev/null
cd -

# Upload to S3
echo "☁️  Uploading zips to S3 under prefix: $S3_PREFIX"
aws s3 cp registerUser.zip s3://$S3_BUCKET/$S3_PREFIX/registerUser.zip
aws s3 cp loginUser.zip s3://$S3_BUCKET/$S3_PREFIX/loginUser.zip
aws s3 cp getUserInfo.zip s3://$S3_BUCKET/$S3_PREFIX/getUserInfo.zip

# Deploy CloudFormation
echo "🚀 Deploying CloudFormation stack..."
aws cloudformation deploy \
  --template-file $TEMPLATE_FILE \
  --stack-name $STACK_NAME \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    CodeS3Bucket=$S3_BUCKET \
    CodeS3Key=$S3_PREFIX

# Show API Gateway endpoint
echo "🔍 Fetching API Gateway endpoint..."
API_URL=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" \
  --output text)

echo "✅ Deployment complete!"
echo "📡 API Gateway URL: $API_URL"
