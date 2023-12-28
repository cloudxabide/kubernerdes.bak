## Label Nodes
```
mansible@thekubernerd:~/DevOps/eksa$ kubectl get nodes
NAME         STATUS   ROLES           AGE   VERSION
eks-host01   Ready    control-plane   20m   v1.28.4-eks-d91a302
eks-host02   Ready    <none>          17m   v1.28.4-eks-d91a302
eks-host03   Ready    <none>          16m   v1.28.4-eks-d91a302
mansible@thekubernerd:~/DevOps/eksa$ for NODE in $(kubectl get nodes -A -o wide | grep -v control-plane | grep "<none>" | awk '{ print $1 }'); do kubectl label node $NODE node-role.kubernetes.io/worker=worker ; done
node/eks-host02 labeled
node/eks-host03 labeled
mansible@thekubernerd:~/DevOps/eksa$ kubectl get nodes
NAME         STATUS   ROLES           AGE   VERSION
eks-host01   Ready    control-plane   21m   v1.28.4-eks-d91a302
eks-host02   Ready    worker          18m   v1.28.4-eks-d91a302
eks-host03   Ready    worker          17m   v1.28.4-eks-d91a302
```

## Output from Creating a Cluster

I'll add some verbiage to this doc later explaining some of the milestones here

```
eksctl anywhere create cluster \
   --hardware-csv hardware.csv \
   -f $CLUSTER_CONFIG
Warning: The recommended number of control plane nodes is 3 or 5
Warning: The recommended number of control plane nodes is 3 or 5
Performing setup and validations
✅ Tinkerbell Provider setup is valid
✅ Validate OS is compatible with registry mirror configuration
✅ Validate certificate for registry mirror
✅ Validate authentication for git provider
✅ Validate cluster's eksaVersion matches EKS-A version
Creating new bootstrap cluster
Provider specific pre-capi-install-setup on bootstrap cluster
Installing cluster-api providers on bootstrap cluster
Provider specific post-setup
Creating new workload cluster
Installing networking on workload cluster
Creating EKS-A namespace
Installing cluster-api providers on workload cluster
Installing EKS-A secrets on workload cluster
Installing resources on management cluster
Moving cluster management from bootstrap to workload cluster
Installing EKS-A custom components (CRD and controller) on workload cluster
Installing EKS-D components on workload cluster
Creating EKS-A CRDs instances on workload cluster
Installing GitOps Toolkit on workload cluster
GitOps field not specified, bootstrap flux skipped
Writing cluster config file
Deleting bootstrap cluster
🎉 Cluster created!
--------------------------------------------------------------------------------------
The Amazon EKS Anywhere Curated Packages are only available to customers with the
Amazon EKS Anywhere Enterprise Subscription
--------------------------------------------------------------------------------------
Enabling curated packages on the cluster
Installing helm chart on cluster	{"chart": "eks-anywhere-packages", "version": "0.3.13-eks-a-54"}
```
