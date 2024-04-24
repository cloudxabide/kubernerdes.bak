#!/bin/bash

# Status:  Need to work on this and figure out how to assign pre-determined addresses to service
#            Likely do an NSLOOKUP to get the IP from DNS, then assign
APPDOMAIN="apps.kubernerdes.lab"

cd ~/eksa/$CLUSTER_NAME/latest/

SERVICEMAPFILE=./SERVICEMAP.csv
cat << EOF2 | tee $SERVICEMAPFILE
#APPNAME|NAMESPACE|PORT
generated-prometheus-server|observability|9090
hubble-ui|kube-system|80
my-grafana|monitoring|80
EOF2

grep -v \# $SERVICEMAPFILE | awk -F"|" '{ print $1" "$2 }' | while read -r APPNAME NAMESPACE PORT
do
  #echo "$APPNAME $NAMESPACE $PORT"
  echo "kubectl patch svc $APPNAME -n $NAMESPACE -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'"
  kubectl patch svc $APPNAME -n $NAMESPACE -p '{"spec": {"type": "LoadBalancer"}}'
  echo
done

exit 0

###
## NOTE:  Hanging on to these commands as they are what I had been testing/using previously

# Prometheus
APPNAME=generated-prometheus-server
NAMESPACE=observability
IPADDR=$(dig +short $APPNAME.$APPDOMAIN)
kubectl patch svc $APPNAME -n $NAMESPACE -p '{"spec": {"type": "LoadBalancer"}}'
kubectl describe svc $APPNAME -n $NAMESPACE
# the following does not work
kubectl patch svc $APPNAME -n $NAMESPACE -p '{"metadata": {"annotations": {"metallb.universe.tf/address-pool": $IPADDR}}}'
kubectl patch svc $APPNAME -n $NAMESPACE -p '{"metadata": {"annotations": {"metallb.universe.tf/ip-allocated-from-pool": "default"}}'
kubectl patch svc $APPNAME -n $NAMESPACE -p '{"status": {"loadBalancer": {"ingress": {"ip": "$IPADDR"}}}}'

kubectl patch svc generated-prometheus-server -n observability -p '{"spec": {"type": "LoadBalancer"}}'
kubectl describe svc generated-prometheus-server -n observability
# http://generated-prometheus-server.observability:9090


# Grafana
APPNAME=my-grafana
NAMESPACE=monitoring
kubectl patch svc $APPNAME -n $NAMESPACE -p '{"spec": {"type": "LoadBalancer"}}'
kubectl describe svc $APPNAME -n $NAMESPACE

# Add these dashboards 315 1860
#kubectl patch svc my-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
#kubectl describe svc my-grafana -n monitoring

# Hubble UI
APPNAME=hubble-ui
NAMESPACE=kube-system
kubectl patch svc $APPNAME -n $NAMESPACE -p '{"spec": {"type": "LoadBalancer"}}'
kubectl describe svc $APPNAME -n $NAMESPACE

#kubectl patch svc hubble-ui -n kube-system -p '{"spec": {"type": "LoadBalancer"}}'
#kubectl describe svc hubble-ui -n kube-system


exit 0

kubectl get svc/generated-prometheus-server -n $NAMESPACE -o=json
SERVICEMAP
