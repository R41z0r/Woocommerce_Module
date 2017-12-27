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
		Write-Error -Message "You have to run 'Set-WooCommerceCredentials' first" -Category ReadError
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
		[System.String]$apiSecret
	)
	
	If ($PSCmdlet.ShouldProcess("Check if the provided credentials and uri is correct"))
	{
		Try
		{
			Invoke-RestMethod -Method GET -Uri "$url/wp-json/wc/v2" -Headers @{ Authorization = "Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $apiKey, $apiSecret))) } -ErrorAction Stop | Out-Null
			$script:woocommerceApiSecret = $apiSecret
			$script:woocommerceApiKey = $apiKey
			$script:woocommerceBase64AuthInfo = @{
				Authorization	  = ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $script:woocommerceApiKey, $script:woocommerceApiSecret))))
			}
			$script:woocommerceUrl = $url
		}
		catch
		{
			Write-Error -Message "Wrong Credentials or URL" -Category AuthenticationError -RecommendedAction "Please provide valid Credentials or the right uri"
		}
	}
}

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

<#
	.SYNOPSIS
		Creates a new WooCommerce product
	
	.DESCRIPTION
		Creates a new WooCommerce product with the specified parameters
	
	.PARAMETER price
		Set the price of your product
	
	.PARAMETER name
		Provide a name for your product
	
	.PARAMETER description
		Provide a description of your product
	
	.PARAMETER briefDescription
		Provide a brief description of the product
	
	.PARAMETER type
		Defines the type of the product, avaible types are:
		simple, grouped, external and variable.
		Default is simple
	
	.EXAMPLE
				PS C:\> New-WooCommerceProduct -price $value1 -name 'Value2' -description 'Value3' -briefDescription 'Value4'
	
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
		[double]$price,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]$name,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]$description,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]$briefDescription,
		[ValidateSet('external', 'grouped', 'simple', 'variable')]
		[ValidateNotNullOrEmpty()]
		[System.String]$type = 'simple'
	)
	
	If ($PSCmdlet.ShouldProcess("Create a new product"))
	{
		$query = @{
			"name"	   = "$name"
			"type"	   = "$type"
			"regular_price" = "$($price -replace ",", ".")"
			"description" = "$description"
			"short_description" = "$briefDescription"
		}
		$json = $query | ConvertTo-Json
		$result = Invoke-RestMethod -Method POST -Uri "$script:woocommerceUrl/$script:woocommerceProducts" -Headers $script:woocommerceBase64AuthInfo -Body $json -ContentType 'application/json'
		if ($result)
		{
			return $result
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
		[System.String]$price,
		[ValidateNotNullOrEmpty()]
		[System.String]$name,
		[ValidateNotNullOrEmpty()]
		[System.String]$description,
		[ValidateNotNullOrEmpty()]
		[System.String]$short_description
	)
	if ($pscmdlet.ShouldProcess("Modify product $id"))
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

Export-ModuleMember -Function Get-WooCommerceOrder,
					Get-WooCommerceProduct,
					New-WooCommerceProduct,
					Set-WooCommerceCredential,
					Set-WooCommerceProduct