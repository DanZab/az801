
locals {
  # You can add additional servers to the servers variable to deploy them
  # The FIRST server in servers{} will be your management server
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
}

# This creates a new subnet to put servers in
resource "azurerm_subnet" "servers" {
  name                 = "snet-servers"
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.vnet_name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [resource.azurerm_resource_group_template_deployment.domain]
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
            "User": "${local.domain_name}\\${local.admin_username}",
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

