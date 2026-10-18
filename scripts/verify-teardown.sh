#!/usr/bin/env bash
set -uo pipefail

echo "=== EKS clusters ==="
eksctl get cluster --region eu-north-1

echo ""
echo "=== Running/pending EC2 instances ==="
aws ec2 describe-instances \
  --region eu-north-1 \
  --filters "Name=instance-state-name,Values=running,pending" \
  --query "Reservations[].Instances[].{ID:InstanceId,Type:InstanceType,State:State.Name}" \
  --output table

echo ""
echo "=== Orphaned EBS volumes created by the EBS CSI driver (status available) ==="
aws ec2 describe-volumes \
  --region eu-north-1 \
  --filters "Name=tag:ebs.csi.aws.com/cluster,Values=true" "Name=status,Values=available" \
  --query "Volumes[].{ID:VolumeId,Size:Size,PVC:Tags[?Key=='kubernetes.io/created-for/pvc/name']|[0].Value,Namespace:Tags[?Key=='kubernetes.io/created-for/pvc/namespace']|[0].Value,CreatedAt:CreateTime}" \
  --output table

echo ""
echo "=== CloudFormation stacks stuck in DELETE_FAILED ==="
aws cloudformation list-stacks \
  --region eu-north-1 \
  --stack-status-filter DELETE_FAILED \
  --query "StackSummaries[?contains(StackName, 'aws-eks-project') || contains(StackName, 'eksctl')].{Name:StackName,Status:StackStatus}" \
  --output table

echo ""
echo "=== Done. Empty tables above = clean teardown. ==="
