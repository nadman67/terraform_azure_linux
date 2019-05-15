provider "azurerm" {
}
resource "azurerm_resource_group" "linuxterraformgroup" {
        name = "linuxResourceGroup"
        location = "eastus"
}
resource "azurerm_virtual_network" "linuxterraformnetwork" {
    name                = "linuxVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.linuxterraformgroup.name}"

    tags {
        environment = "Terraform Demo"
    }
}
resource "azurerm_subnet" "linuxterraformsubnet" {
    name                 = "linuxSubnet"
    resource_group_name  = "${azurerm_resource_group.linuxterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.linuxterraformnetwork.name}"
    address_prefix       = "10.0.2.0/24"
}
resource "azurerm_public_ip" "linuxterraformpublicip" {
    name                         = "linuxPublicIP"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.linuxterraformgroup.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "Terraform Demo"
    }
}
resource "azurerm_network_security_group" "linuxterraformnsg" {
    name                = "linuxNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.linuxterraformgroup.name}"
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
     security_rule {
        name                       = "RDP"
        priority                   = 999
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
         security_rule {
        name                       = "HTTP"
        priority                   = 300
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
         security_rule {
        name                       = "HTTPS"
        priority                   = 320
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
	security_rule {
        name                       = "Healthshare"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "57772"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    


    tags {
        environment = "Terraform Demo"
    }
}
resource "azurerm_network_interface" "linuxterraformnic" {
    name                = "linuxNIC"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.linuxterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.linuxterraformnsg.id}"

    ip_configuration {
        name                          = "linuxNicConfiguration"
        subnet_id                     = "${azurerm_subnet.linuxterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.linuxterraformpublicip.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.linuxterraformgroup.name}"
    }
    
    byte_length = 8
}
resource "azurerm_storage_account" "linuxstorageaccount" {
    name                = "diag${random_id.randomId.hex}"
    resource_group_name = "${azurerm_resource_group.linuxterraformgroup.name}"
    location            = "eastus"
    account_replication_type = "LRS"
    account_tier = "Standard"

    tags {
        environment = "Terraform Demo"
    }
}
resource "azurerm_virtual_machine" "linuxterraformvm" {
    name                  = "linuxVM"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.linuxterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.linuxterraformnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "linuxOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "RedHat"
        offer     = "RHEL"
        sku       = "7-RAW"
        version   = "latest"
    }

    os_profile {
        computer_name  = "linuxvm"
        admin_username = "j2user"
        admin_password ="j2andUtoo"    
    }   
    
    os_profile_linux_config {
        disable_password_authentication = "false"
    }
    
    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.linuxstorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Terraform Demo"
    }
}
resource "azurerm_virtual_machine_extension" "postinstall" {
    name            = "extension"
    location        = "eastus"
    resource_group_name = "${azurerm_resource_group.linuxterraformgroup.name}"
    virtual_machine_name = "${azurerm_virtual_machine.linuxterraformvm.name}"
    publisher           = "Microsoft.OSTCExtensions"
    type                = "CustomScriptForLinux"
    type_handler_version    = "1.2"

    settings = <<SETTINGS
    {
        "fileUris" : [
            "https://postdeploystorage.blob.core.windows.net/scripts/HSlinuxinstall.bash"
        ],
        "commandToExecute": "./HSlinuxinstall.bash"        
    }
    SETTINGS
    
}
