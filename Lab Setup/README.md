# Deploying Active Directory Environment
See the following video for instructions on how to deploy the lab environment: [Instant Active Directory Lab in Azure: Step-by-Step (Part 2)](https://youtu.be/dlGQxzPiXsk)

### Prerequisites
- You must have Terraform Installed - [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- You must have Git Installed - [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- You must have an Azure subscription

### Deployment Steps
1. Sync/Clone this Repo Locally
2. Set/Update the variables in the `main.tf` file in this directory
3. (Optional) Add additional servers to the `servers` variable in the `servers.tf` file
4. [Authenticate Terraform to Azure](https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure?tabs=bash)
5. From the "Lab Setup" directory deploy the resources using Terraform via cli:
    1. `terraform init`
    2. `terraform plan`
    3. `terraform apply`
6. (Optional) Use the [Guided Labs](https://github.com/DanZab/az801/tree/main/Guided%20Labs) to study for AZ-801 objectives.
7. When finished studying, use `terraform destroy` to delete the Azure resources so you aren't charged when not using them.