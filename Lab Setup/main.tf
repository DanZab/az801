
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true

  subscription_id = "YOUR_SUB_ID"
  features {}
}

locals {
  # SET YOUR LAB ENVIRONMENT DETAILS HERE
  location             = "eastus"
  resource_group_name  = "YOUR_LAB_RG_NAME"
  dsc_content_location = "https://raw.githubusercontent.com/DanZab/az801/main/Lab%20Setup/deploy/azuredeploy.json"
  domain_name          = "domain.local"
  domain_dn            = "DC=domain,DC=local" # Used in server deployments extension
  DC_name              = "AD-P1" # The name of the Domain Controller for AD
  DC_ipaddress         = "10.0.0.4"
  DC_vm_size           = "Standard_B2s"
  admin_username       = "AdminUser"
  admin_password       = "P@$$word1"
  vnet_name            = "vnet-lab"
  vnet_range           = "10.0.0.0/16"
  snet_name            = "snet-ad"
  snet_range           = "10.0.0.0/24"
  # template_name        = "deploy-template"
  # template_version     = "v1.0.0"

  public_ip = "${chomp(data.http.myip.response_body)}/32"
  #public_ip = "${chomp(var.public_ip)}/32"
}

# The next four resources are used to connect to your lab environment. They
# contain the following:
# - A block that gets your current IP address (can be replaced with a variable)
# - A public IP to connect to

# - An NSG to restrict access
# - A rule for the NSG which only allows access from your current IP address


# variable "public_ip" {
#   type        = string
#   description = "The Public IP to be configured for the NSG."
# }

data "http" "myip" {
   url = "https://ipv4.icanhazip.com"
}

resource "azurerm_public_ip" "public" {
  name                = "pip-connect"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "rdp" {
  name                = "nsg-allow-rdp"
  resource_group_name = local.resource_group_name
  location            = local.location

  depends_on = [resource.azurerm_resource_group_template_deployment.domain]
}

resource "azurerm_network_security_rule" "from_source" {
  name                        = "allow-rdp-source"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = local.public_ip
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "3389"
  resource_group_name         = local.resource_group_name
  network_security_group_name = azurerm_network_security_group.rdp.name
}

# This links the NSG to the first server in your local.servers variable
resource "azurerm_network_interface_security_group_association" "rdp_nsg" {
  network_interface_id      = module.servers["${keys(local.servers)[0]}"].network_interface_id
  network_security_group_id = azurerm_network_security_group.rdp.id
}