
param storageName string

param location string
// resourceGroup().location
param skuName string = 'Standard_LRS'
var prefix='vinay'
resource stg 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${prefix}${storageName}'
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
}