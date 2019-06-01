resource "azurerm_subnet" "myterraformsubnet2" {
  name                 = "${var.subvn[1]}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
  address_prefix       = "${var.private_adress_subvn[0]}"
  network_security_group_id = "${azurerm_network_security_group.myterraformnsg2.id}"
}

# Create public IPs 
# resource "azurerm_public_ip" "myterraformpublicip" {
#   name                = "${var.ips[0]}"
#   location            = "${azurerm_resource_group.rg.location}"
#   resource_group_name = "${azurerm_resource_group.rg.name}"
#   allocation_method   = "Static"
#   # domain_name_label = "${var.VM[0]}"
# }

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg2" {
  name                = "${var.NSG[1]}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "HTTP2"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "${var.private_adress_subvn[1]}"
    destination_address_prefix = "${var.private_adress_subvn[0]}"
  }
    security_rule {
    name                       = "HTTP3"
    priority                   = 1101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "${var.private_adress_subvn[0]}"
    destination_address_prefix = "*"
  }

      security_rule {
    name                       = "HTTP4"
    priority                   = 1102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8081"
    source_address_prefix      = "*"
    destination_address_prefix = "${var.private_adress_subvn[0]}"
  }

        security_rule {
    name                       = "HTTP5"
    priority                   = 1103
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "8081"
    destination_port_range     = "*"
    source_address_prefix      = "${var.private_adress_subvn[0]}"
    destination_address_prefix = "*"
  }


  security_rule {
    name                       = "SSH"
    priority                   = 1110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "${var.private_adress_subvn[0]}"
  }

    security_rule {
    name                       = "HTTP-o"
    priority                   = 1120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "${var.private_adress_subvn[0]}"
    destination_address_prefix = "*"
  }

  tags {
    environment = "dev"
  }
}

# Associate Network Security Rule to Subnet
resource "azurerm_subnet_network_security_group_association" "associate2" {
  subnet_id                 = "${azurerm_subnet.myterraformsubnet2.id}"
  network_security_group_id = "${azurerm_network_security_group.myterraformnsg2.id}"
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic2" {
  name                = "${var.NIC[1]}-${count.index}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.myterraformnsg2.id}"
  count               = 3
  ip_configuration {
    name                          = "${var.NIConfig[1]}-${count.index}"
    subnet_id                     = "${azurerm_subnet.myterraformsubnet2.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.PrivateIP["${count.index}"] }"
  }

  tags {
    environment = "dev"
  }
}

# # Generate random text for a unique storage account name
# resource "random_id" "randomId" {
#   keepers = {
#     # Generate a new ID only when a new resource group is defined
#     resource_group = "${azurerm_resource_group.rg.name}"
#   }

#   byte_length = 8
# }

# Create storage account for boot diagnostics
# resource "azurerm_storage_account" "mystorageaccount" {
#   name                     = "diag${random_id.randomId.hex}"
#   resource_group_name      = "${azurerm_resource_group.rg.name}"
#   location                 = "${azurerm_resource_group.rg.location}"
#   account_tier             = "Standard"
#   account_replication_type = "LRS"

#   tags {
#     environment = "dev"
#   }
# }

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm2" {
  name                = "${var.VM[1]}-${count.index}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${element(azurerm_network_interface.myterraformnic2.*.id, count.index)}"]
  vm_size               = "Standard_B1ms"
  count = 3

  storage_os_disk {
    name              = "${var.VM[1]}-osdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.VM[1]}-${count.index}"
    admin_username = "${var.useradmin}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
        path     = "/home/${var.useradmin}/.ssh/authorized_keys"
        key_data = "${var.sshkey}"
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
  }

  tags {
    environment = "dev"
    name        = "${var.nametag["${count.index}"]}"
  }
}