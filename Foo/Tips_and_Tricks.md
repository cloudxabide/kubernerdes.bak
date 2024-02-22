# Tips and Tricks

## Helpful commands
```
for NS in $(kubectl get ns | grep -v ^NAME | awk '{ print $1 }'); do echo "Namespace: $NS"; kubectl top pods -n $NS --sort-by=memory; echo; done
```


# You will see 3 containers start and run (an ECR container, the KIND cluster, then "boots")
watch docker ps -a

docker logs -f $(docker ps -a | grep boots | awk '{ print $1 }')

# You can then start powering on your NUC and boot from the network and watch the Docker logs

# Random "shortcuts" that *I* can use to run Kubectl
export KUBECONFIG=${PWD}/${CLUSTER_NAME}/${CLUSTER_NAME}-eks-a-cluster.kubeconfig
export KUBECONFIG=$(find ~/DevOps/eksa -name '*kind.kubeconfig')
export KUBECONFIG=$(find ~/DevOps/eksa -name '*cluster.kubeconfig')

kubectl get nodes -A -o wide --show-labels
kubectl get nodes -A -o wide --show-labels=true
kubectl get hardware -n eksa-system --show-labels

## Cleanup
```
docker kill $(docker ps -a | awk '{ print $1 }' | grep -v CONTAINER)
docker rm $(docker ps -a | awk '{ print $1 }' | grep -v CONTAINER)
rm -rf kubernerdes-eksa eksa-cli-logs
```


# Watch the logs of the last command until you see...
#   "Creating new workload cluster", then...

# You will see 3 containers start and run (an ECR container, the KIND cluster, then "boots")
watch docker ps -a

# Go back to the window where the "watch" command was running and kill the watch.  Then run
docker logs -f <container id of "boots" container>
docker logs -f $(docker ps -a | grep boots | awk '{ print $1 }')

# You can then start powering on your NUC and boot from the network and watch the Docker logs

# Random "shortcuts" that *I* can use to run Kubectl
export KUBECONFIG=${PWD}/${CLUSTER_NAME}/${CLUSTER_NAME}-eks-a-cluster.kubeconfig
export KUBECONFIG=$(find ~/DevOps/eksa -name '*kind.kubeconfig')
export KUBECONFIG=$(find ~/DevOps/eksa -name '*cluster.kubeconfig')

kubectl get nodes -A -o wide --show-labels
kubectl get nodes -A -o wide --show-labels=true
kubectl get hardware -n eksa-system --show-labels

##
# Deploy a Test App (To test the new storage class)
##
kubectl create namespace openebstest
kubectl config set-context --current --namespace=openebstest
curl -o busybox_example_app_persisent_storage.yaml https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/busybox_example_app_persisent_storage.yaml
kubectl apply -f busybox_example_app_persisent_storage.yaml
# Watch the pods until the busybox pod is "Running", then exit
while sleep 1; do kubectl get pods -n openebstest | grep Running && break ; done

# Review hosts for new disk image file
HOSTS="eks-host01 eks-host02 eks-host03"
for HOST in $HOSTS
do
  echo ""
  ssh -i ~/.ssh/id_ecdsa-kubernerdes.lab ec2-user@$HOST "
    sudo iscsiadm -m session -o show
    find  /var/openebs/local -name 'volume-head*.img' -exec ls -lh {} \; "
done

# Clean up app
## ADD SECTION FOR REMOVING THE APP
kubectl delete namespace openebstest

# And check again for the storage block device images
for HOST in $HOSTS
do
  ssh -i ~/.ssh/id_ecdsa-kubernerdes.lab ec2-user@$HOST "
    sudo iscsiadm -m session -o show
    find  /var/openebs/local -name 'volume-head*.img' -exec ls -lh {} \; "
done



# Review hosts for new disk image file
HOSTS="eks-host01 eks-host02 eks-host03"
for HOST in $HOSTS
do
  echo ""
  ssh -i ~/.ssh/id_ecdsa-kubernerdes.lab ec2-user@$HOST "
    cat /etc/*release*
  "
done

