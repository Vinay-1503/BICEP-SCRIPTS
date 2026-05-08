@description('Name of the Azure Web App')
param appName string

@description('Location for the resources')
param location string = 'East US'

@description('Name of the App Service Plan')
param appServicePlanName string = '${appName}-plan'

@description('SKU for the App Service Plan')
param sku string = 'B1'

@description('Runtime stack for the Web App')
param runtimeStack string = 'DOTNETCORE|8.0'

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku
  }
  properties: {}
}

// Web App
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      windowsFxVersion: runtimeStack
    }
  }
}
