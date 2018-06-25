#handle PS2
if(-not $PSScriptRoot)
{
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
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
            $price = 0.12
            $description = "ProductTest"
            $shortDescription = "ShortProductTest"
            $type = "simple"
            $status = "draft"
            $featured = "false"
            $catalog_visibility = "hidden"
            $name = "TestPesterAllAttributes"

            $newProduct = New-WooCommerceProduct -name $name -regular_price $price `
                -description $description -short_description $shortDescription -type $type -status $status `
                -featured $featured -catalog_visibility $catalog_visibility

            $newProduct | Should -not -BeNullOrEmpty
            $newProduct | Should -HaveCount 1
            $script:wooCommerceProductsArray += $newProduct.ID
            $newProduct.regular_price | Should -BeExactly $price
            $newProduct.description | Should -BeExactly $description
            $newProduct.short_description | Should -BeExactly $shortDescription
            $newProduct.status | Should -BeExactly $status
            $newProduct.type | Should -BeExactly $type
            $newProduct.featured | Should -BeExactly $hashFalseTrue["$featured"]
            $newProduct.catalog_visibility | Should -BeExactly $catalog_visibility
            $newProduct.name | Should -BeExactly $name
        }
    }
}

Describe "Get-WooCommerceProduct"  {
    
    Context "All Products" { 

        Set-StrictMode -Version latest

        It "Should list all Products in WooCommerce" {
            $products = Get-WooCommerceProduct -all
            $products | Should -Not -BeNullOrEmpty
            ($products | Measure-Object).Count | Should -BeGreaterOrEqual ($script:wooCommerceProductsArray.Count)
            $products.ID | ForEach-Object -Process { $PSItem | Should -BeIn $script:wooCommerceProductsArray }
        }
    }

    Context "One Product" {
        Set-StrictMode -Version latest

        It "Should list a specific Product in WooCommerce" {
            $script:wooCommerceProductsArray | Should -Not -BeNullOrEmpty
            $product = Get-WooCommerceProduct -id $script:wooCommerceProductsArray[0]
            $product | Should -not -BeNullOrEmpty
            $product | Should -HaveCount 1
            $product.ID | Should -BeExactly $script:wooCommerceProductsArray[0]
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
    }
}