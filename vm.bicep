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

@description('Create new VNet?')
param createVnet bool = true

@description('Address Prefix')
param addressPrefix string = '10.0.0.0/16'

@description('Subnet Prefix')
param subnetPrefix string = '10.0.0.0/24'

@description('Enable NSG')
param enableNSG bool = true

@description('Ports to open')
param openPorts array = [
  22
]

@description('Zone')
param zone string = '2'


// ------------------ Public IP ------------------
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


// ------------------ VNet (Optional Create) ------------------
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = if (createVnet) {
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


// ------------------ Existing VNet ------------------
resource existingVnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = if (!createVnet) {
  name: vnetName
}


// ------------------ Subnet ------------------
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = if (createVnet) {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: subnetPrefix
  }
}


// ------------------ Existing Subnet ------------------
resource existingSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = if (!createVnet) {
  name: subnetName
  parent: existingVnet
}


// ------------------ NSG ------------------
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = if (enableNSG) {
  name: '${vmName}-nsg'
  location: location
  properties: {
    securityRules: [
      for (port, i) in openPorts: {
        name: 'Allow-${port}'
        properties: {
          priority: 1000 + i
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: string(port)
        }
      }
    ]
  }
}


// ------------------ NIC ------------------
resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    networkSecurityGroup: enableNSG ? {
      id: nsg.id
    } : null

    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: createVnet ? subnet.id : existingSubnet.id
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}


// ------------------ VM ------------------
resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  zones: [
    zone
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
