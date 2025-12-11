#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Provides cmdlet to create Azure Function App for ZeppNightscout API token serving.

.DESCRIPTION
    This script defines the Set-ZeppAzureFunction cmdlet and can be downloaded and executed directly.
    
    Usage:
    # Direct download and execute
    iex (irm https://raw.githubusercontent.com/iricigor/ZeppNightscout/main/scripts/create-azure-function.ps1)
    Set-ZeppAzureFunction -ResourceGroupName "rg-zepp" -FunctionAppName "func-zepp" -AllowedIpAddress "1.2.3.4"

.NOTES
    This script is optimized for Azure Cloud Shell where Az module is pre-installed.
#>

function Set-ZeppAzureFunction {
    <#
    .SYNOPSIS
        Creates an Azure Function App with a Python HTTP trigger that returns a dummy API token.

    .DESCRIPTION
        This cmdlet creates an Azure Function App with the following features:
        - Python runtime (version 3.11)
        - HTTP trigger function that returns "DUMMY-TOKEN"
        - IP access restrictions to allow access from a specific IP address
        - Function code editable in the Azure Portal
        - Uses Azure PowerShell (Az module) - designed for Azure Cloud Shell

    .PARAMETER ResourceGroupName
        Name of the Azure Resource Group. Will be created if it doesn't exist.

    .PARAMETER FunctionAppName
        Name of the Azure Function App. Must be globally unique.

    .PARAMETER Location
        Azure region for the resources. Default: eastus

    .PARAMETER AllowedIpAddress
        IP address that will be allowed to access the function. Default: 0.0.0.0/0 (all IPs)

    .PARAMETER StorageAccountName
        Name of the storage account for the function app. If not provided, will be auto-generated.

    .PARAMETER DisableFunctionAuth
        Disables function-level authentication. When enabled, relies solely on IP firewall for security.
        WARNING: Only use this with proper IP restrictions configured!

    .EXAMPLE
        Set-ZeppAzureFunction -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken" -AllowedIpAddress "203.0.113.10"

    .EXAMPLE
        Set-ZeppAzureFunction -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken" -Location "westeurope" -AllowedIpAddress "203.0.113.10" -DisableFunctionAuth

    .NOTES
        Prerequisites:
        - Azure PowerShell (Az module) - pre-installed in Azure Cloud Shell
        - User must be logged in to Azure (Connect-AzAccount)
        - User must have permissions to create resources in the subscription
        
        This cmdlet is optimized for Azure Cloud Shell where Az module is pre-installed.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$FunctionAppName,

        [Parameter(Mandatory = $false)]
        [string]$Location = "eastus",

        [Parameter(Mandatory = $false)]
        [string]$AllowedIpAddress = "0.0.0.0/0",

        [Parameter(Mandatory = $false)]
        [string]$StorageAccountName,

        [Parameter(Mandatory = $false)]
        [switch]$DisableFunctionAuth
    )

    # Set error action preference
    $ErrorActionPreference = "Stop"

    # Function to write colored output
    function Write-ColorOutput {
        param(
            [string]$Message,
            [string]$Color = "White"
        )
        Write-Host $Message -ForegroundColor $Color
    }

# Main script execution
try {
    Write-ColorOutput "================================================" "Cyan"
    Write-ColorOutput "  Azure Function App Creation Script" "Cyan"
    Write-ColorOutput "================================================" "Cyan"
    Write-Host ""

    # Check if Az module is available
    Write-ColorOutput "Checking prerequisites..." "Yellow"
    if (-not (Get-Module -ListAvailable -Name Az.Functions)) {
        Write-ColorOutput "Az.Functions module not found. Installing..." "Yellow"
        Install-Module -Name Az.Functions -Force -AllowClobber -Scope CurrentUser
    }
    if (-not (Get-Module -ListAvailable -Name Az.Resources)) {
        Write-ColorOutput "Az.Resources module not found. Installing..." "Yellow"
        Install-Module -Name Az.Resources -Force -AllowClobber -Scope CurrentUser
    }
    if (-not (Get-Module -ListAvailable -Name Az.Storage)) {
        Write-ColorOutput "Az.Storage module not found. Installing..." "Yellow"
        Install-Module -Name Az.Storage -Force -AllowClobber -Scope CurrentUser
    }
    if (-not (Get-Module -ListAvailable -Name Az.Websites)) {
        Write-ColorOutput "Az.Websites module not found. Installing..." "Yellow"
        Install-Module -Name Az.Websites -Force -AllowClobber -Scope CurrentUser
    }
    
    Write-ColorOutput "✓ Azure PowerShell modules available" "Green"

    # Check if logged in to Azure
    Write-ColorOutput "Checking Azure login status..." "Yellow"
    $context = Get-AzContext
    if (-not $context) {
        throw "Not logged in to Azure. Please run 'Connect-AzAccount' first or use Azure Cloud Shell."
    }
    Write-ColorOutput "✓ Logged in to Azure (Subscription: $($context.Subscription.Name))" "Green"
    Write-Host ""

    # Generate storage account name if not provided
    if (-not $StorageAccountName) {
        # Storage account name must be 3-24 chars, lowercase letters and numbers only
        $randomSuffix = -join ((97..122) | Get-Random -Count 6 | ForEach-Object {[char]$_})
        $StorageAccountName = "stzepptoken$randomSuffix"
        Write-ColorOutput "Generated storage account name: $StorageAccountName" "Yellow"
    }

    # Validate storage account name
    if ($StorageAccountName -notmatch '^[a-z0-9]{3,24}$') {
        throw "Storage account name must be 3-24 characters, lowercase letters and numbers only."
    }

    # Create Resource Group if it doesn't exist
    Write-ColorOutput "Creating/verifying resource group '$ResourceGroupName' in '$Location'..." "Yellow"
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
    }
    Write-ColorOutput "✓ Resource group ready" "Green"
    Write-Host ""

    # Create Storage Account
    Write-ColorOutput "Creating storage account '$StorageAccountName'..." "Yellow"
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
    if (-not $storageAccount) {
        New-AzStorageAccount `
            -ResourceGroupName $ResourceGroupName `
            -Name $StorageAccountName `
            -Location $Location `
            -SkuName Standard_LRS `
            -Kind StorageV2 | Out-Null
        Write-ColorOutput "✓ Storage account created" "Green"
    } else {
        Write-ColorOutput "✓ Storage account already exists" "Green"
    }
    Write-Host ""

    # Determine authentication level
    $authLevel = if ($DisableFunctionAuth) { "anonymous" } else { "function" }
    if ($DisableFunctionAuth) {
        Write-ColorOutput "⚠ Function-level authentication disabled - relying on IP firewall only!" "Yellow"
    }

    # Create Function App with Python runtime
    Write-ColorOutput "Creating Function App '$FunctionAppName' with Python 3.11 runtime..." "Yellow"
    $functionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ErrorAction SilentlyContinue
    if (-not $functionApp) {
        New-AzFunctionApp `
            -Name $FunctionAppName `
            -ResourceGroupName $ResourceGroupName `
            -StorageAccountName $StorageAccountName `
            -Location $Location `
            -Runtime Python `
            -RuntimeVersion 3.11 `
            -FunctionsVersion 4 `
            -OSType Linux | Out-Null
        Write-ColorOutput "✓ Function App created" "Green"
    } else {
        Write-ColorOutput "✓ Function App already exists" "Green"
    }
    Write-Host ""

    # Wait for function app to be fully provisioned
    Write-ColorOutput "Waiting for Function App to be fully provisioned..." "Yellow"
    Start-Sleep -Seconds 30
    Write-ColorOutput "✓ Function App is ready" "Green"
    Write-Host ""

    # Create Python function code directory structure
    Write-ColorOutput "Creating Python function code..." "Yellow"
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "azure-function-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Create function.json for HTTP trigger
    $functionJsonPath = Join-Path $tempDir "function.json"
    $functionJson = @{
        bindings = @(
            @{
                authLevel = $authLevel
                type = "httpTrigger"
                direction = "in"
                name = "req"
                methods = @("get", "post")
            }
            @{
                type = "http"
                direction = "out"
                name = "res"
            }
        )
    } | ConvertTo-Json -Depth 10
    
    Set-Content -Path $functionJsonPath -Value $functionJson -Encoding UTF8
    
    # Create __init__.py with the function code
    $initPyPath = Join-Path $tempDir "__init__.py"
    $pythonCode = @'
import logging
import json
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP trigger function that returns a dummy API token.
    
    This function can be edited directly in the Azure Portal.
    Simply navigate to your Function App, select this function,
    and use the Code + Test feature to modify the response.
    """
    logging.info('Python HTTP trigger function processed a request.')

    # Return the dummy token
    return func.HttpResponse(
        body=json.dumps({
            "token": "DUMMY-TOKEN",
            "message": "This is a dummy API token for testing purposes"
        }),
        mimetype="application/json",
        status_code=200
    )
'@
    
    Set-Content -Path $initPyPath -Value $pythonCode -Encoding UTF8
    
    # Create host.json
    $hostJsonPath = Join-Path (Split-Path $tempDir -Parent) "host.json"
    $hostJson = @{
        version = "2.0"
        extensionBundle = @{
            id = "Microsoft.Azure.Functions.ExtensionBundle"
            version = "[4.*, 5.0.0)"
        }
    } | ConvertTo-Json -Depth 10
    
    Set-Content -Path $hostJsonPath -Value $hostJson -Encoding UTF8
    
    Write-ColorOutput "✓ Function code created locally" "Green"
    Write-Host ""

    # Deploy the function code using zip deploy
    Write-ColorOutput "Deploying function code to Azure..." "Yellow"
    
    # Create a zip file
    $functionName = "GetToken"
    $functionDir = Join-Path $tempDir $functionName
    New-Item -ItemType Directory -Path $functionDir -Force | Out-Null
    Move-Item -Path $functionJsonPath -Destination $functionDir -Force
    Move-Item -Path $initPyPath -Destination $functionDir -Force
    
    # Create requirements.txt
    $requirementsTxt = Join-Path $tempDir "requirements.txt"
    Set-Content -Path $requirementsTxt -Value "azure-functions" -Encoding UTF8
    
    # Move host.json to the right place
    Move-Item -Path $hostJsonPath -Destination $tempDir -Force
    
    # Use timestamp and process ID for unique zip file name to avoid conflicts
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $zipPath = Join-Path ([System.IO.Path]::GetTempPath()) "function-app-$timestamp-$PID.zip"
    
    # Create zip using PowerShell compression
    Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force
    
    # Deploy using Publish-AzWebApp
    try {
        Publish-AzWebApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ArchivePath $zipPath -Force | Out-Null
        Write-ColorOutput "✓ Function code deployed" "Green"
    } catch {
        Write-ColorOutput "Warning: Function deployment may have failed, but the function app is created." "Yellow"
        Write-ColorOutput "You can manually upload the function code through the Azure Portal." "Yellow"
        Write-ColorOutput "Error details: $($_.Exception.Message)" "Red"
    }
    
    # Clean up temp files
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
    Write-Host ""

    # Configure IP restrictions
    if ($AllowedIpAddress -ne "0.0.0.0/0") {
        Write-ColorOutput "Configuring IP access restrictions for $AllowedIpAddress..." "Yellow"
        
        try {
            # Check if IP restriction rule already exists
            $existingRules = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ErrorAction SilentlyContinue
            $ruleExists = $false
            if ($existingRules -and $existingRules.MainSiteAccessRestrictions) {
                $ruleExists = $existingRules.MainSiteAccessRestrictions | Where-Object { $_.RuleName -eq "AllowSpecificIP" }
            }
            
            if ($ruleExists) {
                # Update existing rule by removing and re-adding
                Remove-AzWebAppAccessRestrictionRule `
                    -ResourceGroupName $ResourceGroupName `
                    -WebAppName $FunctionAppName `
                    -Name "AllowSpecificIP" `
                    -ErrorAction SilentlyContinue | Out-Null
            }
            
            # Add IP restriction rule using Add-AzWebAppAccessRestrictionRule
            Add-AzWebAppAccessRestrictionRule `
                -ResourceGroupName $ResourceGroupName `
                -WebAppName $FunctionAppName `
                -Name "AllowSpecificIP" `
                -Action Allow `
                -IpAddress $AllowedIpAddress `
                -Priority 100 | Out-Null
            
            Write-ColorOutput "✓ IP access restrictions configured" "Green"
        } catch {
            Write-ColorOutput "Warning: Failed to configure IP restrictions. You can configure this manually in the Azure Portal." "Yellow"
            Write-ColorOutput "Error details: $($_.Exception.Message)" "Red"
        }
    } else {
        Write-ColorOutput "⚠ No IP restrictions configured - function is accessible from all IPs" "Yellow"
    }
    Write-Host ""

    # Get function URL
    Write-ColorOutput "Retrieving function URL..." "Yellow"
    
    $functionUrl = "https://$FunctionAppName.azurewebsites.net/api/GetToken"
    
    if (-not $DisableFunctionAuth) {
        try {
            # Get function keys using Invoke-AzResourceAction
            $keys = Invoke-AzResourceAction `
                -ResourceType "Microsoft.Web/sites/functions" `
                -ResourceGroupName $ResourceGroupName `
                -ResourceName "$FunctionAppName/GetToken" `
                -Action listkeys `
                -ApiVersion "2022-03-01" `
                -Force
            
            if ($keys.default) {
                $functionUrl = "$functionUrl?code=$($keys.default)"
            }
        } catch {
            Write-ColorOutput "Warning: Could not retrieve function keys. The function was created successfully." "Yellow"
            Write-ColorOutput "You can find the function URL and keys in the Azure Portal." "Yellow"
        }
    }
    
    Write-ColorOutput "================================================" "Cyan"
    Write-ColorOutput "  Deployment Completed Successfully! ✓" "Green"
    Write-ColorOutput "================================================" "Cyan"
    Write-Host ""
    Write-ColorOutput "Resource Group:   $ResourceGroupName" "White"
    Write-ColorOutput "Function App:     $FunctionAppName" "White"
    Write-ColorOutput "Storage Account:  $StorageAccountName" "White"
    Write-ColorOutput "Location:         $Location" "White"
    Write-ColorOutput "Runtime:          Python 3.11" "White"
    Write-ColorOutput "Function Name:    GetToken" "White"
    Write-ColorOutput "Auth Level:       $authLevel" "White"
    if ($AllowedIpAddress -ne "0.0.0.0/0") {
        Write-ColorOutput "Allowed IP:       $AllowedIpAddress" "White"
    }
    Write-Host ""
    Write-ColorOutput "Function URL:" "Cyan"
    Write-ColorOutput $functionUrl "Yellow"
    Write-Host ""
    Write-ColorOutput "To test the function, run:" "Cyan"
    Write-ColorOutput "  curl `"$functionUrl`"" "White"
    Write-Host ""
    Write-ColorOutput "To edit the function in Azure Portal:" "Cyan"
    Write-ColorOutput "  1. Go to https://portal.azure.com" "White"
    Write-ColorOutput "  2. Navigate to your Function App: $FunctionAppName" "White"
    Write-ColorOutput "  3. Select 'Functions' -> 'GetToken' -> 'Code + Test'" "White"
    Write-ColorOutput "  4. Edit __init__.py to change the response" "White"
    Write-Host ""

} catch {
    Write-ColorOutput "" "Red"
    Write-ColorOutput "================================================" "Red"
    Write-ColorOutput "  ERROR: $($_.Exception.Message)" "Red"
    Write-ColorOutput "================================================" "Red"
    Write-Host ""
    throw
}
}

# Display usage information when script is loaded (only in interactive sessions)
if ([Environment]::UserInteractive -and -not $PSBoundParameters.Count) {
    Write-Host ""
    Write-Host "✓ Set-ZeppAzureFunction cmdlet loaded successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  Set-ZeppAzureFunction -ResourceGroupName 'rg-zepp' -FunctionAppName 'func-zepp' -AllowedIpAddress '1.2.3.4'" -ForegroundColor White
    Write-Host ""
    Write-Host "For help:" -ForegroundColor Cyan
    Write-Host "  Get-Help Set-ZeppAzureFunction -Detailed" -ForegroundColor White
    Write-Host ""
}
