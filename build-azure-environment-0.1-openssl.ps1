## Middlebox Hackathon Environment Creation Script
## 
## v0.1 - Matt C (NCSC)
##
## Instructions
##
##   - Install the Azure Powershell cmdlets from https://docs.microsoft.com/en-us/powershell/azure/install-azurerm-ps
##
##   - Configure the deployment name: (for various reasons this should be 3 characters or fewer)
        $deploymentName = "CYB-$(Get-Random)"
##
##   - Configure the desired Azure region: (choose from centralus, eastasia, southeastasia, eastus, eastus2, westus,
##     westus2, northcentralus, southcentralus, westcentralus, northeurope, westeurope, japaneast, japanwest,
##     brazilsouth, australiasoutheast, australiaeast, westindia, southindia, centralindia, canadacentral, canadaeast,
##     uksouth, ukwest, koreacentral, koreasouth). Note that not all features are present in all location. This script has
##     been tested using the centralus location.
        $location = "centralus"
##
##   - configure the auto-run scripts:
        $serverConfigScript = "https://raw.githubusercontent.com/middleboxhackathon/test-environment/master/build-server.sh"
        $serverConfigScriptName = "build-server-0.1-openssl.sh"
##
##   - If you don't already have SSH keys in ./.ssh/ (as id_rsa and id_rsa.pub) then create them
##
##   - Run the script
##
##   - The script will display the IP addresses of the created VMs, at the moment you'll have to guess which is which
##     (generally the lower number will be the first once created etc.)
##
##   - play
##
##   - To remove all created resources from Azure, use 'Remove-AzureRmResourceGroup -Name $resourceGroupName'

##
##   To configure the Linux VMs run
##
##      curl https://raw.githubusercontent.com/middleboxhackathon/test-environment/master/build-proxy.sh | bash
##   or
##      curl https://raw.githubusercontent.com/middleboxhackathon/test-environment/master/build-server.sh | bash
##


#### You shouldn't need to edit anything below here. ####
$startTime = Get-Date
$resourceGroupName = "$($deploymentName)-ResGrp"
$vmNamePrefix = "$($deploymentName)"
$vNetName = "$($deploymentName)-VNet"
$subnetName = "$($deploymentName)-Subnet"
$securityGroupName = "$($deploymentName)-SecGrp"
$storageAccountName = "$($deploymentName)-Storage".ToLower().Replace("-", "")
$scriptStorageContainerName = "$($deploymentName)-ScriptStorageContainer".ToLower()

## Load Azure module
# Import-Module AzureRM

## Log in to Azure
if ([string]::IsNullOrEmpty($(Get-AzureRmContext).Account)) {Login-AzureRmAccount}

## Create Resource Group
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

## Create Virtual Network and Virtual Subnets
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 192.168.1.0/24
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vNetName -AddressPrefix 192.168.0.0/16 -Location $location -Subnet $subnetConfig
#Add-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix 192.168.1.0/24
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

## Create storage account for storing config scripts and PCAPs
$storage = New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName "Standard_LRS"
Set-AzureRmCurrentStorageAccount -StorageAccountName $storageAccountName -ResourceGroupName $resourceGroupName
New-AzureStorageContainer -name $scriptStorageContainerName
$storageKey = (Get-AzureRmStorageAccountKey -Name $storageAccountName -ResourceGroupName $resourceGroupName).Value[0]

## Upload Config Scripts
Set-AzureStorageBlobContent -File $serverConfigScriptName -container $scriptStorageContainerName

## Create Virtual Machine(s)

# Create Ubuntu Server VM
# Note: there should be a copy of your SSH public key at ./ssh/id_rsa.pub
# Note: from https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-powershell
function createServerVM() {
    # Create an inbound network security group rule for port 22
    $nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow

    # Create an inbound network security group rule for port 80
    $nsgRuleWeb = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleWWW  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80 -Access Allow

    # Create an inbound network security group rule for port 443
    $nsgRuleWebSec = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleWWWSec  -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443 -Access Allow

    # Create a network security group
    $nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$($deploymentName)-Server-NSG" -SecurityRules $nsgRuleSSH,$nsgRuleWeb,$nsgRuleWebSec

    # Create a public IP address and specify a DNS name
    $pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "$deploymentName-Server-IP" -DomainNameLabel ($deploymentName.ToLower() + "-server")

    # Create a virtual network card and associate with public IP address and NSG
    $nic = New-AzureRmNetworkInterface -Name "$deploymentName-Server-NIC" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

    # Define a credential object
    $securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ("azureuser", $securePassword)

    # Create a virtual machine configuration
    $vmNameUbuntu = "$vmNamePrefix-Server"
    $vmConfig = New-AzureRmVMConfig -VMName $vmNameUbuntu -VMSize Standard_D1 | Set-AzureRmVMOperatingSystem -Linux -ComputerName "$vmNamePrefix-server" -Credential $cred -DisablePasswordAuthentication | Set-AzureRmVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 16.04-LTS -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id

    # Configure SSH Keys
    $sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"
    Add-AzureRmVMSshPublicKey -VM $vmconfig -KeyData $sshPublicKey -Path "/home/azureuser/.ssh/authorized_keys"

    # Create the Virtual Machine
    $ubuntuVm = New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig

    # Run configuration script on the VM
    $scriptUri = "https://$storageAccountName.blob.core.windows.net/$scriptStorageContainerName/build-server.sh"
    $serverDns = "$($deploymentName.ToLower() + "-server").$location.cloudapp.azure.com"
    $Settings = @{"fileUris" = @($scriptUri); "commandToExecute" = "./build-server.sh $serverDns"};
    $ProtectedSettings = @{"storageAccountName" = $storageAccountName; "storageAccountKey" = $storageKey};
    Set-AzureRmVMExtension -ResourceGroupName $resourceGroupName -Location $location -VMName $vmNameUbuntu -Name "InstallServer" -Publisher "Microsoft.Azure.Extensions" -Type "customScript" -TypeHandlerVersion "2.0" -Settings $Settings -ProtectedSettings $ProtectedSettings
}
### END CREATE UBUNTU VM


createServerVM

Write-Host "Server VM: $deploymentName-server.$location.cloudapp.azure.com"
Write-Host "------"
Write-Host "When you've finished with this environment, delete it with"
Write-Host "Remove-AzureRmResourceGroup -Name $resourceGroupName"

$endTime = Get-Date
$executionTime = $endTime.Subtract($startTime)
Write-Host "Created $deploymentName in $($executionTime.Hours) hrs $($executionTime.Minutes) mins $($executionTime.Seconds) secs"
