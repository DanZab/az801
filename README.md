# AZ 801
This repo contains the scripts and deployment files I use to manage the lab environment for the content related to AZ-801:
[AZ-801 YouTube Playlist](https://youtube.com/playlist?list=PLf4LHvX8--d9OHjQOs5Mnk1nNE0BTD488&si=8rz_vlgdxWSazdRV)

## Contents

### Guided Labs
The [Guided Labs](https://github.com/DanZab/az801/tree/main/Guided%20Labs) page is in progress, but contains some walkthroughs you can use as you're studying for the AZ-801 to teach yourself the exam objectives.


### Lab Setup
The [Lab Setup](https://github.com/DanZab/az801/tree/main/Lab%20Setup) section contains content you can use to quickly deploy an Active Directory lab environment in your Azure tenant using Terraform. Video walkthroughs about how to deploy the environment can be found here: [Instant Active Directory Lab in Azure: Step-by-Step (Part 2)](https://youtu.be/dlGQxzPiXsk).

This deploys the following environment by default:

![AD Lab Environment](diagram.png)

### Active Directory
This directory contains files that are referenced by DSC to configure the domain if you are using the Lab Setup. It also contains a script that can be customized to configure a blank AD domain if you are using the Microsoft Quickstart template: [Create an Azure VM with a new AD Forest - Code Samples | Microsoft Learn](https://learn.microsoft.com/en-us/samples/azure/azure-quickstart-templates/active-directory-new-domain/)

### Scripts
The [Scripts](https://github.com/DanZab/az801/tree/main/Scripts) directory contains some individual powershell scripts that may be needed for some of the [Guided Labs](https://github.com/DanZab/az801/tree/main/Guided%20Labs).


