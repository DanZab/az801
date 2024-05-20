# Scripts
Back to [Home Page](https://github.com/DanZab/az801)

Contains scripts that can be used to configure elements of the Lab Environment. The [Active Directory scripts](https://github.com/DanZab/az801/tree/main/Active%20Directory) are in their own folder because that content is referenced by the Terraform deployment in the [Lab Setup](https://github.com/DanZab/az801/tree/main/Lab%20Setup).

## General
### Mgmt-InstallRSAT.ps1
Used to install RSAT tools on the Management Server (MGMT-P1)

## Failover Clusters
### Clusters-iSCSISetup.ps1
This script is intended to be run from a server that is separate from the Cluster nodes (like the Management server). It creates vhdx drive files and then provisions them as iSCSI storage on the cluster nodes.

You should update the `$Domain` variable to match your AD domain name, and also the `$Servers` variable to include the name of your cluster nodes.

### Clusters-FSRole.ps1
This script installed the File Server role on a cluster. It also sets some parameters that were required to get the File Server role working in a cluster hosted on Azure.