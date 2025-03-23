#!/bin/bash

set -e

# Load .env file
if [ -f .env ]; then
  source .env
else
  echo "❌ .env file not found!"
  exit 1
fi

# Validate required env variables
if [ -z "$S3_BUCKET" ] || [ -z "$JWT_SECRET" ]; then
  echo "❌ S3_BUCKET or JWT_SECRET not set in .env file"
  exit 1
fi

# Check if bucket exists, if not create it
if ! aws s3 ls "s3://$S3_BUCKET" > /dev/null 2>&1; then
  echo "📦 S3 bucket $S3_BUCKET does not exist. Creating it..."
  aws s3 mb s3://$S3_BUCKET
  echo "✅ Bucket created!"
else
  echo "📦 S3 bucket $S3_BUCKET already exists."
fi

# Timestamp to version S3 uploads (ensures Lambda update)
TIMESTAMP=$(date +%s)

# Configuration
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
cd lambdas/registerUser && zip -r ../../registerUser.zip . > /dev/null && cd -
cd lambdas/loginUser && zip -r ../../loginUser.zip . > /dev/null && cd -
cd lambdas/getUserInfo && zip -r ../../getUserInfo.zip . > /dev/null && cd -

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
    CodeS3Key=$S3_PREFIX \
    JwtSecret=$JWT_SECRET

# Show API Gateway endpoint
echo "🔍 Fetching API Gateway endpoint..."
API_URL=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" \
  --output text)

echo "✅ Deployment complete!"
echo "📡 API Gateway URL: $API_URL"
