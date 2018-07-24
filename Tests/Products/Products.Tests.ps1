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
if(-not $PSScriptRoot)
{
    [string]$PSScriptRoot = Get-ScriptDirectory
    #$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}
$PSVersion = $PSVersionTable.PSVersion.Major

$script:consumerKey = "ck_4152c4f7449ceff479498be90607bb905761d9b1"
$script:cosumerSecret = "cs_e8e8bf615e8cc3fcf56415ace8d8c04a04551ab6"
$script:url = "https://cloudra.de"

[System.Array]$script:wooCommerceProductsArray = @()

Import-Module -Force $PSScriptRoot\..\..\Woocommerce

Set-WooCommerceCredential -url $script:url -apiKey $script:consumerKey -apiSecret $script:cosumerSecret

Describe "New-WooCommerceProduct" {
    Context "New simple Product" {
        Set-StrictMode -Version latest

        It "Should create a new simple product" {
            $newProduct = New-WooCommerceProduct -name "TestPester"
            $newProduct | Should -Not -BeNullOrEmpty
            $script:wooCommerceProductsArray += $newProduct.ID
        }

        It "Should create a new simple product with price" {
            $price = 10.01
            $newProduct = New-WooCommerceProduct -name "TestPester" -regular_price $price
            $newProduct | Should -not -BeNullOrEmpty
            $newProduct | Should -HaveCount 1
            $script:wooCommerceProductsArray += $newProduct.ID
            $newProduct.regular_price | Should -BeExactly $price
        }

        It "Should create a new simple product with all attributes available" {
            $hashFalseTrue = @{
                "true" = $true
                "false" = $false
            }
            $name = "TestPesterAllAttributes"
            $type = "simple"
            $description = "ProductTest"
            $shortDescription = "ShortProductTest"
            $status = "draft"
            $slug = "test"
            $featured = "$([System.String]([boolean](Get-Random 0,1)))"
            $catalog_visibility = "hidden"
            $price = 0.12
            $sale_price = 0.05
            $date_on_sale_from = "$(Get-Date -Date (Get-Date).AddDays(1) -Format s)"
            $date_on_sale_to = "$(Get-Date -Date (Get-Date).AddDays(3) -Format s)"
            $virtual = "$([System.String]([boolean](Get-Random 0,1)))"
            $downloadable = "$([System.String]([boolean](Get-Random 0,1)))"

            $newProduct = New-WooCommerceProduct -name $name -type $type `
                -description $description -short_description $shortDescription -status $status `
                -slug $slug -featured $featured -catalog_visibility $catalog_visibility -regular_price $price `
                -sale_price $sale_price -date_on_sale_from $date_on_sale_from -date_on_sale_to $date_on_sale_to `
                -virtual $virtual -downloadable $downloadable

            $newProduct | Should -not -BeNullOrEmpty
            $newProduct | Should -HaveCount 1
            $script:wooCommerceProductsArray += $newProduct.ID
            $newProduct.name | Should -BeExactly $name
            $newProduct.type | Should -BeExactly $type
            $newProduct.description | Should -BeExactly $description
            $newProduct.short_description | Should -BeExactly $shortDescription
            $newProduct.status | Should -BeExactly $status
            $newProduct.slug | Should -BeExactly $slug
            $newProduct.featured | Should -BeExactly $hashFalseTrue["$featured"]
            $newProduct.catalog_visibility | Should -BeExactly $catalog_visibility
            $newProduct.regular_price | Should -BeExactly $price
            $newProduct.sale_price | Should -BeExactly $sale_price
            $newProduct.date_on_sale_from | Should -BeExactly $date_on_sale_from
            $newProduct.date_on_sale_to | Should -BeExactly $date_on_sale_to
            $newProduct.virtual | Should -BeExactly $virtual
            $newProduct.downloadable | Should -BeExactly $downloadable
        }
    }
}

Describe "Get-WooCommerceProduct"  {
    
    Context "List Product" { 

        Set-StrictMode -Version latest

        It "Should list one specific product" {
			$product = Get-WooCommerceProduct -id $script:wooCommerceProductsArray[0]
			$product | Should -Not -BeNullOrEmpty
			$product | Should -HaveCount 1
			$product.id | Should -EQ $script:wooCommerceProductsArray[0]
		}
		
		It "Should list all products"
		{
			$products = Get-WooCommerceProduct -all
			$products | Should -Not -BeNullOrEmpty
			($products | Measure-Object).count | Should -HaveCount -BeGreaterThan $script:wooCommerceProductsArray.count
			$script:wooCommerceProductsArray | Should -BeIn $products.id
		}
	}
}

Describe "Set-WooCommerceProduct"  {
	
	Context "New simple Product" {
		Set-StrictMode -Version latest
		
		It "Should create a new simple product" {
			$newProduct = New-WooCommerceProduct -name "TestPester"
			$newProduct | Should -Not -BeNullOrEmpty
			$script:wooCommerceProductsArray += $newProduct.ID
		}
		
		It "Should create a new simple product with price" {
			$price = 10.01
			$newProduct = New-WooCommerceProduct -name "TestPester" -regular_price $price
			$newProduct | Should -not -BeNullOrEmpty
			$newProduct | Should -HaveCount 1
			$script:wooCommerceProductsArray += $newProduct.ID
			$newProduct.regular_price | Should -BeExactly $price
		}
		
		It "Should create a new simple product with all attributes available" {
			$hashFalseTrue = @{
				"true"  = $true
				"false" = $false
			}
			$name = "TestPesterAllAttributes"
			$type = "simple"
			$description = "ProductTest"
			$shortDescription = "ShortProductTest"
			$status = "draft"
			$slug = "test"
			$featured = "$([System.String]([boolean](Get-Random 0, 1)))"
			$catalog_visibility = "hidden"
			$price = 0.12
			$sale_price = 0.05
			$date_on_sale_from = "$(Get-Date -Date (Get-Date).AddDays(1) -Format s)"
			$date_on_sale_to = "$(Get-Date -Date (Get-Date).AddDays(3) -Format s)"
			$virtual = "$([System.String]([boolean](Get-Random 0, 1)))"
			$downloadable = "$([System.String]([boolean](Get-Random 0, 1)))"
			
			$newProduct = New-WooCommerceProduct -name $name -type $type `
												 -description $description -short_description $shortDescription -status $status `
												 -slug $slug -featured $featured -catalog_visibility $catalog_visibility -regular_price $price `
												 -sale_price $sale_price -date_on_sale_from $date_on_sale_from -date_on_sale_to $date_on_sale_to `
												 -virtual $virtual -downloadable $downloadable
			
			$newProduct | Should -not -BeNullOrEmpty
			$newProduct | Should -HaveCount 1
			$script:wooCommerceProductsArray += $newProduct.ID
			$newProduct.name | Should -BeExactly $name
			$newProduct.type | Should -BeExactly $type
			$newProduct.description | Should -BeExactly $description
			$newProduct.short_description | Should -BeExactly $shortDescription
			$newProduct.status | Should -BeExactly $status
			$newProduct.slug | Should -BeExactly $slug
			$newProduct.featured | Should -BeExactly $hashFalseTrue["$featured"]
			$newProduct.catalog_visibility | Should -BeExactly $catalog_visibility
			$newProduct.regular_price | Should -BeExactly $price
			$newProduct.sale_price | Should -BeExactly $sale_price
			$newProduct.date_on_sale_from | Should -BeExactly $date_on_sale_from
			$newProduct.date_on_sale_to | Should -BeExactly $date_on_sale_to
			$newProduct.virtual | Should -BeExactly $virtual
			$newProduct.downloadable | Should -BeExactly $downloadable
		}
	}
}

Describe "Remove-WooCommerceProduct" {
    Context "Delete one" {
        Set-StrictMode -Version latest
        
        It "Should move one Product to bin" {
            $script:wooCommerceProductsArray | Should -Not -BeNullOrEmpty
            $removedProduct = Remove-WooCommerceProduct -id $script:wooCommerceProductsArray[0]
            $removedProduct | Should -Not -BeNullOrEmpty
            $removedProduct | Should -HaveCount 1
            $removedProduct.ID | Should -BeExactly $script:wooCommerceProductsArray[0]
        }
                
        It "Should remove one Product completely" {
            $script:wooCommerceProductsArray | Should -Not -BeNullOrEmpty
            $removedProduct = Remove-WooCommerceProduct -id $script:wooCommerceProductsArray[1] -permanently
            $removedProduct | Should -Not -BeNullOrEmpty
            $removedProduct | Should -HaveCount 1
            $removedProduct.ID | Should -BeExactly $script:wooCommerceProductsArray[1]
        }
		
		It "Should remove all Products completely" {
			Get-WooCommerceProduct | Select-Object -Property ID | Remove-WooCommerceProduct -permanently | Out-Null
			(Get-WooCommerceProduct | Measure-Object).Count | Should -BeExactly 0
		}
    }
}
