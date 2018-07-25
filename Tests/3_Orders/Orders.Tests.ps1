function Get-ScriptDirectory
{
<#
	.SYNOPSIS
		Get-ScriptDirectory returns the proper location of the script.

	.OUTPUTS
		System.String
	
	.NOTES
		Returns the correct path within a packaged executable.
#>
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}

#Sample variable that provides the location of the script

#handle PS2
if (-not $PSScriptRoot)
{
	[string]$PSScriptRoot = Get-ScriptDirectory
	$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}
$PSVersion = $PSVersionTable.PSVersion.Major

$script:consumerKey = "ck_4152c4f7449ceff479498be90607bb905761d9b1"
$script:cosumerSecret = "cs_e8e8bf615e8cc3fcf56415ace8d8c04a04551ab6"
$script:url = "https://cloudra.de"

[System.Array]$script:wooCommerceOrdersArray = @()

Import-Module -Force $PSScriptRoot\..\..\Woocommerce

Set-WooCommerceCredential -url $script:url -apiKey $script:consumerKey -apiSecret $script:cosumerSecret

Describe "New-WooCommerceOrder" {
	Context "New simple Order" {
		Set-StrictMode -Version latest
		
		It "Should create a new simple order" {
			$status = "on-hold"
			$newOrder = New-WooCommerceOrder -status $status
			$newOrder | Should -Not -BeNullOrEmpty
			$newOrder.status | Should -BeExactly $status
			$script:wooCommerceOrdersArray += $newOrder.ID
		}
		
		It "Should create a new simple order for customer 0" {
			$status = "on-hold"
			$customer = 0
			$newOrder = New-WooCommerceOrder -status $status -customer_id 0
			$newOrder | Should -Not -BeNullOrEmpty
			$newOrder.status | Should -BeExactly $status
			$newOrder.customer_id | Should -BeExactly $status
			$script:wooCommerceOrdersArray += $newOrder.ID
		}
		
		It "Should create a new order with all attributes available" {
			$hashFalseTrue = @{
				"true"  = $true
				"false" = $false
			}
			$currency = "EUR"
			$customer_id = 0
			$customer_note = "Dies=ist=ein=Test"
			$billing_first_name = "Max"
			$billing_last_name = "Mustermann"
			$billing_address_1 = "Musterstraße"
			$billing_address_2 = "Musteretage"
			$billing_city = "Musterstadt"
			$billing_state = "Musterbundeland"
			$billing_postcode = "00000"
			$billing_country = "Musterland"
			$billing_email = "max@mustermann.de"
			$billing_phone = "0123456789"
			$shipping_first_name = "Marta"
			$shipping_last_name = "Musterfrau"
			$shipping_address_1 = "Kleine=Musterstraße"
			$shipping_address_2 = "Keller"
			$shipping_city = "Kleine=Musterstadt"
			$shipping_state = "Neues=Musterbundesland"
			$shipping_postcode = "11111"
			$shipping_country = "Kleine=Musterland"
			$shipping_email = "Marta@mustermann.de"
			$shipping_phone = "9876543210"
			$payment_method = "cheque"
			$payment_method_title = "Chequepayment"
			$transaction_id = ([guid]::NewGuid())
			$fee_lines = (New-WooCommerceOrderLineFee -name "Gebühr" -total 10)
			
			$newOrder = New-WooCommerceOrder -currency $currency -customer_id $customer_id -customer_note $customer_note `
											 -billing_first_name $billing_first_name -billing_last_name $billing_last_name -billing_address_1 $billing_address_1 `
											 -billing_address_2 $billing_address_2 -billing_city $billing_city -billing_state $billing_state `
											 -billing_postcode $billing_postcode -billing_country $billing_country -billing_email $billing_email `
											 -billing_phone $billing_phone -shipping_first_name $shipping_first_name -shipping_last_name $shipping_last_name `
											 -shipping_address_1 $shipping_address_1 -shipping_address_2 $shipping_address_2 -shipping_city $shipping_city `
											 -shipping_state $shipping_state -shipping_postcode $shipping_postcode -shipping_country $shipping_country `
											 -shipping_email $shipping_email -shipping_phone $shipping_phone -payment_method $payment_method `
											 -payment_method_title $payment_method_title -transaction_id $transaction_id `
											 -fee_lines $fee_lines
			
			$newOrder | Should -not -BeNullOrEmpty
			$newOrder | Should -HaveCount 1
			$script:wooCommerceOrdersArray += $newOrder.ID
			
			$newOrder | Should -not -BeNullOrEmpty
			$newOrder | Should -HaveCount 1
			$script:wooCommerceOrdersArray += $newOrder.ID
			$newOrder.currency | Should -BeExactly $currency
			$newOrder.customer_id | Should -BeExactly $customer_id
			$newOrder.customer_note | Should -BeExactly $customer_note
			$newOrder.billing.first_name | Should -BeExactly $billing_first_name
			$newOrder.billing.last_name | Should -BeExactly $billing_last_name
			$newOrder.billing.address_1 | Should -BeExactly $billing_address_1
			$newOrder.billing.address_2 | Should -BeExactly $billing_address_2
			$newOrder.billing.city | Should -BeExactly $billing_city
			$newOrder.billing.state | Should -BeExactly $billing_state
			$newOrder.billing.postcode | Should -BeExactly $billing_postcode
			$newOrder.billing.country | Should -BeExactly $billing_country
			$newOrder.billing.email | Should -BeExactly $billing_email
			$newOrder.billing.phone | Should -BeExactly $billing_phone
		}
	}
}

Describe "Get-WooCommerceOrder"  {
	
	Context "List Orders" {
		
		Set-StrictMode -Version latest
		
		It "Should list one specific Order" {
			$order = Get-WooCommerceOrder -id $script:wooCommerceOrdersArray[0]
			$order | Should -Not -BeNullOrEmpty
			$order | Should -HaveCount 1
			$order.id | Should -Be $script:wooCommerceOrdersArray[0]
		}
		
		It "Should list all orders" {
			$order = Get-WooCommerceOrder -all
			$order | Should -Not -BeNullOrEmpty
			($order | Measure-Object).count | Should -BeGreaterOrEqual $script:wooCommerceOrdersArray.count
			$script:wooCommerceOrdersArray | Should -BeIn $order.id
		}
	}
}

Describe "Remove-WooCommerceOrder" {
	Context "Delete one" {
		Set-StrictMode -Version latest
		
		It "Should move one Order to bin" {
			$script:wooCommerceOrdersArray | Should -Not -BeNullOrEmpty
			$removedOrder = Remove-WooCommerceOrder -id $script:wooCommerceOrdersArray[0]
			$removedOrder | Should -Not -BeNullOrEmpty
			$removedOrder | Should -HaveCount 1
			$removedOrder.ID | Should -BeExactly $script:wooCommerceOrdersArray[0]
		}
		
		It "Should remove one Order completely" {
			$script:wooCommerceOrdersArray | Should -Not -BeNullOrEmpty
			($script:wooCommerceOrdersArray).Count | Should -BeGreaterOrEqual 2
			$removedOrder = Remove-WooCommerceOrder -id $script:wooCommerceOrdersArray[1] -permanently
			$removedOrder | Should -Not -BeNullOrEmpty
			$removedOrder | Should -HaveCount 1
			$removedOrder.ID | Should -BeExactly $script:wooCommerceOrdersArray[1]
		}
		It "Should remove all Orders completely" {
			Get-WooCommerceOrder | Select-Object -Property ID | ForEach-Object -Process { Remove-WooCommerceOrder -id $PSItem.id -permanently | Out-Null }
			(Get-WooCommerceOrder | Measure-Object).Count | Should -BeExactly 0
		}
	}
}
