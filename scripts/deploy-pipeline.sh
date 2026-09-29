#!/usr/bin/env bash
set -euo pipefail

echo "Deploying pipeline.yaml (CodePipeline + CodeBuild) to stack aws-eks-project-pipeline..."

aws cloudformation deploy \
  --template-file infra/cloudformation/pipeline.yaml \
  --stack-name aws-eks-project-pipeline \
  --capabilities CAPABILITY_NAMED_IAM \
  --region eu-north-1 \
  --parameter-overrides \
    ProjectName=aws-eks-project \
    CodeConnectionArn=arn:aws:codeconnections:eu-north-1:180571023536:connection/ea9540c2-4f1f-47a9-a609-7a348fbe6f36 \
    GitHubFullRepositoryId=antoan-a-ignatov/aws-eks-project \
    GitHubBranch=main

echo "Pipeline stack deploy complete."
