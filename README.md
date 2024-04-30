# AZ 801
This repo contains the scripts and deployment files I use to manage the lab environment for the content related to AZ-801:
[AZ-801 YouTube Playlist](https://youtube.com/playlist?list=PLf4LHvX8--d9OHjQOs5Mnk1nNE0BTD488&si=8rz_vlgdxWSazdRV)

## Contents

### Configuration Scripts
- **Active Directory** contains a script you can use to populate a blank AD domain. It creates OUs, Groups, Users and some default GPOs
- **Failover Clusters** contains a script to configure a server as a host for iSCSI drives and then a second that can be used on your nodes to connect to them
- **Management** contains a script to install a set of RSAT tools on the management server so it can be used to manage other lab elements

### Lab Setup
This directory contains files that can be used to deploy a lab environment in Azure. By default it includes an AD domain controller and a management server, it can be customized to modify the domain settings and to deploy multiple member servers.

This requires that you have deployed the [Microsoft AD Quickstart](https://learn.microsoft.com/en-us/samples/azure/azure-quickstart-templates/active-directory-new-domain/) template once, and then you can use that to create a template spec that this terraform deployment uses.

