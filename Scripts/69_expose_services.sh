#!/bin/bash


# Prometheus
kubectl patch svc generated-prometheus-server -n observability -p '{"spec": {"type": "LoadBalancer"}}'
kubectl describe svc generated-prometheus-server -n observability
# http://generated-prometheus-server.observability:9090

# Grafana
kubectl patch svc my-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl describe svc my-grafana -n monitoring
# 315 1860

# Hubble UI
kubectl patch svc hubble-ui -n kube-system -p '{"spec": {"type": "LoadBalancer"}}'
kubectl describe svc hubble-ui -n kube-system
