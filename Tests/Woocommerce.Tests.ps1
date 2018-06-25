#handle PS2
if(-not $PSScriptRoot)
{
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

$PSVersion = $PSVersionTable.PSVersion.Major
Import-Module -Force $PSScriptRoot\..\Woocommerce


#This is more appropriate for context, but we include PSVersion in the It blocks to differentiate in AppVeyor
Describe "Invoke-DiskPartScript"  {
    
    Context "Strict mode" { 

        Set-StrictMode -Version latest

        It "Should list disks on a local system PS$PSVersion" {

            $OutString = Invoke-DiskPartScript -ComputerName $env:COMPUTERNAME -DiskPartText "list disk" -Raw
            $OutArray = ($OutString -split "`n") | Where-Object { $_ -match "[A-Za-z0-9]"}
            
            #Hopefully you have at least one disk.
            $OutArray.Count | Should BeGreaterThan 4

            #Is this different on other versions of Windows?  Is there a better regex?
            $OutString | Should Match "\s*Disk ###\s*Status\s*Size\s*Free.*"
        }
    }
}

Describe "Get-DiskPartDisk" {
    
    Context "Strict mode" { 

        Set-StrictMode -Version latest

        It "Should list disks on a local system PS$PSVersion" {

            $OutArray = @( Get-DiskPartDisk -ComputerName $env:COMPUTERNAME )
            
            #Hopefully you have at least one disk.
            $OutArray.Count | Should BeGreaterThan 0
        }
    }
}

Describe "Get-DiskPartVolume"  {
    
    Context "Strict mode" { 

        Set-StrictMode -Version latest

        It "Should list volumes on a local system PS$PSVersion" {

            $OutArray = @( Get-DiskPartVolume -ComputerName $env:COMPUTERNAME )
            
            #Hopefully you have at least one volume.
            $OutArray.Count | Should BeGreaterThan 0

            #Does it have a subset of props?
                $ActualProperties = $OutArray[0].PSObject.Properties | Select -ExpandProperty Name
                $ExpectedProperties = echo ComputerName VolumeNumber Letter Label
                $Comparison = Compare-Object -ReferenceObject $ActualProperties -DifferenceObject $ExpectedProperties
            
                ( $Comparison | Select -ExpandProperty SideIndicator ) -Contains "=>" | Should be $False
        }
    }
}