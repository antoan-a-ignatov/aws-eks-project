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

echo "Infra ready. Push to main (or rerun the pipeline) to deploy app services."