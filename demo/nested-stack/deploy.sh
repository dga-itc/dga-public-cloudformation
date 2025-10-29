#!/bin/bash

#######################################
# Demo Nested Stack Deployment Script
#######################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="demo-nested-stack"
REGION="ap-southeast-1"
BUCKET_NAME="my-cloudformation-templates"  # Change this to your bucket name
TEMPLATE_PREFIX="demo/nested-stack/"

# Functions
print_header() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    print_success "AWS CLI is installed"
}

# Check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    print_success "AWS credentials are configured"

    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_info "AWS Account ID: $ACCOUNT_ID"
}

# Create S3 bucket if not exists
create_bucket_if_not_exists() {
    print_header "Step 1: Check/Create S3 Bucket"

    if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
        print_warning "Bucket $BUCKET_NAME does not exist. Creating..."

        if [ "$REGION" == "us-east-1" ]; then
            aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"
        else
            aws s3 mb "s3://$BUCKET_NAME" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
        fi

        print_success "Bucket created: $BUCKET_NAME"
    else
        print_success "Bucket already exists: $BUCKET_NAME"
    fi
}

# Upload templates to S3
upload_templates() {
    print_header "Step 2: Upload Child Templates to S3"

    local templates=("network-stack.yaml" "storage-stack.yaml" "security-stack.yaml")

    for template in "${templates[@]}"; do
        print_info "Uploading $template..."
        aws s3 cp "$template" "s3://$BUCKET_NAME/$TEMPLATE_PREFIX" --region "$REGION"
        print_success "Uploaded: $template"
    done

    echo ""
    print_info "Listing uploaded templates:"
    aws s3 ls "s3://$BUCKET_NAME/$TEMPLATE_PREFIX"
}

# Deploy CloudFormation stack
deploy_stack() {
    print_header "Step 3: Deploy CloudFormation Stack"

    # Check if stack already exists
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &> /dev/null; then
        print_warning "Stack $STACK_NAME already exists. Updating..."

        aws cloudformation update-stack \
            --stack-name "$STACK_NAME" \
            --template-body file://main-stack.yaml \
            --parameters file://parameters.json \
            --region "$REGION" \
            --capabilities CAPABILITY_IAM

        print_info "Waiting for stack update to complete..."
        aws cloudformation wait stack-update-complete \
            --stack-name "$STACK_NAME" \
            --region "$REGION"

        print_success "Stack updated successfully!"
    else
        print_info "Creating new stack: $STACK_NAME"

        aws cloudformation create-stack \
            --stack-name "$STACK_NAME" \
            --template-body file://main-stack.yaml \
            --parameters file://parameters.json \
            --region "$REGION" \
            --capabilities CAPABILITY_IAM

        print_info "Waiting for stack creation to complete (this may take a few minutes)..."
        aws cloudformation wait stack-create-complete \
            --stack-name "$STACK_NAME" \
            --region "$REGION"

        print_success "Stack created successfully!"
    fi
}

# Show stack outputs
show_outputs() {
    print_header "Step 4: Stack Outputs"

    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs' \
        --output table
}

# Show all nested stacks
show_nested_stacks() {
    print_header "Nested Stacks Created"

    aws cloudformation list-stacks \
        --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
        --region "$REGION" \
        --query "StackSummaries[?contains(StackName, '$STACK_NAME')].{Name:StackName, Status:StackStatus, CreatedTime:CreationTime}" \
        --output table
}

# Main deployment flow
main() {
    print_header "AWS CloudFormation Nested Stack Deployment"
    echo ""

    print_warning "Configuration:"
    echo "  Stack Name: $STACK_NAME"
    echo "  Region: $REGION"
    echo "  S3 Bucket: $BUCKET_NAME"
    echo "  Template Prefix: $TEMPLATE_PREFIX"
    echo ""

    # Confirm before proceeding
    read -p "Do you want to proceed with deployment? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_error "Deployment cancelled."
        exit 0
    fi

    echo ""

    # Run deployment steps
    check_aws_cli
    check_aws_credentials
    echo ""

    create_bucket_if_not_exists
    echo ""

    upload_templates
    echo ""

    deploy_stack
    echo ""

    show_outputs
    echo ""

    show_nested_stacks
    echo ""

    print_header "Deployment Complete!"
    print_success "All nested stacks have been deployed successfully!"
    echo ""
    print_info "To view your resources in AWS Console:"
    echo "  https://console.aws.amazon.com/cloudformation/home?region=$REGION#/stacks"
}

# Run main function
main
