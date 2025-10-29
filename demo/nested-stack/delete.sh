#!/bin/bash

#######################################
# Demo Nested Stack Deletion Script
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

# Check if stack exists
check_stack_exists() {
    if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &> /dev/null; then
        print_error "Stack $STACK_NAME does not exist in region $REGION"
        exit 1
    fi
}

# Get all nested stacks
get_nested_stacks() {
    print_header "Current Nested Stacks"

    aws cloudformation list-stack-resources \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'StackResourceSummaries[?ResourceType==`AWS::CloudFormation::Stack`].{Name:LogicalResourceId, PhysicalId:PhysicalResourceId, Status:ResourceStatus}' \
        --output table
}

# Check for S3 buckets that need to be emptied
check_s3_buckets() {
    print_header "Checking for S3 Buckets"

    # Get S3 bucket name from stack outputs
    BUCKET_NAME=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
        --output text 2>/dev/null || echo "")

    if [ -n "$BUCKET_NAME" ]; then
        print_warning "Found S3 Bucket: $BUCKET_NAME"

        # Check if bucket has objects
        OBJECT_COUNT=$(aws s3 ls "s3://$BUCKET_NAME" --recursive --summarize 2>/dev/null | grep "Total Objects:" | awk '{print $3}' || echo "0")

        if [ "$OBJECT_COUNT" -gt "0" ]; then
            print_warning "Bucket contains $OBJECT_COUNT object(s)"
            echo ""
            read -p "Do you want to empty the bucket before deletion? (yes/no): " empty_bucket

            if [ "$empty_bucket" == "yes" ]; then
                print_info "Emptying bucket..."
                aws s3 rm "s3://$BUCKET_NAME" --recursive --region "$REGION"
                print_success "Bucket emptied"
            else
                print_error "Cannot delete stack with non-empty S3 bucket."
                print_info "Please empty the bucket manually or run this script again and choose 'yes'"
                exit 1
            fi
        else
            print_info "Bucket is already empty"
        fi
    else
        print_info "No S3 buckets found in stack outputs"
    fi

    echo ""
}

# Delete the stack
delete_stack() {
    print_header "Deleting Stack: $STACK_NAME"

    print_warning "This will delete the following:"
    echo "  - Parent stack: $STACK_NAME"
    echo "  - All nested stacks (Network, Storage, Security)"
    echo "  - All AWS resources created by these stacks"
    echo ""

    read -p "Are you absolutely sure you want to delete? Type 'DELETE' to confirm: " confirm

    if [ "$confirm" != "DELETE" ]; then
        print_error "Deletion cancelled."
        exit 0
    fi

    print_info "Deleting stack..."
    aws cloudformation delete-stack \
        --stack-name "$STACK_NAME" \
        --region "$REGION"

    print_info "Waiting for stack deletion to complete (this may take a few minutes)..."
    aws cloudformation wait stack-delete-complete \
        --stack-name "$STACK_NAME" \
        --region "$REGION"

    print_success "Stack deleted successfully!"
}

# Verify deletion
verify_deletion() {
    print_header "Verifying Deletion"

    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &> /dev/null; then
        STACK_STATUS=$(aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$REGION" \
            --query 'Stacks[0].StackStatus' \
            --output text)

        print_warning "Stack still exists with status: $STACK_STATUS"
    else
        print_success "Stack has been completely deleted"
    fi
}

# Main deletion flow
main() {
    print_header "AWS CloudFormation Nested Stack Deletion"
    echo ""

    print_warning "Configuration:"
    echo "  Stack Name: $STACK_NAME"
    echo "  Region: $REGION"
    echo ""

    # Check if stack exists
    check_stack_exists
    echo ""

    # Show nested stacks
    get_nested_stacks
    echo ""

    # Check for S3 buckets
    check_s3_buckets

    # Delete stack
    delete_stack
    echo ""

    # Verify deletion
    verify_deletion
    echo ""

    print_header "Deletion Complete!"
    print_success "All nested stacks and resources have been deleted."
}

# Run main function
main
