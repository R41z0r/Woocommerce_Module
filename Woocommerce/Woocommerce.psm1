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
$hashTrueFalse = @{
	"True"  = $true
	"False" = $false
	$true   = $true
	$false  = $false
}

$script:woocommerceProducts = "wp-json/wc/v2/products"
$script:woocommerceOrder = "wp-json/wc/v2/orders"
$script:woocommercePaymentGateways = "wp-json/wc/v2/payment_gateways"
$script:woocommerceCoupon = "/wp-json/wc/v2/coupons"
$script:woocommerceTaxClass = "/wp-json/wc/v2/taxes/classes"


[boolean]$script:pUseDefaultCredentials = $false
$script:pProxy = ""
$script:pProxyCredentials = ""
[boolean]$script:pProxyUseDefaultCredentials = $false
[boolean]$script:usePersistent = $false

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
	
	.PARAMETER UseDefaultCredentials
		A description of the UseDefaultCredentials parameter.
	
	.PARAMETER Proxy
		A description of the Proxy parameter.
	
	.PARAMETER ProxyUseDefaultCredentials
		A description of the ProxyUseDefaultCredentials parameter.
	
	.PARAMETER ProxyCredential
		A description of the ProxyCredential parameter.
	
	.PARAMETER persistent
		A description of the persistent parameter.
	
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
		[switch]$noMsg,
		[Parameter(Position = 5)]
		[switch]$UseDefaultCredentials,
		[Parameter(Position = 6)]
		[System.Uri]$Proxy,
		[Parameter(Position = 7)]
		[switch]$ProxyUseDefaultCredentials,
		[Parameter(Position = 8)]
		[System.Management.Automation.PSCredential]$ProxyCredential,
		[Parameter(Position = 9)]
		[switch]$persistent
	)
	
	If ($PSCmdlet.ShouldProcess("Check if the provided credentials and uri is correct"))
	{
		Try
		{
			$paramInvokeRestMethod = @{
				Method = 'GET'
				Uri    = "$url/$script:woocommerceOrder"
				Headers = @{ Authorization = "Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $apiKey, $apiSecret))) }
				ErrorAction = 'Stop'
			}
			if ($UseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
			}
			if ($ProxyCredential)
			{
				$paramInvokeRestMethod += @{ ProxyCredential = $ProxyCredential }
			}
			if ($ProxyUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials }
			}
			if ($Proxy)
			{
				$paramInvokeRestMethod += @{ Proxy = $Proxy }
			}
			
			Invoke-RestMethod @paramInvokeRestMethod | Out-Null
			$script:woocommerceApiSecret = $apiSecret
			$script:woocommerceApiKey = $apiKey
			$script:woocommerceBase64AuthInfo = @{
				Authorization = ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $script:woocommerceApiKey, $script:woocommerceApiSecret))))
			}
			$script:woocommerceUrl = $url
			if ($persistent -and ($Proxy -or $ProxyUseDefaultCredentials -or $UseDefaultCredentials -or $ProxyCredential))
			{
				$script:pProxy = $Proxy
				$script:pUseDefaultCredentials = $UseDefaultCredentials
				$script:pProxyUseDefaultCredentials = $ProxyUseDefaultCredentials
				$script:pProxyCredentials = $ProxyCredential
				$script:usePersistent = $true
				Write-Output -InputObject "You set your Proxy-Settings persistent for all commands"
			}
			else
			{
				$script:pUseDefaultCredentials = $false
				$script:pProxy = ""
				$script:pProxyCredentials = ""
				$script:pProxyUseDefaultCredentials = $false
				$script:usePersistent = $false
			}
			if (-not ($noMsg))
			{
				Write-Output -InputObject "Credentials set correctly"
			}
		}
		catch
		{
			throw "$($_.Exception)"
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
		[switch]$all,
		[Parameter(Position = 3)]
		[switch]$UseDefaultCredentials,
		[Parameter(Position = 4)]
		[System.Uri]$Proxy,
		[Parameter(Position = 5)]
		[switch]$ProxyUseDefaultCredentials,
		[Parameter(Position = 6)]
		[System.Management.Automation.PSCredential]$ProxyCredential
	)
	
	if (Get-WooCommerceCredential)
	{
		$url = "$script:woocommerceUrl/$script:woocommerceOrder"
		if ($id -and !$all)
		{
			$url += "/$id"
		}
		$paramInvokeRestMethod = @{
			Method = 'GET'
			Uri    = "$url"
			Headers = $script:woocommerceBase64AuthInfo
		}
		if ($script:usePersistent)
		{
			if ($script:pUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
			}
			if ($script:pProxyCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyCredential = $script:pProxyCredentials }
			}
			if ($script:pProxyUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $script:pProxyUseDefaultCredentials }
			}
			if ($script:pProxy)
			{
				$paramInvokeRestMethod += @{ Proxy = $script:pProxy }
			}
		}
		else
		{
			if ($UseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
			}
			if ($ProxyCredential)
			{
				$paramInvokeRestMethod += @{ ProxyCredential = $ProxyCredential }
			}
			if ($ProxyUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials }
			}
			if ($Proxy)
			{
				$paramInvokeRestMethod += @{ Proxy = $Proxy }
			}
		}
		
		$result = Invoke-RestMethod @paramInvokeRestMethod
		if ($result)
		{
			return $result
		}
	}
}

<#
	.SYNOPSIS
		A brief description of the New-WooCommerceOrder function.
	
	.DESCRIPTION
		A detailed description of the New-WooCommerceOrder function.
	
	.PARAMETER status
		A description of the status parameter.
	
	.PARAMETER currency
		A description of the currency parameter.
	
	.PARAMETER customer_id
		A description of the customer_id parameter.
	
	.PARAMETER customer_note
		A description of the customer_note parameter.
	
	.PARAMETER billing_first_name
		A description of the billing_first_name parameter.
	
	.PARAMETER billing_last_name
		A description of the billing_last_name parameter.
	
	.PARAMETER billing_company
		A description of the billing_company parameter.
	
	.PARAMETER billing_address_1
		A description of the billing_address_1 parameter.
	
	.PARAMETER billing_address_2
		A description of the billing_address_2 parameter.
	
	.PARAMETER billing_city
		A description of the billing_city parameter.
	
	.PARAMETER billing_state
		A description of the billing_state parameter.
	
	.PARAMETER billing_postcode
		A description of the billing_postcode parameter.
	
	.PARAMETER billing_country
		A description of the billing_country parameter.
	
	.PARAMETER billing_email
		A description of the billing_email parameter.
	
	.PARAMETER billing_phone
		A description of the billing_phone parameter.
	
	.PARAMETER shipping_first_name
		A description of the shipping_first_name parameter.
	
	.PARAMETER shipping_last_name
		A description of the shipping_last_name parameter.
	
	.PARAMETER shipping_company
		A description of the shipping_company parameter.
	
	.PARAMETER shipping_address_1
		A description of the shipping_address_1 parameter.
	
	.PARAMETER shipping_address_2
		A description of the shipping_address_2 parameter.
	
	.PARAMETER shipping_city
		A description of the shipping_city parameter.
	
	.PARAMETER shipping_state
		A description of the shipping_state parameter.
	
	.PARAMETER shipping_postcode
		A description of the shipping_postcode parameter.
	
	.PARAMETER shipping_country
		A description of the shipping_country parameter.
	
	.PARAMETER shipping_email
		A description of the shipping_email parameter.
	
	.PARAMETER shipping_phone
		A description of the shipping_phone parameter.
	
	.PARAMETER payment_method
		A description of the payment_method parameter.
	
	.PARAMETER payment_method_title
		A description of the payment_method_title parameter.
	
	.PARAMETER transaction_id
		A description of the transaction_id parameter.
	
	.PARAMETER line_items
		A description of the line_items parameter.
	
	.PARAMETER fee_lines
		[System.Array]$shipping_lines,
	
	.PARAMETER set_paid
		[System.Array]$coupon_lines,
	
	.EXAMPLE
				PS C:\> New-WooCommerceOrder -currency EUR -customer_id 0 -customer_note "Dies ist ein Test" -billing_first_name "Max" -billing_last_name "Mustermann" -billing_address_1 "Musterstraße" -billing_address_2 "Musteretage" -billing_city "Musterstadt" -billing_state "Musterbundeland" -billing_postcode "00000" -billing_country "Musterland" -billing_email "max@mustermann.de" -billing_phone "0123456789" -shipping_first_name "Marta" -shipping_last_name "Musterfrau" -shipping_address_1 "Kleine Musterstraße" -shipping_address_2 "Keller" -shipping_city "Kleine Musterstadt" -shipping_state "Neues Musterbundesland" -shipping_postcode "11111" -shipping_country "Kleine Musterland" -shipping_email "Marta@mustermann.de" -shipping_phone "9876543210" -payment_method cheque -payment_method_title "Chequepayment" -transaction_id ([guid]::NewGuid()) -line_items ((New-WooCommerceOrderLineItem -product_id 168 -quantity 2), (New-WooCommerceOrderLineItem -product_id 167 -quantity 5)) -fee_lines ((New-WooCommerceOrderLineFee -name "Gebühr" -total 10), (New-WooCommerceOrderLineFee -name "Additional Fee" -total 4.95))
	
	.NOTES
		Additional information about the function.
#>
function New-WooCommerceOrder
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[ValidateSet('pending', 'processing', 'on-hold', 'completed', 'cancelled', 'refunded', 'failed', IgnoreCase = $false)]
		[System.String]$status = 'pending',
		[ValidateSet('AED', 'AFN', 'ALL', 'AMD', 'ANG', 'AOA', 'ARS', 'AUD', 'AWG', 'AZN', 'BAM', 'BBD', 'BDT', 'BGN', 'BHD', 'BIF', 'BMD', 'BND', 'BOB', 'BRL', 'BSD', 'BTC', 'BTN', 'BWP', 'BYR', 'BZD', 'CAD', 'CDF', 'CHF', 'CLP', 'CNY', 'COP', 'CRC', 'CUC', 'CUP', 'CVE', 'CZK', 'DJF', 'DKK', 'DOP', 'DZD', 'EGP', 'ERN', 'ETB', 'EUR', 'FJD', 'FKP', 'GBP', 'GEL', 'GGP', 'GHS', 'GIP', 'GMD', 'GNF', 'GTQ', 'GYD', 'HKD', 'HNL', 'HRK', 'HTG', 'HUF', 'IDR', 'ILS', 'IMP', 'INR', 'IQD', 'IRR', 'IRT', 'ISK', 'JEP', 'JMD', 'JOD', 'JPY', 'KES', 'KGS', 'KHR', 'KMF', 'KPW', 'KRW', 'KWD', 'KYD', 'KZT', 'LAK', 'LBP', 'LKR', 'LRD', 'LSL', 'LYD', 'MAD', 'MDL', 'MGA', 'MKD', 'MMK', 'MNT', 'MOP', 'MRO', 'MUR', 'MVR', 'MWK', 'MXN', 'MYR', 'MZN', 'NAD', 'NGN', 'NIO', 'NOK', 'NPR', 'NZD', 'OMR', 'PAB', 'PEN', 'PGK', 'PHP', 'PKR', 'PLN', 'PRB', 'PYG', 'QAR', 'RON', 'RSD', 'RUB', 'RWF', 'SAR', 'SBD', 'SCR', 'SDG', 'SEK', 'SGD', 'SHP', 'SLL', 'SOS', 'SRD', 'SSP', 'STD', 'SYP', 'SZL', 'THB', 'TJS', 'TMT', 'TND', 'TOP', 'TRY', 'TTD', 'TWD', 'TZS', 'UAH', 'UGX', 'USD', 'UYU', 'UZS', 'VEF', 'VND', 'VUV', 'WST', 'XAF', 'XCD', 'XOF', 'XPF', 'YER', 'ZAR', 'ZMW', IgnoreCase = $false)]
		[System.String]$currency = 'USD',
		[ValidateNotNullOrEmpty()]
		[int]$customer_id = 0,
		[System.String]$customer_note,
		[System.String]$billing_first_name,
		[System.String]$billing_last_name,
		[System.String]$billing_company,
		[System.String]$billing_address_1,
		[System.String]$billing_address_2,
		[System.String]$billing_city,
		[System.String]$billing_state,
		[System.String]$billing_postcode,
		[System.String]$billing_country,
		[System.String]$billing_email,
		[System.String]$billing_phone,
		[System.String]$shipping_first_name,
		[System.String]$shipping_last_name,
		[System.String]$shipping_company,
		[System.String]$shipping_address_1,
		[System.String]$shipping_address_2,
		[System.String]$shipping_city,
		[System.String]$shipping_state,
		[System.String]$shipping_postcode,
		[System.String]$shipping_country,
		[System.String]$shipping_email,
		[System.String]$shipping_phone,
		[System.String]$payment_method,
		[System.String]$payment_method_title,
		[System.String]$transaction_id,
		[System.Array]$line_items,
		[System.Array]$fee_lines,
		[switch]$set_paid
	)
	
	If ($PSCmdlet.ShouldProcess("Create a new order"))
	{
		If (Get-WooCommerceCredential)
		{
			$query = @{
			}
			$queryBilling = @{
				
			}
			$url = "$script:woocommerceUrl/$script:woocommerceOrder"
			
			$CommandName = $PSCmdlet.MyInvocation.InvocationName
			$ParameterList = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object {
				$_ -notin $filterParameter -and $_ -notlike "billing_*" -and $_ -notlike "shipping_*" -and $_ -notin ("line_items", "shipping_lines", "fee_lines", "coupon_lines")
			}
			$ParameterBilling = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object {
				$_ -like "billing_*"
			}
			
			$ParameterShipping = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object {
				$_ -like "shipping_*"
			}
			
			ForEach ($Parameter In $ParameterList)
			{
				$var = Get-Variable -Name $Parameter -ErrorAction SilentlyContinue
				If ($var.Value -match "\d|\w")
				{
					$query += @{
						$var.Name = "$($var.Value)"
					}
				}
			}
			ForEach ($Parameter In $ParameterBilling)
			{
				$var = Get-Variable -Name $Parameter -ErrorAction SilentlyContinue
				If ($var.Value -match "\d|\w")
				{
					$name = $var.Name.Substring($var.Name.IndexOf("_") + 1)
					$queryBilling += @{
						$name = "$($var.Value)"
					}
				}
			}
			if ($queryBilling)
			{
				$query += @{
					"billing" = $queryBilling
				}
			}
			
			ForEach ($Parameter In $ParameterShipping)
			{
				$var = Get-Variable -Name $Parameter -ErrorAction SilentlyContinue
				If ($var.Value -match "\d|\w")
				{
					$name = $var.Name.Substring($var.Name.IndexOf("_") + 1)
					$queryShipping += @{
						$name = "$($var.Value)"
					}
				}
			}
			if ($queryShipping)
			{
				$query += @{
					"shipping" = $queryShipping
				}
			}
			
			#Need to modify many stuff to support coupons via REST (self calculation per product - read coupon and product before creation etc.)
			<#if ($coupon_lines.count -gt 0)
			{
				$coupons = @()
				foreach ($coupon in $coupon_lines)
				{
					$coupons += Get-WooCommerceCoupon -id $coupon["code"]
				}
				
				$query += @{
					"coupon_lines" = $coupon_lines
				}
			}#>
			
			if ($line_items.count -gt 0)
			{
				$query += @{
					"line_items" = $line_items
				}
			}
			
			if ($fee_lines.count -gt 0)
			{
				$query += @{
					"fee_lines" = $fee_lines
				}
			}
			
			$json = $query | ConvertTo-Json
			$paramInvokeRestMethod = @{
				Method = 'POST'
				Uri    = "$url"
				Headers = $script:woocommerceBase64AuthInfo
				Body   = ([System.Text.Encoding]::UTF8.GetBytes($json))
				ContentType = 'application/json'
			}
			
			if ($script:usePersistent)
			{
				if ($script:pUseDefaultCredentials)
				{
					$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
				}
				if ($script:pProxyCredentials)
				{
					$paramInvokeRestMethod += @{ ProxyCredential = $script:pProxyCredentials }
				}
				if ($script:pProxyUseDefaultCredentials)
				{
					$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $script:pProxyUseDefaultCredentials }
				}
				if ($script:pProxy)
				{
					$paramInvokeRestMethod += @{ Proxy = $script:pProxy }
				}
			}
			else
			{
				if ($UseDefaultCredentials)
				{
					$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
				}
				if ($ProxyCredential)
				{
					$paramInvokeRestMethod += @{ ProxyCredential = $ProxyCredential }
				}
				if ($ProxyUseDefaultCredentials)
				{
					$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials }
				}
				if ($Proxy)
				{
					$paramInvokeRestMethod += @{ Proxy = $Proxy }
				}
			}
			
			$result = Invoke-RestMethod @paramInvokeRestMethod
			If ($result)
			{
				Return $result
			}
		}
	}
}

<#
	.SYNOPSIS
		A brief description of the Set-WooCommerceOrder function.
	
	.DESCRIPTION
		A detailed description of the Set-WooCommerceOrder function.
	
	.PARAMETER id
		A description of the id parameter.
	
	.PARAMETER status
		A description of the status parameter.
	
	.PARAMETER currency
		A description of the currency parameter.
	
	.PARAMETER customer_id
		A description of the customer_id parameter.
	
	.PARAMETER customer_note
		A description of the customer_note parameter.
	
	.PARAMETER billing_first_name
		A description of the billing_first_name parameter.
	
	.PARAMETER billing_last_name
		A description of the billing_last_name parameter.
	
	.PARAMETER billing_company
		A description of the billing_company parameter.
	
	.PARAMETER billing_address_1
		A description of the billing_address_1 parameter.
	
	.PARAMETER billing_address_2
		A description of the billing_address_2 parameter.
	
	.PARAMETER billing_city
		A description of the billing_city parameter.
	
	.PARAMETER billing_state
		A description of the billing_state parameter.
	
	.PARAMETER billing_postcode
		A description of the billing_postcode parameter.
	
	.PARAMETER billing_country
		A description of the billing_country parameter.
	
	.PARAMETER billing_email
		A description of the billing_email parameter.
	
	.PARAMETER billing_phone
		A description of the billing_phone parameter.
	
	.PARAMETER shipping_first_name
		A description of the shipping_first_name parameter.
	
	.PARAMETER shipping_last_name
		A description of the shipping_last_name parameter.
	
	.PARAMETER shipping_company
		A description of the shipping_company parameter.
	
	.PARAMETER shipping_address_1
		A description of the shipping_address_1 parameter.
	
	.PARAMETER shipping_address_2
		A description of the shipping_address_2 parameter.
	
	.PARAMETER shipping_city
		A description of the shipping_city parameter.
	
	.PARAMETER shipping_state
		A description of the shipping_state parameter.
	
	.PARAMETER shipping_postcode
		A description of the shipping_postcode parameter.
	
	.PARAMETER shipping_country
		A description of the shipping_country parameter.
	
	.PARAMETER shipping_email
		A description of the shipping_email parameter.
	
	.PARAMETER shipping_phone
		A description of the shipping_phone parameter.
	
	.PARAMETER payment_method
		A description of the payment_method parameter.
	
	.PARAMETER payment_method_title
		A description of the payment_method_title parameter.
	
	.PARAMETER transaction_id
		A description of the transaction_id parameter.
	
	.PARAMETER line_items
		A description of the line_items parameter.
	
	.PARAMETER fee_lines
		[System.Array]$shipping_lines,
	
	.PARAMETER set_paid
		[System.Array]$coupon_lines,
	
	.EXAMPLE
				PS C:\> Set-WooCommerceOrder -id 'Value1'
	
	.NOTES
		Additional information about the function.
#>
function Set-WooCommerceOrder
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[ValidateSet('pending', 'processing', 'on-hold', 'completed', 'cancelled', 'refunded', 'failed', IgnoreCase = $false)]
		[System.String]$status = 'pending',
		[ValidateSet('AED', 'AFN', 'ALL', 'AMD', 'ANG', 'AOA', 'ARS', 'AUD', 'AWG', 'AZN', 'BAM', 'BBD', 'BDT', 'BGN', 'BHD', 'BIF', 'BMD', 'BND', 'BOB', 'BRL', 'BSD', 'BTC', 'BTN', 'BWP', 'BYR', 'BZD', 'CAD', 'CDF', 'CHF', 'CLP', 'CNY', 'COP', 'CRC', 'CUC', 'CUP', 'CVE', 'CZK', 'DJF', 'DKK', 'DOP', 'DZD', 'EGP', 'ERN', 'ETB', 'EUR', 'FJD', 'FKP', 'GBP', 'GEL', 'GGP', 'GHS', 'GIP', 'GMD', 'GNF', 'GTQ', 'GYD', 'HKD', 'HNL', 'HRK', 'HTG', 'HUF', 'IDR', 'ILS', 'IMP', 'INR', 'IQD', 'IRR', 'IRT', 'ISK', 'JEP', 'JMD', 'JOD', 'JPY', 'KES', 'KGS', 'KHR', 'KMF', 'KPW', 'KRW', 'KWD', 'KYD', 'KZT', 'LAK', 'LBP', 'LKR', 'LRD', 'LSL', 'LYD', 'MAD', 'MDL', 'MGA', 'MKD', 'MMK', 'MNT', 'MOP', 'MRO', 'MUR', 'MVR', 'MWK', 'MXN', 'MYR', 'MZN', 'NAD', 'NGN', 'NIO', 'NOK', 'NPR', 'NZD', 'OMR', 'PAB', 'PEN', 'PGK', 'PHP', 'PKR', 'PLN', 'PRB', 'PYG', 'QAR', 'RON', 'RSD', 'RUB', 'RWF', 'SAR', 'SBD', 'SCR', 'SDG', 'SEK', 'SGD', 'SHP', 'SLL', 'SOS', 'SRD', 'SSP', 'STD', 'SYP', 'SZL', 'THB', 'TJS', 'TMT', 'TND', 'TOP', 'TRY', 'TTD', 'TWD', 'TZS', 'UAH', 'UGX', 'USD', 'UYU', 'UZS', 'VEF', 'VND', 'VUV', 'WST', 'XAF', 'XCD', 'XOF', 'XPF', 'YER', 'ZAR', 'ZMW', IgnoreCase = $false)]
		[System.String]$currency = 'USD',
		[ValidateNotNullOrEmpty()]
		[int]$customer_id = 0,
		[System.String]$customer_note,
		[System.String]$billing_first_name,
		[System.String]$billing_last_name,
		[System.String]$billing_company,
		[System.String]$billing_address_1,
		[System.String]$billing_address_2,
		[System.String]$billing_city,
		[System.String]$billing_state,
		[System.String]$billing_postcode,
		[System.String]$billing_country,
		[System.String]$billing_email,
		[System.String]$billing_phone,
		[System.String]$shipping_first_name,
		[System.String]$shipping_last_name,
		[System.String]$shipping_company,
		[System.String]$shipping_address_1,
		[System.String]$shipping_address_2,
		[System.String]$shipping_city,
		[System.String]$shipping_state,
		[System.String]$shipping_postcode,
		[System.String]$shipping_country,
		[System.String]$shipping_email,
		[System.String]$shipping_phone,
		[System.String]$payment_method,
		[System.String]$payment_method_title,
		[System.String]$transaction_id,
		[System.Array]$line_items,
		[System.Array]$fee_lines,
		[switch]$set_paid
	)
	
	If ($PSCmdlet.ShouldProcess("Change order $id"))
	{
		If (Get-WooCommerceCredential)
		{
			$query = @{
			}
			$queryBilling = @{
				
			}
			$url = "$script:woocommerceUrl/$script:woocommerceOrder/$id"
			
			$CommandName = $PSCmdlet.MyInvocation.InvocationName
			$ParameterList = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object {
				$_ -notin $filterParameter -and $_ -notlike "billing_*" -and $_ -notlike "shipping_*" -and $_ -notin ("line_items", "shipping_lines", "fee_lines", "coupon_lines")
			}
			$ParameterBilling = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object {
				$_ -like "billing_*"
			}
			
			$ParameterShipping = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object {
				$_ -like "shipping_*"
			}
			
			ForEach ($Parameter In $ParameterList)
			{
				$var = Get-Variable -Name $Parameter -ErrorAction SilentlyContinue
				If ($var.Value -match "\d|\w")
				{
					$query += @{
						$var.Name = "$($var.Value)"
					}
				}
			}
			ForEach ($Parameter In $ParameterBilling)
			{
				$var = Get-Variable -Name $Parameter -ErrorAction SilentlyContinue
				If ($var.Value -match "\d|\w")
				{
					$name = $var.Name.Substring($var.Name.IndexOf("_") + 1)
					$queryBilling += @{
						$name = "$($var.Value)"
					}
				}
			}
			if ($queryBilling)
			{
				$query += @{
					"billing" = $queryBilling
				}
			}
			
			ForEach ($Parameter In $ParameterShipping)
			{
				$var = Get-Variable -Name $Parameter -ErrorAction SilentlyContinue
				If ($var.Value -match "\d|\w")
				{
					$name = $var.Name.Substring($var.Name.IndexOf("_") + 1)
					$queryShipping += @{
						$name = "$($var.Value)"
					}
				}
			}
			if ($queryShipping)
			{
				$query += @{
					"shipping" = $queryShipping
				}
			}
			
			#Need to modify many stuff to support coupons via REST (self calculation per product - read coupon and product before creation etc.)
			<#if ($coupon_lines.count -gt 0)
			{
				$coupons = @()
				foreach ($coupon in $coupon_lines)
				{
					$coupons += Get-WooCommerceCoupon -id $coupon["code"]
				}
				
				$query += @{
					"coupon_lines" = $coupon_lines
				}
			}#>
			
			if ($line_items.count -gt 0)
			{
				$query += @{
					"line_items" = $line_items
				}
			}
			
			if ($fee_lines.count -gt 0)
			{
				$query += @{
					"fee_lines" = $fee_lines
				}
			}
			
			$json = $query | ConvertTo-Json
			$paramInvokeRestMethod = @{
				Method = 'PUT'
				Uri    = "$url"
				Headers = $script:woocommerceBase64AuthInfo
				Body   = ([System.Text.Encoding]::UTF8.GetBytes($json))
				ContentType = 'application/json'
			}
			
			if ($script:usePersistent)
			{
				if ($script:pUseDefaultCredentials)
				{
					$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
				}
				if ($script:pProxyCredentials)
				{
					$paramInvokeRestMethod += @{ ProxyCredential = $script:pProxyCredentials }
				}
				if ($script:pProxyUseDefaultCredentials)
				{
					$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $script:pProxyUseDefaultCredentials }
				}
				if ($script:pProxy)
				{
					$paramInvokeRestMethod += @{ Proxy = $script:pProxy }
				}
			}
			else
			{
				if ($UseDefaultCredentials)
				{
					$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
				}
				if ($ProxyCredential)
				{
					$paramInvokeRestMethod += @{ ProxyCredential = $ProxyCredential }
				}
				if ($ProxyUseDefaultCredentials)
				{
					$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials }
				}
				if ($Proxy)
				{
					$paramInvokeRestMethod += @{ Proxy = $Proxy }
				}
			}
			
			$result = Invoke-RestMethod @paramInvokeRestMethod
			If ($result)
			{
				Return $result
			}
		}
	}
}

function Remove-WooCommerceOrder
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[switch]$permanently = $false,
		[switch]$UseDefaultCredentials,
		[System.Uri]$Proxy,
		[switch]$ProxyUseDefaultCredentials,
		[System.Management.Automation.PSCredential]$ProxyCredential
	)
	process
	{
		if ($pscmdlet.ShouldProcess("Remove order $id"))
		{
			if (Get-WooCommerceCredential)
			{
				$url = "$script:woocommerceUrl/$script:woocommerceOrder/$id"
				if ($permanently)
				{
					$url += "?force=true"
				}
				$paramInvokeRestMethod = @{
					Method = 'DELETE'
					Uri    = "$url"
					Headers = $script:woocommerceBase64AuthInfo
				}
				
				if ($script:usePersistent)
				{
					if ($script:pUseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
					}
					if ($script:pProxyCredentials)
					{
						$paramInvokeRestMethod += @{ ProxyCredential = $script:pProxyCredentials }
					}
					if ($script:pProxyUseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $script:pProxyUseDefaultCredentials }
					}
					if ($script:pProxy)
					{
						$paramInvokeRestMethod += @{ Proxy = $script:pProxy }
					}
				}
				else
				{
					if ($UseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
					}
					if ($ProxyCredential)
					{
						$paramInvokeRestMethod += @{ ProxyCredential = $ProxyCredential }
					}
					if ($ProxyUseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials }
					}
					if ($Proxy)
					{
						$paramInvokeRestMethod += @{ Proxy = $Proxy }
					}
				}
				
				$result = Invoke-RestMethod @paramInvokeRestMethod
				if ($result)
				{
					Return $result
				}
			}
		}
	}
}

#region order helper

function New-WooCommerceOrderLineItem
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[System.String]$name,
		[int]$product_id,
		[int]$variation_id,
		[int]$quantity,
		[int]$tax_class,
		[System.String]$subtotal,
		[System.String]$total
	)
	
	If ($PSCmdlet.ShouldProcess("Create a new order line item"))
	{
		$query = @{
		}
		$CommandName = $PSCmdlet.MyInvocation.InvocationName
		$ParameterList = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object {
			$_ -notin $filterParameter
		}
		ForEach ($Parameter In $ParameterList)
		{
			$var = Get-Variable -Name $Parameter -ErrorAction SilentlyContinue
			If ($var.Value -match "\d|\w")
			{
				$query += @{
					$var.Name = "$($var.Value)"
				}
			}
		}
		return $query
	}
}

function New-WooCommerceOrderLineCoupon
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[System.String]$code,
		[System.String]$discount
	)
	
	If ($PSCmdlet.ShouldProcess("Create a new order line coupon"))
	{
		$query = @{
		}
		$CommandName = $PSCmdlet.MyInvocation.InvocationName
		$ParameterList = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object {
			$_ -notin $filterParameter
		}
		ForEach ($Parameter In $ParameterList)
		{
			$var = Get-Variable -Name $Parameter -ErrorAction SilentlyContinue
			If ($var.Value -match "\d|\w")
			{
				$query += @{
					$var.Name = "$($var.Value)"
				}
			}
		}
		return $query
	}
}

function New-WooCommerceOrderLineFee
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[System.String]$name,
		[System.String]$tax_class,
		[ValidateSet('taxable', 'none')]
		[ValidateNotNullOrEmpty()]
		[System.String]$tax_status,
		[System.String]$total
	)
	
	If ($PSCmdlet.ShouldProcess("Create a new order line fee"))
	{
		$query = @{
		}
		$CommandName = $PSCmdlet.MyInvocation.InvocationName
		$ParameterList = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object {
			$_ -notin $filterParameter
		}
		ForEach ($Parameter In $ParameterList)
		{
			$var = Get-Variable -Name $Parameter -ErrorAction SilentlyContinue
			If ($var.Value -match "\d|\w")
			{
				$query += @{
					$var.Name = "$($var.Value)"
				}
			}
		}
		return $query
	}
}
#endregion order helper

#endregion Order

#region Paymentgateways
function Get-WooCommercePaymentGateway
{
	param
	(
		[Parameter(Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[Parameter(Position = 2)]
		[switch]$all,
		[Parameter(Position = 3)]
		[switch]$UseDefaultCredentials,
		[Parameter(Position = 4)]
		[System.Uri]$Proxy,
		[Parameter(Position = 5)]
		[switch]$ProxyUseDefaultCredentials,
		[Parameter(Position = 6)]
		[System.Management.Automation.PSCredential]$ProxyCredential
	)
	
	if (Get-WooCommerceCredential)
	{
		$url = "$script:woocommerceUrl/$script:woocommercePaymentGateways"
		if ($id -and !$all)
		{
			$url += "/$id"
		}
		$paramInvokeRestMethod = @{
			Method = 'GET'
			Uri    = "$url"
			Headers = $script:woocommerceBase64AuthInfo
		}
		if ($script:usePersistent)
		{
			if ($script:pUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
			}
			if ($script:pProxyCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyCredential = $script:pProxyCredentials }
			}
			if ($script:pProxyUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $script:pProxyUseDefaultCredentials }
			}
			if ($script:pProxy)
			{
				$paramInvokeRestMethod += @{ Proxy = $script:pProxy }
			}
		}
		else
		{
			if ($UseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
			}
			if ($ProxyCredential)
			{
				$paramInvokeRestMethod += @{ ProxyCredential = $ProxyCredential }
			}
			if ($ProxyUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials }
			}
			if ($Proxy)
			{
				$paramInvokeRestMethod += @{ Proxy = $Proxy }
			}
		}
		
		$result = Invoke-RestMethod @paramInvokeRestMethod
		if ($result)
		{
			return $result
		}
	}
}

function Set-WooCommercePaymentGateway
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[ValidateNotNullOrEmpty()]
		[System.String]$title,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.String]$description,
		[ValidateNotNullOrEmpty()]
		[int]$order,
		[ValidateNotNullOrEmpty()]
		[ValidateSet('false', 'true', IgnoreCase = $true)]
		[System.String]$enabled,
		[switch]$UseDefaultCredentials,
		[System.Uri]$Proxy,
		[switch]$ProxyUseDefaultCredentials,
		[System.Management.Automation.PSCredential]$ProxyCredential
	)
	
	if ($pscmdlet.ShouldProcess("Modify payment gateway $id"))
	{
		if (Get-WooCommerceCredential)
		{
			$query = @{ }
			$url = "$script:woocommerceUrl/$script:woocommercePaymentGateways/$id"
			
			$CommandName = $PSCmdlet.MyInvocation.InvocationName
			$ParameterList = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object {
				$_ -notin $filterParameter
			}
			
			foreach ($Parameter In $ParameterList)
			{
				$var = Get-Variable -Name $Parameter -ErrorAction SilentlyContinue
				If ($var.Value -match "\d|\w")
				{
					$value = $var.Value
					if ($var.Name -eq "enabled")
					{
						$value = $hashTrueFalse["$($var.Value)"]
					}
					$query += @{
						$var.Name = "$value"
					}
				}
			}
			
			if ($query.Count -gt 0)
			{
				$json = $query | ConvertTo-Json
				
				$paramInvokeRestMethod = @{
					Method = 'PUT'
					Uri    = "$url"
					Headers = $script:woocommerceBase64AuthInfo
					Body   = ([System.Text.Encoding]::UTF8.GetBytes($json))
					ContentType = 'application/json'
				}
				
				if ($script:usePersistent)
				{
					if ($script:pUseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
					}
					if ($script:pProxyCredentials)
					{
						$paramInvokeRestMethod += @{ ProxyCredential = $script:pProxyCredentials }
					}
					if ($script:pProxyUseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $script:pProxyUseDefaultCredentials }
					}
					if ($script:pProxy)
					{
						$paramInvokeRestMethod += @{ Proxy = $script:pProxy }
					}
				}
				else
				{
					if ($UseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
					}
					if ($ProxyCredential)
					{
						$paramInvokeRestMethod += @{ ProxyCredential = $ProxyCredential }
					}
					if ($ProxyUseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials }
					}
					if ($Proxy)
					{
						$paramInvokeRestMethod += @{ Proxy = $Proxy }
					}
				}
				
				$result = Invoke-RestMethod @paramInvokeRestMethod
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
#endregion Paymentgateways

#region Coupons
function Get-WooCommerceCoupon
{
	param
	(
		[Parameter(Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[Parameter(Position = 2)]
		[switch]$all,
		[Parameter(Position = 3)]
		[switch]$UseDefaultCredentials,
		[Parameter(Position = 4)]
		[System.Uri]$Proxy,
		[Parameter(Position = 5)]
		[switch]$ProxyUseDefaultCredentials,
		[Parameter(Position = 6)]
		[System.Management.Automation.PSCredential]$ProxyCredential
	)
	
	if (Get-WooCommerceCredential)
	{
		$url = "$script:woocommerceUrl/$script:woocommerceCoupon"
		if ($id -and !$all)
		{
			$url += "/$id"
		}
		$paramInvokeRestMethod = @{
			Method = 'GET'
			Uri    = "$url"
			Headers = $script:woocommerceBase64AuthInfo
		}
		if ($script:usePersistent)
		{
			if ($script:pUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
			}
			if ($script:pProxyCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyCredential = $script:pProxyCredentials }
			}
			if ($script:pProxyUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $script:pProxyUseDefaultCredentials }
			}
			if ($script:pProxy)
			{
				$paramInvokeRestMethod += @{ Proxy = $script:pProxy }
			}
		}
		else
		{
			if ($UseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
			}
			if ($ProxyCredential)
			{
				$paramInvokeRestMethod += @{ ProxyCredential = $ProxyCredential }
			}
			if ($ProxyUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials }
			}
			if ($Proxy)
			{
				$paramInvokeRestMethod += @{ Proxy = $Proxy }
			}
		}
		
		$result = Invoke-RestMethod @paramInvokeRestMethod
		if ($result)
		{
			return $result
		}
	}
}

#endregion Coupons


#region Tax Class
function Get-WooCommerceTaxClass
{
	param
	(
		[Parameter(Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[Parameter(Position = 2)]
		[switch]$all,
		[Parameter(Position = 3)]
		[switch]$UseDefaultCredentials,
		[Parameter(Position = 4)]
		[System.Uri]$Proxy,
		[Parameter(Position = 5)]
		[switch]$ProxyUseDefaultCredentials,
		[Parameter(Position = 6)]
		[System.Management.Automation.PSCredential]$ProxyCredential
	)
	
	if (Get-WooCommerceCredential)
	{
		$url = "$script:woocommerceUrl/$script:woocommerceTaxClass"
		if ($id -and !$all)
		{
			$url += "/$id"
		}
		$paramInvokeRestMethod = @{
			Method = 'GET'
			Uri    = "$url"
			Headers = $script:woocommerceBase64AuthInfo
		}
		if ($script:usePersistent)
		{
			if ($script:pUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
			}
			if ($script:pProxyCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyCredential = $script:pProxyCredentials }
			}
			if ($script:pProxyUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $script:pProxyUseDefaultCredentials }
			}
			if ($script:pProxy)
			{
				$paramInvokeRestMethod += @{ Proxy = $script:pProxy }
			}
		}
		else
		{
			if ($UseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
			}
			if ($ProxyCredential)
			{
				$paramInvokeRestMethod += @{ ProxyCredential = $ProxyCredential }
			}
			if ($ProxyUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials }
			}
			if ($Proxy)
			{
				$paramInvokeRestMethod += @{ Proxy = $Proxy }
			}
		}
		
		$result = Invoke-RestMethod @paramInvokeRestMethod
		if ($result)
		{
			return $result
		}
	}
}

#endregion Tax Class


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
	
	.PARAMETER UseDefaultCredentials
		A description of the UseDefaultCredentials parameter.
	
	.PARAMETER Proxy
		A description of the Proxy parameter.
	
	.PARAMETER ProxyUseDefaultCredentials
		A description of the ProxyUseDefaultCredentials parameter.
	
	.PARAMETER ProxyCredential
		A description of the ProxyCredential parameter.
	
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
		[ValidatePattern('\d')]
		[ValidateNotNullOrEmpty()]
		[System.String]$regular_price,
		[ValidateNotNullOrEmpty()]
		[ValidatePattern('\d')]
		[System.String]$sale_price,
		[ValidateNotNullOrEmpty()]
		[datetime]$date_on_sale_from,
		[ValidateNotNullOrEmpty()]
		[datetime]$date_on_sale_to,
		[ValidateSet('false', 'true')]
		[ValidateNotNullOrEmpty()]
		[System.String]$virtual = 'false',
		[ValidateSet('false', 'true')]
		[ValidateNotNullOrEmpty()]
		[System.String]$downloadable = 'false',
		[switch]$UseDefaultCredentials,
		[System.Uri]$Proxy,
		[switch]$ProxyUseDefaultCredentials,
		[System.Management.Automation.PSCredential]$ProxyCredential
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
			
			$paramInvokeRestMethod = @{
				Method = 'POST'
				Uri    = "$url"
				Headers = $script:woocommerceBase64AuthInfo
				Body   = ([System.Text.Encoding]::UTF8.GetBytes($json))
				ContentType = 'application/json'
			}
			
			if ($script:usePersistent)
			{
				if ($script:pUseDefaultCredentials)
				{
					$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
				}
				if ($script:pProxyCredentials)
				{
					$paramInvokeRestMethod += @{ ProxyCredential = $script:pProxyCredentials }
				}
				if ($script:pProxyUseDefaultCredentials)
				{
					$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $script:pProxyUseDefaultCredentials }
				}
				if ($script:pProxy)
				{
					$paramInvokeRestMethod += @{ Proxy = $script:pProxy }
				}
			}
			else
			{
				if ($UseDefaultCredentials)
				{
					$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
				}
				if ($ProxyCredential)
				{
					$paramInvokeRestMethod += @{ ProxyCredential = $ProxyCredential }
				}
				if ($ProxyUseDefaultCredentials)
				{
					$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials }
				}
				if ($Proxy)
				{
					$paramInvokeRestMethod += @{ Proxy = $Proxy }
				}
			}
			$result = Invoke-RestMethod @paramInvokeRestMethod
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
		[switch]$all,
		[Parameter(Position = 3)]
		[switch]$UseDefaultCredentials,
		[Parameter(Position = 4)]
		[System.Uri]$Proxy,
		[Parameter(Position = 5)]
		[switch]$ProxyUseDefaultCredentials,
		[Parameter(Position = 6)]
		[System.Management.Automation.PSCredential]$ProxyCredential
	)
	if (Get-WooCommerceCredential)
	{
		$url = "$script:woocommerceUrl/$script:woocommerceProducts"
		if ($id -and !$all)
		{
			$url += "/$id"
		}
		$paramInvokeRestMethod = @{
			Method = 'GET'
			Uri    = "$url"
			Headers = $script:woocommerceBase64AuthInfo
		}
		
		if ($script:usePersistent)
		{
			if ($script:pUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
			}
			if ($script:pProxyCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyCredential = $script:pProxyCredentials }
			}
			if ($script:pProxyUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $script:pProxyUseDefaultCredentials }
			}
			if ($script:pProxy)
			{
				$paramInvokeRestMethod += @{ Proxy = $script:pProxy }
			}
		}
		else
		{
			if ($UseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
			}
			if ($ProxyCredential)
			{
				$paramInvokeRestMethod += @{ ProxyCredential = $ProxyCredential }
			}
			if ($ProxyUseDefaultCredentials)
			{
				$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials }
			}
			if ($Proxy)
			{
				$paramInvokeRestMethod += @{ Proxy = $Proxy }
			}
		}
		
		$result = Invoke-RestMethod @paramInvokeRestMethod
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
				   ValueFromPipelineByPropertyName = $true,
				   Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[switch]$permanently = $false,
		[switch]$UseDefaultCredentials,
		[System.Uri]$Proxy,
		[switch]$ProxyUseDefaultCredentials,
		[System.Management.Automation.PSCredential]$ProxyCredential
	)
	process
	{
		if ($pscmdlet.ShouldProcess("Remove product $id"))
		{
			if (Get-WooCommerceCredential)
			{
				$url = "$script:woocommerceUrl/$script:woocommerceProducts/$id"
				if ($permanently)
				{
					$url += "?force=true"
				}
				$paramInvokeRestMethod = @{
					Method = 'DELETE'
					Uri    = "$url"
					Headers = $script:woocommerceBase64AuthInfo
				}
				
				if ($script:usePersistent)
				{
					if ($script:pUseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
					}
					if ($script:pProxyCredentials)
					{
						$paramInvokeRestMethod += @{ ProxyCredential = $script:pProxyCredentials }
					}
					if ($script:pProxyUseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $script:pProxyUseDefaultCredentials }
					}
					if ($script:pProxy)
					{
						$paramInvokeRestMethod += @{ Proxy = $script:pProxy }
					}
				}
				else
				{
					if ($UseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
					}
					if ($ProxyCredential)
					{
						$paramInvokeRestMethod += @{ ProxyCredential = $ProxyCredential }
					}
					if ($ProxyUseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials }
					}
					if ($Proxy)
					{
						$paramInvokeRestMethod += @{ Proxy = $Proxy }
					}
				}
				
				$result = Invoke-RestMethod @paramInvokeRestMethod
				if ($result)
				{
					Return $result
				}
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
		[System.String]$downloadable = 'false',
		[switch]$UseDefaultCredentials,
		[System.Uri]$Proxy,
		[switch]$ProxyUseDefaultCredentials,
		[System.Management.Automation.PSCredential]$ProxyCredential
	)
	
	if ($pscmdlet.ShouldProcess("Modify product $id"))
	{
		if (Get-WooCommerceCredential)
		{
			$query = @{ }
			$url = "$script:woocommerceUrl/$script:woocommerceProducts/$id"
			
			$CommandName = $PSCmdlet.MyInvocation.InvocationName
			$ParameterList = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object {
				$_ -notin $filterParameter
			}
			
			foreach ($Parameter In $ParameterList)
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
			
			if ($query.Count -gt 0)
			{
				$json = $query | ConvertTo-Json
				
				$paramInvokeRestMethod = @{
					Method = 'PUT'
					Uri    = "$url"
					Headers = $script:woocommerceBase64AuthInfo
					Body   = ([System.Text.Encoding]::UTF8.GetBytes($json))
					ContentType = 'application/json'
				}
				
				if ($script:usePersistent)
				{
					if ($script:pUseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
					}
					if ($script:pProxyCredentials)
					{
						$paramInvokeRestMethod += @{ ProxyCredential = $script:pProxyCredentials }
					}
					if ($script:pProxyUseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $script:pProxyUseDefaultCredentials }
					}
					if ($script:pProxy)
					{
						$paramInvokeRestMethod += @{ Proxy = $script:pProxy }
					}
				}
				else
				{
					if ($UseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ UseDefaultCredentials = $true }
					}
					if ($ProxyCredential)
					{
						$paramInvokeRestMethod += @{ ProxyCredential = $ProxyCredential }
					}
					if ($ProxyUseDefaultCredentials)
					{
						$paramInvokeRestMethod += @{ ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials }
					}
					if ($Proxy)
					{
						$paramInvokeRestMethod += @{ Proxy = $Proxy }
					}
				}
				
				$result = Invoke-RestMethod @paramInvokeRestMethod
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