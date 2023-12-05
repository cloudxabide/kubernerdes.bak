# My Kubernetes Lab - kubernerdes.lab 

This is the chronicles of deploying Kubernetes (EKS Anywhere) in my HomeLab: The Kubernerdes lab.

It is worth noting that a portion of this repo is likely not applicable in most situations.  I am essentially plumbing up a new interface on my Firewall, creating a new /22 CIDR off that interface, and starting from scratch - things you would not (or could not) need to do if you were in an enterprise situation.

Goal:  to create my own EKS Anywhere environment from bare metal (Intel NUCs) starting with a USB stick with install media (Ubuntu Server 22.04 - though I am considering Ubuntu Desktop now that I have been "in the ecosystem" for a while) and an Internet connection.  I want this environment to be completely independent of everything else in my lab. 

![Kubernerdes Lab](Images/KubernerdesLab.png)

## Build THEKUBERNERD Host
You will need to install Ubuntu on "TheKubernerd" (the "Admin Host" referenced in the docs).  While I have ways of accomplishing this with automation, *that* is not in-scope to explain here.

[Post Install Script - THEKUBERNERD](Scripts/00_Post_Install_THEKUBERNERD.sh)

The EKS Anywhere build process will create all the PXE bits, etc..  EKS Anywhere is incredible.  
It will deploy a KIND Cluster using Docker to build a "bootstrap Cluster" - this will include all the necessary plumbing, etc.. to bootstrap the base OS on the Cluster Nodes.

The only "customization" I am going to pursue is hosting the OS Image and Hooks on my own webeserver, and my own DNS server for my Lab.    
* [Ansible](Scripts/10_Install_Ansible.sh)
* [EKS Tools](Scripts/11_Install_EKS_Tools.sh)
* [BIND](Scripts/15_Install_BIND9.sh)

Uneeded (this is all handled by the "tinkerbell boots" container:  
* [WWW](Scripts/Install_HTTP_Server.sh)
* [DHCP Server](Scripts/Install_DHCP_Server.sh)
* TFTP

## Deploy EKS Anywhere Cluster
ProTip:  If you have only "node=cp-machine" in your hardware, and remove the WorkerNodeGroup from your hardware.csv, your CP nodes will not be tainted and workloads can run there.  (so, either you have 3 x CP that are also Worker Nodes - or you have 1 x CP and 2 x Worker Nodes)  
[Install EKS Anywhere](Scripts/50_Install_EKS_Anywhere.sh)

## References
[EKS Anywhere - Landing Page](https://anywhere.eks.amazonaws.com/)  
[EKS Anywhere - Docs](https://anywhere.eks.amazonaws.com/docs/)  
[Ubuntu Server - Download](https://ubuntu.com/download/server)  

[Containers from the Couch - Search: EKS Anywhere (YouTube)](https://www.youtube.com/@ContainersfromtheCouch/search?query=eks%20anywhere)

