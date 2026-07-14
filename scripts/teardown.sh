#!/usr/bin/env bash
set -euo pipefail

echo "Tearing down EKS cluster..."
eksctl delete cluster -f infra/eksctl/cluster.yaml --wait

echo "Tearing down CloudFormation foundation stack..."
aws cloudformation delete-stack \
  --stack-name aws-eks-project-foundation \
  --region eu-north-1

aws cloudformation wait stack-delete-complete \
  --stack-name aws-eks-project-foundation \
  --region eu-north-1

echo "Teardown complete."