[![Build status](https://ci.appveyor.com/api/projects/status/5gwuykr48m4qionk/branch/master?svg=true)](https://ci.appveyor.com/project/R41z0r/woocommerce-module/branch/master)
# Woocommerce_Module
Manage your WordPress WooCommerce Shop through the Restful API
 
# Requirements
At a minimum, make sure you have installed the following:
- Windows Powershell 3+

WooCommerce Requirements [ApiReference]:

| API Version | WC Version | WP Version |
| ------ | ------ | ------ |
| 3 | 3.0.x or later | 4.4 or later 


# Installation & Execution
Option 1: PowerShellGallery
Module can be installed from the PowerShellGalley (requires PowerShell 5+)
`Install-Module -Name WooCommerce`

Option 2: Manual
1. Download the latest version to your desktop
2. Open a PowerShell console
3. Run `Set-ExecutionPolicy` using the parameter `RemoteSigned` or `Bypass`.
4. Import the Module

# Usage Instructions
1. You have to create a special API key/secret at your WooCommerce Shop - Manual [WooCommerceApiKey] 
2. For any Cmdlet you have to call `Set-WooCommerceCredential` in first (Cmdlets throws helpful exception if not)
2.1 This Command lets you provite your website, api-key and api-secret and checks if they are correct
3. Now you can use all other commands

Order 
`Get-WooCommerceOrder`
- You can provide a specific id or the switch `-all` to show all your orders

Product
`New-WooCommerceProduct`
- Creates a new product in your shop based on the parameters provided

# Future

Cmdlets for managing:
- variable product
- shipping zones
- payment gateways
- webhooks
- settings
- reports
- taxes
- refunds
- customers
- coupons

# Issues
Knowing none

[WooCommerceApiKey]: <https://docs.woocommerce.com/document/woocommerce-rest-api/>
[ApiReference]: <http://woocommerce.github.io/woocommerce-rest-api-docs/#introduction>