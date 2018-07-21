<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	27.12.2017 08:40
	 Created by:   	R41Z0R
	 Organization: 	
	 Filename:     	Woocommerce.psm1
	-------------------------------------------------------------------------
	 Module Name: Woocommerce
	===========================================================================
#>

$filterParameter = @(
	"Verbose",
	"Debug",
	"ErrorAction",
	"WarningAction",
	"InformationAction",
	"ErrorVariable",
	"WarningVariable",
	"InformationVariable",
	"OutVariable",
	"OutBuffer",
	"PipelineVariable",
	"WhatIf",
	"Confirm"
)

$script:woocommerceProducts = "wp-json/wc/v2/products"
$script:woocommerceOrder = "wp-json/wc/v2/orders"

#region Helper Functions

#region Credentials
<#
	.SYNOPSIS
		Check for the WooCommerce credentials and uri
	
	.DESCRIPTION
		Check the local variables, if the WooCommerce Base-Authentication and uri is provided to connect to the remote uri
	
	.EXAMPLE
		PS C:\> Get-WooCommerceCredential
	
	.NOTES
		Additional information about the function.
#>
function Get-WooCommerceCredential
{
	if ($script:woocommerceUrl -and $script:woocommerceBase64AuthInfo)
	{
		return $true
	}
	else
	{
		Write-Error -Message "You have to run 'Set-WooCommerceCredentials' first" -Category AuthenticationError
		return $false
	}
}

<#
	.SYNOPSIS
		A brief description of the Set-WooCommerceCredential function.
	
	.DESCRIPTION
		A detailed description of the Set-WooCommerceCredential function.
	
	.PARAMETER url
		The url of your WooCommerce installation
	
	.PARAMETER apiKey
		The api Key provided by WooCommerce
	
	.PARAMETER apiSecret
		The api secret provided by WooCommerce
	
	.PARAMETER noMsg
		Hides the status msg of a seccessful connect
	
	.EXAMPLE
		PS C:\> Set-WooCommerceCredential -url 'Value1' -apiKey 'Value2' -apiSecret 'Value3'
	
	.NOTES
		Additional information about the function.
#>
function Set-WooCommerceCredential
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$url,
		[Parameter(Mandatory = $true,
				   Position = 2)]
		[ValidateNotNullOrEmpty()]
		[System.String]$apiKey,
		[Parameter(Mandatory = $true,
				   Position = 3)]
		[ValidateNotNullOrEmpty()]
		[System.String]$apiSecret,
		[Parameter(Position = 4)]
		[switch]$noMsg
	)
	
	If ($PSCmdlet.ShouldProcess("Check if the provided credentials and uri is correct"))
	{
		Try
		{
			Invoke-RestMethod -Method GET -Uri "$url/$script:woocommerceOrder" -Headers @{ Authorization = "Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $apiKey, $apiSecret))) } -ErrorAction Stop | Out-Null
			$script:woocommerceApiSecret = $apiSecret
			$script:woocommerceApiKey = $apiKey
			$script:woocommerceBase64AuthInfo = @{
				Authorization = ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $script:woocommerceApiKey, $script:woocommerceApiSecret))))
			}
			$script:woocommerceUrl = $url
			if (-not ($noMsg))
			{
				Write-Output -InputObject "Credentials set correctly"
			}
		}
		catch
		{
			throw "Wrong Credentials or URL"
		}
	}
}
#endregion Credentials

#endregion Helper Functions

#region Order
<#
	.SYNOPSIS
		Return a list of WooCommerce orders
	
	.DESCRIPTION
		Returns a list or a single WooCommerce order based on the parameters provided
	
	.PARAMETER id
		The id of your WooCommerce order
	
	.PARAMETER all
		Return all orders if nothing is set or if explicitly set
	
	.EXAMPLE
		PS C:\> Get-WooCommerceOrder
	
	.NOTES
		Additional information about the function.
#>
function Get-WooCommerceOrder
{
	param
	(
		[Parameter(Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[Parameter(Position = 2)]
		[switch]$all
	)
	
	if (Get-WooCommerceCredential)
	{
		$url = "$script:woocommerceUrl/$script:woocommerceOrder"
		if ($id -and !$all)
		{
			$url += "/$id"
		}
		$result = Invoke-RestMethod -Method GET -Uri "$url" -Headers $script:woocommerceBase64AuthInfo
		if ($result)
		{
			return $result
		}
	}
}
#endregion Order

#region Product
<#
	.SYNOPSIS
		Creates a new WooCommerce product
	
	.DESCRIPTION
		Creates a new WooCommerce product with the specified parameters
	
	.PARAMETER name
		Provide a name for your product
	
	.PARAMETER type
		Defines the type of the product, avaible types are:
		simple, grouped, external and variable.
		Default is simple
	
	.PARAMETER description
		Provide a description of your product
	
	.PARAMETER short_description
		Provide a brief description of the product
	
	.PARAMETER status
		Defines the status of the product:
		draft, pending, private or publish
	
	.PARAMETER slug
		Slug is used for permalink, define property for custom permalink
	
	.PARAMETER featured
		Set the product as a featured product
	
	.PARAMETER catalog_visibility
		Defines the visibility to the catalog
		visible, catalog, search, hidden
	
	.PARAMETER sku
		Unique identifier of a product
	
	.PARAMETER regular_price
		Set the regular_price of your product
	
	.PARAMETER sale_price
		Price for products on sale
	
	.PARAMETER date_on_sale_from
		A description of the date_on_sale_from parameter.
	
	.PARAMETER date_on_sale_to
		A description of the date_on_sale_to parameter.
	
	.PARAMETER virtual
		A description of the virtual parameter.
	
	.PARAMETER downloadable
		A description of the downloadable parameter.
	
	.EXAMPLE
		PS C:\> New-WooCommerceProduct -regular_price $value1 -name 'Value2' -description 'Value3' -short_description 'Value4'
	
	.NOTES
		Additional information about the function.
#>
function New-WooCommerceProduct
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]$name,
		[ValidateSet('external', 'grouped', 'simple', 'variable')]
		[ValidateNotNullOrEmpty()]
		[System.String]$type = 'simple',
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.String]$description,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.String]$short_description,
		[ValidateSet('draft', 'pending', 'private', 'publish')]
		[ValidateNotNullOrEmpty()]
		[System.String]$status = 'publish',
		[ValidateNotNullOrEmpty()]
		[System.String]$slug,
		[ValidateSet('false', 'true')]
		[ValidateNotNullOrEmpty()]
		[System.String]$featured = 'false',
		[ValidateSet('visible', 'catalog', 'search', 'hidden')]
		[ValidateNotNullOrEmpty()]
		[System.String]$catalog_visibility = 'visible',
		[ValidateNotNullOrEmpty()]
		[System.String]$sku,
		[ValidateNotNullOrEmpty()]
		[double]$regular_price,
		[ValidateNotNullOrEmpty()]
		[double]$sale_price,
		[ValidateNotNullOrEmpty()]
		[datetime]$date_on_sale_from,
		[ValidateNotNullOrEmpty()]
		[datetime]$date_on_sale_to,
		[ValidateSet('false', 'true')]
		[ValidateNotNullOrEmpty()]
		[System.String]$virtual = 'false',
		[ValidateSet('false', 'true')]
		[ValidateNotNullOrEmpty()]
		[System.String]$downloadable = 'false'
	)
	
	If ($PSCmdlet.ShouldProcess("Create a new product"))
	{
		If (Get-WooCommerceCredential)
		{
			$query = @{
			}
			$url = "$script:woocommerceUrl/$script:woocommerceProducts"
			
			$CommandName = $PSCmdlet.MyInvocation.InvocationName
			$ParameterList = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object {
				$_ -notin $filterParameter
			}
			
			ForEach ($Parameter In $ParameterList)
			{
				$var = Get-Variable -Name $Parameter -ErrorAction SilentlyContinue
				If ($var.Value -match "\d|\w")
				{
					$value = $var.Value
					If ($var.Name -in @("date_on_sale_from", "date_on_sale_to"))
					{
						$value = Get-Date $value -Format s
					}
					$query += @{
						$var.Name = "$value"
					}
				}
			}
			$json = $query | ConvertTo-Json
			$result = Invoke-RestMethod -Method POST -Uri "$url" -Headers $script:woocommerceBase64AuthInfo -Body $json -ContentType 'application/json'
			If ($result)
			{
				Return $result
			}
		}
	}
}

<#
	.SYNOPSIS
		Return a list of WooCommerce products
	
	.DESCRIPTION
		Returns a list or a single WooCommerce product based on the parameters provided
	
	.PARAMETER all
		Return all products if nothing is set or if explicitly set
	
	.PARAMETER id
		The id of your WooCommerce product
	
	.EXAMPLE
		PS C:\> Get-WooCommerceProduct
	
	.NOTES
		Additional information about the function.
#>
function Get-WooCommerceProduct
{
	param
	(
		[Parameter(Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[Parameter(Position = 2)]
		[switch]$all
	)
	if (Get-WooCommerceCredential)
	{
		$url = "$script:woocommerceUrl/$script:woocommerceProducts"
		if ($id -and !$all)
		{
			$url += "/$id"
		}
		$result = Invoke-RestMethod -Method GET -Uri "$url" -Headers $script:woocommerceBase64AuthInfo
		if ($result)
		{
			return $result
		}
	}
}

<#
	.SYNOPSIS
		Remove the provided WooCommerce product
	
	.DESCRIPTION
		Remove the provided WooCommerce product
	
	.PARAMETER id
		The id of the WooCommerce product to remove
	
	.PARAMETER permanently
		If set, the product will be deleted permanently
	
	.EXAMPLE
		PS C:\> Remove-WooCommerceProduct -id 'Value1'
	
	.NOTES
		Additional information about the function.
#>
function Remove-WooCommerceProduct
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[switch]$permanently = $false
	)
	
	if ($pscmdlet.ShouldProcess("Remove product $id"))
	{
		if (Get-WooCommerceCredential)
		{
			$url = "$script:woocommerceUrl/$script:woocommerceProducts/$id"
			if ($permanently)
			{
				$url += "?force=true"
			}
			$result = Invoke-RestMethod -Method DELETE -Uri "$url" -Headers $script:woocommerceBase64AuthInfo
			if ($result)
			{
				Return $result
			}
		}
	}
}

<#
	.SYNOPSIS
		Modifys a WooCommerce product
	
	.DESCRIPTION
		Modifys a WooCommerce product with the specified parameters
	
	.PARAMETER id
		A description of the id parameter.
	
	.PARAMETER price
		Set the price of your product
	
	.PARAMETER name
		Provide a name for your product
	
	.PARAMETER description
		Provide a description of your product
	
	.PARAMETER short_description
		Provide a brief description of the product
	
	.EXAMPLE
		PS C:\> Set-WooCommerceProduct -id 'Value1'
	
	.NOTES
		Additional information about the function.
#>
function Set-WooCommerceProduct
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[ValidateNotNullOrEmpty()]
		[System.String]$regular_price,
		[ValidateNotNullOrEmpty()]
		[System.String]$name,
		[ValidateNotNullOrEmpty()]
		[System.String]$description,
		[ValidateNotNullOrEmpty()]
		[System.String]$short_description
	)
	
	if ($pscmdlet.ShouldProcess("Modify product $id"))
	{
		if (Get-WooCommerceCredential)
		{
			$query = @{ }
			$url = "$script:woocommerceUrl/$script:woocommerceProducts/$id"
			
			$CommandName = $PSCmdlet.MyInvocation.InvocationName
			$ParameterList = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object { $_ -notin $filterParameter }
			
			foreach ($Parameter in $ParameterList)
			{
				$var = Get-Variable -Name $Parameter -ErrorAction SilentlyContinue
				if ($var.Value -match "\d|\w")
				{
					$query += @{ $var.Name = $var.Value }
				}
			}
			if ($query.Count -gt 0)
			{
				$json = $query | ConvertTo-Json
				$result = Invoke-RestMethod -Method PUT -Uri "$url" -Headers $script:woocommerceBase64AuthInfo -Body $json -ContentType 'application/json'
				if ($result)
				{
					return $result
				}
			}
			else
			{
				Write-Error -Message "No value provided" -Category InvalidData
			}
		}
	}
}
#endregion Product

Export-ModuleMember -Function Get-WooCommerceOrder,
					Get-WooCommerceProduct,
					New-WooCommerceProduct,
					Set-WooCommerceCredential,
					Set-WooCommerceProduct,
					Remove-WooCommerceProduct