provider "azurerm" {}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resourceG}"
  location = "${var.server[0]}"
}

resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "${var.vn[0]}"
  address_space       = ["${var.private_adress_vn[0]}"]
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "myterraformsubnet" {
  name                 = "${var.subvn[0]}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
  address_prefix       = "${var.private_adress_subvn[1]}"
  network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"
}

# Create public IPs 
resource "azurerm_public_ip" "myterraformpublicip" {
  name                = "${var.ips[0]}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"
  # domain_name_label = "${var.VM[0]}"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "${var.NSG[0]}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "HTTP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "${var.private_adress_subvn[1]}"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "${var.private_adress_subvn[1]}"
  }

  tags {
    environment = "dev"
  }
}

# Associate Network Security Rule to Subnet
resource "azurerm_subnet_network_security_group_association" "associate" {
  subnet_id                 = "${azurerm_subnet.myterraformsubnet.id}"
  network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
  name                = "${var.NIC[0]}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"
  ip_configuration {
    name                          = "${var.NIConfig[0]}"
    subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.PrivateIP[3] }"
    public_ip_address_id = "${azurerm_public_ip.myterraformpublicip.id}"
  }

  tags {
    environment = "dev"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.rg.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    environment = "dev"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
  name                = "${var.VM[0]}-admin"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
  vm_size               = "Standard_B1ms"

  storage_os_disk {
    name              = "${var.VM[0]}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.VM[0]}"
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
    name        = "${var.nametag[3]}"
  }


#   provisioner "remote-exec" { 
#     inline = ["echo 'Hello World'"]

#     connection {
#       type = "ssh"
#       host = "${azurerm_public_ip.myterraformpublicip.fqdn}"
#       user = "${var.useradmin}"
#       private_key = "${file("/home/lmartinon/.ssh/id_rsa")}"
#     }
#   }

#   provisioner "local-exec" {
#     command = "ansible-playbook apache-provisioner.yml"
#   }

}

# output "_instructions" {
#   value = "This output contains plain text. You can add variables too."
# }

# output "public_dns" {
#   value = "${azurerm_public_ip.myterraformpublicip.fqdn}"
# }

# output "App_Server_URL" {
#   value = "http://${azurerm_public_ip.myterraformpublicip.fqdn}"
# }
