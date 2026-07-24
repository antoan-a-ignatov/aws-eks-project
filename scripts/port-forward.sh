#!/usr/bin/env bash
kubectl port-forward svc/order-service-order-service 3000:3000 &
kubectl port-forward svc/frontend-frontend 8080:80 &
wait