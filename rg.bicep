targetScope = 'subscription'

@description('Name of the Resource Group')
param rgName string

@description('Location of the Resource Group')
param location string

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: location
}
