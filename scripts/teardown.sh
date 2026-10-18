#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="aws-eks-project"
REGION="eu-north-1"

# Find the kubectl context eksctl created for THIS cluster (format: user@cluster.region.eksctl.io).
CTX="$(kubectl config get-contexts -o name 2>/dev/null | grep -E "@${CLUSTER_NAME}\.${REGION}\.eksctl\.io$" | head -n1 || true)"

# A tiny wrapper so every kubectl call below is pinned to that context, with a timeout.
kc() { kubectl --context "$CTX" --request-timeout=30s "$@"; }

if [ -z "$CTX" ]; then
  echo "No kubectl context found for ${CLUSTER_NAME}; skipping in-cluster cleanup."
elif ! kc get namespace default >/dev/null 2>&1; then
  echo "Cluster ${CLUSTER_NAME} is not reachable; skipping in-cluster cleanup."
else

  echo "Removing workloads that own EBS volumes..."
  helm --kube-context "$CTX" uninstall db -n default --wait || true
  kc delete prometheus,alertmanager --all -n monitoring --wait --timeout=180s || true
  kc delete kafka,kafkanodepool --all -n kafka --ignore-not-found --wait --timeout=300s || true

  echo "Deleting any remaining PVCs..."
  # PVCs created by StatefulSets and by Strimzi are not removed with their owners, so delete them explicitly.
  for ns in default kafka monitoring; do
    kc delete pvc --all -n "$ns" --wait --timeout=180s || true
  done

  echo "Waiting for the volumes (PVs) to be deleted by the EBS CSI driver..."
  kc wait --for=delete pv --all --timeout=300s || true
fi

echo "Tearing down EKS cluster..."
eksctl delete cluster -f infra/eksctl/cluster.yaml --wait

echo "Teardown complete. Foundation and pipeline stacks left intact (persistent infra)."
