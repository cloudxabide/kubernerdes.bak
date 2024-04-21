#!/bin/bash

# Status:  Need to work on this and figure out how to assign pre-determined addresses to service
#            Likely do an NSLOOKUP to get the IP from DNS, then assign

# Prometheus
kubectl patch svc generated-prometheus-server -n observability -p '{"spec": {"type": "LoadBalancer"}}'
kubectl describe svc generated-prometheus-server -n observability
# http://generated-prometheus-server.observability:9090

t
 Grafana
kubectl patch svc my-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl describe svc my-grafana -n monitoring
# 315 1860

# Hubble UI
kubectl patch svc hubble-ui -n kube-system -p '{"spec": {"type": "LoadBalancer"}}'
kubectl describe svc hubble-ui -n kube-system
