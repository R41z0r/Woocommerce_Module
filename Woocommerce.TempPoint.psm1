<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	27.12.2017 08:40
	 Created by:   	DV48441
	 Organization: 	
	 Filename:     	Woocommerce.psm1
	-------------------------------------------------------------------------
	 Module Name: Woocommerce
	===========================================================================
#>
$script:woocommerceUrl = "https://pole-oase.de"
$script:woocommerceProducts = "wp-json/wc/v2/products"
$script:woocommerceOrder = "wp-json/wc/v2/orders"
$script:woocommerceApiKey = "ck_15400a2006aa8286e4403cb1700675a71d6e8cc4"
$script:woocommerceApiSecret = "cs_5a9efce74ea21f1170a0b10edc20f447e6292bd8"
$script:woocommerceBase64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $script:woocommerceApiKey, $script:woocommerceApiSecret)))

function Get-WooCommerceOrder
{
	param
	(
		[switch]$all,
		[System.String]$id
	)
	if ($id)
	{
		$result = Invoke-RestMethod -Method GET -Uri "$script:woocommerceUrl/$script:woocommerceOrder/$id" -Headers @{ Authorization = ("Basic {0}" -f $script:woocommerceBase64AuthInfo) }
	}
	elseif ($all)
	{
		$result = Invoke-RestMethod -Method GET -Uri "$script:woocommerceUrl/$script:woocommerceOrder/$id" -Headers @{ Authorization = ("Basic {0}" -f $script:woocommerceBase64AuthInfo) }
	}
	if ($result)
	{
		return $result
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
		$result = Invoke-RestMethod -Method GET -Uri "$script:woocommerceUrl/$script:woocommerceProducts/$id" -Headers @{ Authorization = ("Basic {0}" -f $script:woocommerceBase64AuthInfo) }
	}
	elseif ($all)
	{
		$result = Invoke-RestMethod -Method GET -Uri "$script:woocommerceUrl/$script:woocommerceProducts" -Headers @{ Authorization = ("Basic {0}" -f $script:woocommerceBase64AuthInfo) }
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
		"name" = "$name"
		"type" = "$type"
		"regular_price" = "$($price -replace ",", ".")"
		"description" = "$description"
		"short_description" = "$shortDescription"
	}
	$json = $query | ConvertTo-Json
	$result = Invoke-RestMethod -Method POST -Uri "$script:woocommerceUrl/$script:woocommerceProducts" -Headers @{ Authorization = ("Basic {0}" -f $script:woocommerceBase64AuthInfo) } -Body $json -ContentType 'application/json'
	if ($result)
	{
		return $result
	}
}


Export-ModuleMember -Function Get-WooCommerceOrder,
					Get-WooCommerceProduct,
					New-WooCommerceProduct