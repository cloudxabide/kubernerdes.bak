# README - Scripts directory

Status:  I am currently rearranging my "Scripts" directory to be more cluster-specifc, or cluster-type-specific.  (i.e. vSphere will have it's own section, vs bare-metal)

The plan:  
* put ALL the scripts in <base>/Scripts
* create a cluster-type-specific directory (in this case based on CLUSTER_NAME)
* create symlinks from CLUSTER_NAME -> ../50_Deploy_EKSA.sh


The intent of this directory ~/Scripts is files that can be run non-interactively, broken down by "area of concern".
Non-interactive files will go in ~/Foo

Note:  Anything in my "scripts" that is encapsulated in a bash routine - ie. my_route(){ code; } generally means it is some optional code that I won't generally
 use. (like installing the Desktop UI)

Eventually, I would like to be able to simply run the following to build my environment
```
for SCRIPT in $(ls [0-9]*.sh | sort); do sh ./$SCRIPT; done
```

<pre>
I *think* I want my folder structue on my Admin Host to be...
  ~/ 
   /eksa/
        /$CLUSTER_NAME(management-cluster)/*artifacts*
        /$CLUSTER_NAME(workload-cluster01)/*artifacts*
        /$CLUSTER_NAME(workload-cluster02)/*artifacts*
        /.archive/`date +%F`//management-cluster/
        /.archive/`date +%F`/workload-cluster/
</pre>

<pre>
eksa
├── dummy-vsphere-cluster
│   ├── eksa-cli-logs
│   └── eksa-mgmt-cluster.yaml
├── kubernerdes-eksa
│   ├── 2024-03-20
│   ├── 2024-03-20-01
│   ├── 2024-04-21
│   └── latest -> /home/mansible/eksa/kubernerdes-eksa/2024-04-21
└── vsphere-eksa
    ├── 2024-03-26
    ├── 2024-03-26-01
    ├── 2024-04-10
    ├── 2024-04-10-01
    ├── 2024-04-12
    ├── 2024-04-22
    └── latest -> /home/mansible/eksa/vsphere-eksa/2024-04-22
</pre>
