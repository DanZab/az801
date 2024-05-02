# If you want to create a VM in the same subnet as AD you can use this data call
# to reference the subnet id:
# data.azurerm_subnet.template.id
data "azurerm_subnet" "template" {
  depends_on = [resource.azurerm_resource_group_template_deployment.domain]

  name                 = local.snet_name
  virtual_network_name = local.vnet_name
  resource_group_name  = local.resource_group_name
}

# data "azurerm_template_spec_version" "domain" {
#   name                = local.template_name
#   resource_group_name = local.resource_group_name
#   version             = local.template_version
# }

resource "azurerm_resource_group_template_deployment" "domain" {
  name                     = "deploy-domain"
  resource_group_name      = local.resource_group_name
  deployment_mode          = "Incremental"

  parameters_content = jsonencode({
    _artifactsLocation         = { value = local.dsc_content_location }
    _artifactsLocationSasToken = {}
    adminPassword              = { value = local.admin_password }
    adminUsername              = { value = local.admin_username }
    domainName                 = { value = local.domain_name }
    domainDN                   = { value = local.domain_dn }
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

  template_content = file("./deploy/azuredeploy.json")

  timeouts {
    create = "40m"
    delete = "10m"
  }

  lifecycle {
    ignore_changes = [parameters_content]
  }
}
# resource "azurerm_resource_group_template_deployment" "domain" {
#   name                     = "deploy-domain"
#   resource_group_name      = local.resource_group_name
#   deployment_mode          = "Incremental"
#   template_spec_version_id = data.azurerm_template_spec_version.domain.id

#   parameters_content = jsonencode({
#     _artifactsLocation         = { value = local.dsc_content_location }
#     _artifactsLocationSasToken = {}
#     adminPassword              = { value = local.admin_password }
#     adminUsername              = { value = local.admin_username }
#     dnsPrefix                  = { value = local.dns_prefix }
#     domainName                 = { value = local.domain_name }
#     domainDN                   = { value = local.domain_dn }
#     location                   = { value = local.location }
#     networkInterfaceName       = { value = "${local.DC_name}-nic" }
#     privateIPAddress           = { value = local.DC_ipaddress }
#     subnetName                 = { value = local.snet_name }
#     subnetRange                = { value = local.snet_range }
#     virtualMachineName         = { value = local.DC_name }
#     virtualNetworkAddressRange = { value = local.vnet_range }
#     virtualNetworkName         = { value = local.vnet_name }
#     vmSize                     = { value = local.DC_vm_size }
#   })

#   timeouts {
#     create = "40m"
#     delete = "10m"
#   }

#   lifecycle {
#     ignore_changes = [parameters_content]
#   }
# }