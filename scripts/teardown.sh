#!/usr/bin/env bash
set -euo pipefail

echo "Tearing down EKS cluster..."
eksctl delete cluster -f infra/eksctl/cluster.yaml --wait

echo "Teardown complete. Foundation and pipeline stacks left intact (persistent infra)."