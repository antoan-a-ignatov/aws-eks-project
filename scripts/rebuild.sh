#!/usr/bin/env bash
set -euo pipefail

CONNECTION_ARN="arn:aws:codeconnections:eu-north-1:180571023536:connection/ea9540c2-4f1f-47a9-a609-7a348fbe6f36"

echo "Deploying CloudFormation foundation stack..."
aws cloudformation deploy \
  --template-file infra/cloudformation/foundation.yaml \
  --stack-name aws-eks-project-foundation \
  --parameter-overrides ProjectName=aws-eks-project CodeConnectionArn="${CONNECTION_ARN}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region eu-north-1

echo "Creating EKS cluster..."
eksctl create cluster -f infra/eksctl/cluster.yaml

echo "Cluster ready. Verifying nodes..."
kubectl get nodes

NODE_IDS=$(aws ec2 describe-instances --region eu-north-1 \
  --filters "Name=tag:eks:cluster-name,Values=aws-eks-project" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" --output text)

for id in $NODE_IDS; do
  aws ec2 modify-instance-credit-specification \
    --region eu-north-1 \
    --instance-credit-specification "InstanceId=${id},CpuCredits=standard"
done