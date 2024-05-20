# Guided Labs Section
Back to [Home Page](https://github.com/DanZab/az801)

This section contains walkthroughs that map AZ-801 exam objectives to steps that can be performed on Windows Server in the lab environment you can deploy.

You should be able to use the Lab Setup in this repo to configure your lab environment, instructions for doing so can be found in this video: [Instant Active Directory Lab in Azure: Step-by-Step (Part 2)](https://youtu.be/dlGQxzPiXsk)

The instructions for these Guided Labs are intended to be vague. You should attempt to figure out how to complete each step on your own which will help you to learn the content.

Each lab includes a description of the study guide content that is covered, as well as the recommended server configuration to deploy.

## Adding additional servers to your lab environment
It is assumed that you are deploying your lab using the [Lab Setup](https://github.com/DanZab/az801/tree/main/Lab%20Setup) in this repo, if any of the guided labs require additional servers, I'll add a server block you can copy/paste to configure the additional servers. 

This server block should be added to the `servers` variable in the `servers.tf` ([link](https://github.com/DanZab/az801/blob/main/Lab%20Setup/servers.tf)) file. The block would be added here:

``` terraform
locals {
  servers = {
    MGMT-P1 = { ... },
    NEW-SERVER = {} # < THIS IS WHERE YOU COPY/PASTE THE SERVER BLOCK, make sure you add a comma after the closing bracket of MGMT-P1
  }
}
```

## Secure Windows Server on-premises and hybrid infrastructures (25–30%)
- [Secure a hybrid Active Directory infrastructure](./secure-hybrid-ad/)
- [Secure Windows Server Operating System](./secure-windows-server/)
