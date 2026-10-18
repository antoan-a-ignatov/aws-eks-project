#!/usr/bin/env bash
set -euo pipefail

echo "Bootstrapping cluster add-ons (ESO, Strimzi operator) via Ansible..."
(cd ansible && ansible-playbook playbooks/bootstrap.yml)

echo "Applying StorageClass..."
kubectl apply -f k8s/base/storage/storageclass.yaml

echo "Applying secrets chain (ClusterSecretStore + ExternalSecret)..."
kubectl apply -f k8s/base/secrets/secret-store.yaml
kubectl apply -f k8s/base/secrets/external-secret-db-credentials.yaml

echo "Waiting for db-credentials secret to sync..."
kubectl wait --for=condition=Ready externalsecret/db-credentials -n default --timeout=60s

echo "Installing PostgreSQL..."
helm upgrade --install db helm/postgres --namespace default --wait

echo "Applying Kafka cluster and topic..."
kubectl apply -f k8s/base/kafka/kafka-cluster.yaml
kubectl apply -f k8s/base/kafka/kafka-topic-orders.yaml

echo "Waiting for Kafka cluster to be ready..."
kubectl wait --for=condition=Ready kafka/order-kafka -n kafka --timeout=300s

MONITORING_OVERLAY="${MONITORING_OVERLAY:-dev}"
case "$MONITORING_OVERLAY" in
  dev|demo) ;;
  *) echo "ERROR: MONITORING_OVERLAY must be dev or demo (prod is never deployed on this cluster)." >&2; exit 1 ;;
esac

echo "Checking IRSA service accounts created by eksctl..."
for sa in alertmanager fluent-bit; do
  if ! kubectl get serviceaccount "$sa" -n monitoring >/dev/null 2>&1; then
    echo "ERROR: service account $sa not found in namespace monitoring. Check iam.serviceAccounts in infra/eksctl/cluster.yaml." >&2
    exit 1
  fi
done

echo "Creating Grafana admin secret (only if missing)..."
if ! kubectl get secret grafana-admin -n monitoring >/dev/null 2>&1; then
  kubectl create secret generic grafana-admin -n monitoring \
    --from-literal=admin-user=admin \
    --from-literal=admin-password="$(openssl rand -base64 24)"
fi

echo "Rendering monitoring overlay: ${MONITORING_OVERLAY}..."
RENDERED="$(mktemp)"
trap 'rm -f "$RENDERED"' EXIT
kubectl kustomize --enable-helm "k8s/overlays/${MONITORING_OVERLAY}" > "$RENDERED"

echo "Applying monitoring manifests (pass 1, errors expected until CRDs register)..."
kubectl apply --server-side -f "$RENDERED" || echo "Pass 1 reported errors, continuing after the CRD wait."

echo "Waiting for CRDs to be established..."
kubectl wait --for=condition=Established crd --all --timeout=120s

echo "Applying monitoring manifests (pass 2)..."
kubectl apply --server-side -f "$RENDERED"

echo "Waiting for monitoring components..."
kubectl wait --for=condition=Available deployment --all -n monitoring --timeout=300s
kubectl wait --for=condition=Available prometheus/kube-prometheus-stack-prometheus -n monitoring --timeout=300s
kubectl wait --for=condition=Available alertmanager/kube-prometheus-stack-alertmanager -n monitoring --timeout=300s

echo "Installing Fluent Bit..."
helm upgrade --install fluent-bit eks/aws-for-fluent-bit --version 0.2.0 --namespace monitoring -f k8s/base/monitoring/fluent-bit-values.yaml --wait

echo "Infra and observability ready (monitoring overlay: ${MONITORING_OVERLAY})."
echo "Grafana password: kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d"
echo "Push to main (or rerun the pipeline) to deploy app services."
