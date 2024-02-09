terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.91.0"
    }
  }
}



# Define provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "westus"
}

# Create a virtual network
resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Create subnets
resource "azurerm_subnet" "example" {
  count                     = 3
  name                      = "subnet-${count.index}"
  resource_group_name       = azurerm_resource_group.example.name
  virtual_network_name      = azurerm_virtual_network.example.name
  address_prefixes          = ["10.0.${count.index}.0/24"]

 

}


# Create NSG
resource "azurerm_network_security_group" "example" {
  count = 3
  name                = "example-${count.index}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Create NSG rules (SSH)
resource "azurerm_network_security_rule" "ssh" {
  count                      = 3
  name                       = "SSH-${count.index}"
  priority                   = 100 + count.index
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name        = azurerm_resource_group.example.name
  network_security_group_name = "example-${count.index}"
}

# Create public IPs
resource "azurerm_public_ip" "example" {
  count                       = 3
  name                        = "example-pip-${count.index}"
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  allocation_method           = "Static"
}

# Create NICs
resource "azurerm_network_interface" "example" {
  count               = 3
  name                = "example-nic-${count.index}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example[count.index].id
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-subnet" {
  count = 3
  subnet_id = azurerm_subnet.example[count.index].id
network_security_group_id =azurerm_network_security_group.example[count.index].id

}

# Create VMs
resource "azurerm_linux_virtual_machine" "example" {
  count                         = 3
  name                          = "example-vm-${count.index}"
  location                      = azurerm_resource_group.example.location
  resource_group_name           = azurerm_resource_group.example.name
  size                          = "Standard_DS1_v2"
  admin_username                = "adminuser"
  network_interface_ids         = [azurerm_network_interface.example[count.index].id]
  admin_ssh_key {
    username                    = "adminuser"
    public_key                  = file("~/.ssh/id_rsa.pub") # Provide the path to your SSH public key
  }
  os_disk {
    caching                     = "ReadWrite"
    storage_account_type        = "Standard_LRS"
  }
  source_image_reference {
    publisher                   = "Canonical"
    offer                       = "UbuntuServer"
    sku                         = "18.04-LTS"
    version                     = "latest"
  }
}

