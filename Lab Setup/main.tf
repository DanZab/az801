
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
  dsc_content_location = "https://raw.githubusercontent.com/DanZab/232-public/master/azuredeploy.json"
  domain_name          = "domain.local"
  domain_dn            = "DC=domain,DC=local" # Used in server deployments extension
  dns_prefix           = "domainlocal"
  DC_name              = "AD-P1" # The name of the Domain Controller for AD
  DC_ipaddress         = "10.0.0.4"
  DC_vm_size           = "Standard_B2s"
  admin_username       = "AdminUser"
  admin_password       = "P@$$word1"
  vnet_name            = "vnet-lab"
  vnet_range           = "10.0.0.0/16"
  snet_name            = "snet-ad"
  snet_range           = "10.0.0.0/24"

  # Windows Server 2019 Datacenter
  # Windows Server 2022 Datacenter: Azure Edition
  servers = {
    MGMT-P1 = {
      size       = "Standard_B2s"
      subnet_id  = azurerm_subnet.servers.id
      image_plan = "2022-datacenter-g2"
      data_disks = [
        {
          name                 = "mgmt-p1-disk1"
          storage_account_type = "Standard_LRS"
          create_option        = "Empty"
          attach_setting = {
            lun     = 1
            caching = "ReadWrite"
          }
          disk_size_gb = 40
        }
      ]
      private_ip = "10.0.1.4"
      public_ip  = azurerm_public_ip.public.id
      server_ou  = "OU=Servers,${local.domain_dn}"
    }#,
    # BACK-P1 = { # Uncomment to create a second VM named "BACK-P1"
    #   size       = "Standard_B2s"
    #   subnet_id  = azurerm_subnet.servers.id
    #   image_plan = "2022-datacenter-g2"
    #   data_disks = []
    #   private_ip = "10.0.1.10"
    #   public_ip  = null
    #   server_ou  = "OU=Servers,${local.domain_dn}"
    # }
  }

  public_ip = "${chomp(var.public_ip)}/32"
}

variable "public_ip" {
  type        = string
  description = "The Public IP to be configured for the NSG."
}

# You can update the Terraform to use this data call for the NSG rule instead
# this would automatically allow RDP from wherever you are running the 
# terraform deployment
#
# data "http" "myip" {
#   url = "https://ipv4.icanhazip.com"
# }

# If you want to create a VM in the same subnet as AD you can use this data call
# to reference the subnet id:
# data.azurerm_subnet.template.id
data "azurerm_subnet" "template" {
  depends_on = [resource.azurerm_resource_group_template_deployment.domain]

  name                 = local.snet_name
  virtual_network_name = local.vnet_name
  resource_group_name  = local.resource_group_name
}

data "azurerm_template_spec_version" "domain" {
  name                = "domain-template"
  resource_group_name = local.resource_group_name
  version             = "v1.0.0"
}

resource "azurerm_resource_group_template_deployment" "domain" {
  name                     = "deploy-domain"
  resource_group_name      = local.resource_group_name
  deployment_mode          = "Incremental"
  template_spec_version_id = data.azurerm_template_spec_version.domain.id

  parameters_content = jsonencode({
    _artifactsLocation         = { value = local.dsc_content_location }
    _artifactsLocationSasToken = {}
    adminPassword              = { value = local.admin_password }
    adminUsername              = { value = local.admin_username }
    dnsPrefix                  = { value = local.dns_prefix }
    domainName                 = { value = local.domain_name }
    location                   = { value = local.location }
    networkInterfaceName       = { value = "${local.DC_name}-nic" }
    privateIPAddress           = { value = local.DC_ipaddress }
    subnetName                 = { value = local.snet_name }
    subnetRange                = { value = local.snet_range }
    virtualMachineName         = { value = local.DC_name }
    virtualNetworkAddressRange = { value = local.vnet_range }
    virtualNetworkName         = { value = local.vnet_name }
    vmSize                     = { value = local.DC_vm_size }
  })

  timeouts {
    create = "40m"
    delete = "10m"
  }

  lifecycle {
    ignore_changes = [parameters_content]
  }
}

resource "azurerm_subnet" "servers" {
  name                 = "snet-servers"
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.vnet_name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [resource.azurerm_resource_group_template_deployment.domain]
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

resource "azurerm_network_interface_security_group_association" "rdp_nsg" {
  network_interface_id      = module.servers["MGMT-P1"].network_interface_id
  network_security_group_id = azurerm_network_security_group.rdp.id
}

module "servers" {
  depends_on = [resource.azurerm_resource_group_template_deployment.domain]

  source   = "Azure/virtual-machine/azurerm"
  version  = "1.1.0"
  for_each = local.servers

  location            = local.location
  resource_group_name = local.resource_group_name

  name           = each.key
  image_os       = "windows"
  size           = each.value.size
  subnet_id      = each.value.subnet_id
  admin_username = "azureuser"
  admin_password = "P@$$word1"

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = each.value.image_plan
    version   = "latest"
  }

  data_disks = each.value.data_disks

  new_boot_diagnostics_storage_account = {
    name = "boot${lower(replace(each.key, "-", ""))}"
  }

  new_network_interface = {
    name = "${lower(each.key)}-nic"
    ip_configurations = [
      {
        private_ip_address_allocation = "Static"
        private_ip_address            = each.value.private_ip
        public_ip_address_id          = each.value.public_ip
      }
    ]
    dns_servers = [
      local.DC_ipaddress,
      "8.8.8.8"
    ]
  }

  allow_extension_operations = true
  extensions = [
    {

      name                       = "join-domain"
      publisher                  = "Microsoft.Compute"
      type                       = "JsonADDomainExtension"
      type_handler_version       = "1.3"
      auto_upgrade_minor_version = true

      settings = <<SETTINGS
        {
            "Name": "${local.domain_name}",
            "User": "DZAB\\${local.admin_password}",
            "OUPath": "${each.value.server_ou}",
            "Restart": "true",
            "Options": "3"
        }
SETTINGS

      protected_settings = <<PROTECTED_SETTINGS
        {
            "Password": "${local.admin_password}"
        }
PROTECTED_SETTINGS

    }
  ]
}

data "azurerm_public_ip" "pip" {
  name                = azurerm_public_ip.public.name
  resource_group_name = local.resource_group_name

  depends_on = [module.servers]
}

output "rdp_pip" {
  value = data.azurerm_public_ip.pip.ip_address
}

