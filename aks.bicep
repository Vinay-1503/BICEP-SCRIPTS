@description('AKS Cluster Name')
param aksName string

@description('Location')
param location string = resourceGroup().location

@description('Node Count')
param nodeCount int = 1

resource aks 'Microsoft.ContainerService/managedClusters@2023-08-01' = {
  name: aksName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: aksName

    agentPoolProfiles: [
      {
        name: 'nodepool1'
        count: nodeCount
        vmSize: 'Standard_B2s'
        osType: 'Linux'
        mode: 'System'
      }
    ]

    linuxProfile: {
      adminUsername: 'azureuser'
      ssh: {
        publicKeys: [
          {
            keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC...' // replace
          }
        ]
      }
    }

    enableRBAC: true

    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
    }
  }
}