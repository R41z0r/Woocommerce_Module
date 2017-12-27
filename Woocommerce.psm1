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

$script:woocommerceProducts = "wp-json/wc/v2/products"
$script:woocommerceOrder = "wp-json/wc/v2/orders"

<#
	Get and Set Credentials and Uri
#>
function Get-WooCommerceCredentials
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

function Set-WooCommerceCredentials
{
	param
	(
		[System.String]$url,
		[System.String]$apiKey,
		[System.String]$apiSecret
	)
	Try
	{
		$result = Invoke-RestMethod -Method GET -Uri "$url/wp-json/wc/v2" -Headers @{ Authorization = "Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $apiKey, $apiSecret))) } -ErrorAction Stop
		$script:woocommerceApiSecret = $apiSecret
		$script:woocommerceApiKey = $apiKey
		$script:woocommerceBase64AuthInfo = @{
			Authorization  = ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $script:woocommerceApiKey, $script:woocommerceApiSecret))))
		}
		$script:woocommerceUrl = $url
	}
	catch
	{
		Write-Error -Message "Wrong Credentials or URL" -Category AuthenticationError -RecommendedAction "Please provide valid Credentials or the right uri"
	}
}

function Get-WooCommerceOrder
{
	param
	(
		[switch]$all,
		[System.String]$id
	)
	if (Get-WooCommerceCredentials)
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
    Products
#>
function Get-WooCommerceProduct
{
	param
	(
		[switch]$all,
		[System.String]$id
	)
	if ($id)
	{
		$result = Invoke-RestMethod -Method GET -Uri "$script:woocommerceUrl/$script:woocommerceProducts/$id" -Headers $script:woocommerceBase64AuthInfo
	}
	elseif ($all)
	{
		$result = Invoke-RestMethod -Method GET -Uri "$script:woocommerceUrl/$script:woocommerceProducts" -Headers $script:woocommerceBase64AuthInfo
	}
	if ($result)
	{
		return $result
	}
}

function New-WooCommerceProduct
{
	param
	(
		[double]$price,
		[System.String]$name,
		[System.String]$description,
		[System.String]$shortDescription,
		[System.String]$type = "simple"
	)
	$query = @{
		"name"    = "$name"
		"type"    = "$type"
		"regular_price" = "$($price -replace ",", ".")"
		"description" = "$description"
		"short_description" = "$shortDescription"
	}
	$json = $query | ConvertTo-Json
	$result = Invoke-RestMethod -Method POST -Uri "$script:woocommerceUrl/$script:woocommerceProducts" -Headers $script:woocommerceBase64AuthInfo
	if ($result)
	{
		return $result
	}
}

Export-ModuleMember -Function Get-WooCommerceOrder,
					Get-WooCommerceProduct,
					New-WooCommerceProduct,
					Set-WooCommerceCredentials