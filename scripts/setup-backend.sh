#!/bin/bash
set -e

echo "=== Setting up Terraform S3 Backend ==="
echo ""

ACCOUNT_ID="326698396633"
REGION="us-east-1"
BUCKET_NAME="terraform-state-${ACCOUNT_ID}"
DYNAMODB_TABLE="terraform-state-lock"

echo "Account ID: $ACCOUNT_ID"
echo "Region: $REGION"
echo "Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo ""

# Check if bucket exists
if aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
    echo "✓ S3 bucket already exists: ${BUCKET_NAME}"
else
    echo "Creating S3 bucket: ${BUCKET_NAME}"
    aws s3api create-bucket \
        --bucket "${BUCKET_NAME}" \
        --region "${REGION}"
    
    echo "Enabling versioning..."
    aws s3api put-bucket-versioning \
        --bucket "${BUCKET_NAME}" \
        --versioning-configuration Status=Enabled
    
    echo "Enabling encryption..."
    aws s3api put-bucket-encryption \
        --bucket "${BUCKET_NAME}" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    
    echo "Blocking public access..."
    aws s3api put-public-access-block \
        --bucket "${BUCKET_NAME}" \
        --public-access-block-configuration \
            BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    
    echo "✓ S3 bucket created and configured"
fi

# Check if DynamoDB table exists
if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${REGION}" 2>/dev/null; then
    echo "✓ DynamoDB table already exists: ${DYNAMODB_TABLE}"
else
    echo "Creating DynamoDB table: ${DYNAMODB_TABLE}"
    aws dynamodb create-table \
        --table-name "${DYNAMODB_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${REGION}"
    
    echo "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "${DYNAMODB_TABLE}" --region "${REGION}"
    
    echo "✓ DynamoDB table created"
fi

echo ""
echo "=== Backend Setup Complete ==="
echo ""
echo "Update your environments/root/main.tf backend configuration:"
echo ""
echo "backend \"s3\" {"
echo "  bucket         = \"${BUCKET_NAME}\""
echo "  key            = \"control-tower/terraform.tfstate\""
echo "  region         = \"${REGION}\""
echo "  encrypt        = true"
echo "  dynamodb_table = \"${DYNAMODB_TABLE}\""
echo "}"
