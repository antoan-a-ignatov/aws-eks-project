#!/usr/bin/env bash
set -euo pipefail

# Local access to the cluster UIs. The cluster has no ALB and no public
# endpoints by design, so everything is reached through port-forwards.

pkill -f "kubectl port-forward" 2>/dev/null || true
sleep 1

forward() {
  nohup kubectl port-forward "$2" "$3" -n "$1" >/dev/null 2>&1 &
}

forward monitoring svc/kube-prometheus-stack-prometheus   9090:9090
forward monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
forward monitoring svc/kube-prometheus-stack-grafana      3001:80
forward default    svc/frontend-frontend                  8080:80
forward default    svc/order-service-order-service        3000:3000

sleep 3
echo "Port-forwards running:"
pgrep -af "kubectl port-forward" | sed 's/.*kubectl/kubectl/'
