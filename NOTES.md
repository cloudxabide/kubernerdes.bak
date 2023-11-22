# Notes




## File relationships
Notice that the definition you put in your hardware config, must match the update you add to your ClusterConfig

Hardware Inventory
eks-host01,1c:69:7a:ab:23:50,10.10.12.11,255.255.252.0,10.10.12.1,10.10.12.10|8.8.8.8|8.8.4.4,node=cp-machine,/dev/nvme0n1

Cluster Config
spec:
  hardwareSelector: { node: "cp-machine" }

