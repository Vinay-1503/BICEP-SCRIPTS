@description('Location for all resources')
param location string

@description('VM Name')
param vmName string

@description('Admin Username')
param adminUsername string = 'azureuser'

@description('SSH Public Key')
param sshPublicKey string

@description('VM Size')
param vmSize string

@description('VNet Name')
param vnetName string

@description('Subnet Name')
param subnetName string

@description('Address Prefix')
param addressPrefix string

@description('Subnet Prefix')
param subnetPrefix string

// Public IP
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${vmName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// VNet
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
  }
}

// Subnet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: subnetPrefix
  }
}

// NIC
resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}

// VM
resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  zones: [
    '2'
  ]

  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }

    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }

      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        diskSizeGB: 30
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }

    osProfile: {
      computerName: vmName
      adminUsername: adminUsername

      linuxConfiguration: {
        disablePasswordAuthentication: true

        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }

    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }

    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}
