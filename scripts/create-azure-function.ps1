#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates an Azure Function App with a Python HTTP trigger that returns a dummy API token.

.DESCRIPTION
    This script creates an Azure Function App with the following features:
    - Python runtime (version 3.11)
    - HTTP trigger function that returns "DUMMY-TOKEN"
    - IP access restrictions to allow access from a specific IP address
    - Function code editable in the Azure Portal

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

.EXAMPLE
    .\create-azure-function.ps1 -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken" -AllowedIpAddress "203.0.113.10"

.EXAMPLE
    .\create-azure-function.ps1 -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken" -Location "westeurope" -AllowedIpAddress "203.0.113.10"

.NOTES
    Prerequisites:
    - Azure CLI must be installed and configured
    - User must be logged in to Azure (az login)
    - User must have permissions to create resources in the subscription
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
    [string]$StorageAccountName
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

    # Check if Azure CLI is installed
    Write-ColorOutput "Checking prerequisites..." "Yellow"
    $azVersion = az version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI is not installed or not in PATH. Please install from: https://learn.microsoft.com/cli/azure/install-azure-cli"
    }
    Write-ColorOutput "✓ Azure CLI is installed" "Green"

    # Check if logged in to Azure
    Write-ColorOutput "Checking Azure login status..." "Yellow"
    $accountInfo = az account show 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Not logged in to Azure. Please run 'az login' first."
    }
    Write-ColorOutput "✓ Logged in to Azure" "Green"
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
    az group create --name $ResourceGroupName --location $Location | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create resource group"
    }
    Write-ColorOutput "✓ Resource group ready" "Green"
    Write-Host ""

    # Create Storage Account
    Write-ColorOutput "Creating storage account '$StorageAccountName'..." "Yellow"
    az storage account create `
        --name $StorageAccountName `
        --location $Location `
        --resource-group $ResourceGroupName `
        --sku Standard_LRS `
        --kind StorageV2 | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create storage account"
    }
    Write-ColorOutput "✓ Storage account created" "Green"
    Write-Host ""

    # Create Function App with Python runtime
    Write-ColorOutput "Creating Function App '$FunctionAppName' with Python 3.11 runtime..." "Yellow"
    az functionapp create `
        --name $FunctionAppName `
        --resource-group $ResourceGroupName `
        --storage-account $StorageAccountName `
        --consumption-plan-location $Location `
        --runtime python `
        --runtime-version 3.11 `
        --functions-version 4 `
        --os-type Linux | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create function app"
    }
    Write-ColorOutput "✓ Function App created" "Green"
    Write-Host ""

    # Wait for function app to be fully provisioned
    Write-ColorOutput "Waiting for Function App to be fully provisioned..." "Yellow"
    Start-Sleep -Seconds 30
    Write-ColorOutput "✓ Function App is ready" "Green"
    Write-Host ""

    # Create Python function code directory structure
    Write-ColorOutput "Creating Python function code..." "Yellow"
    $tempDir = Join-Path $env:TEMP "azure-function-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Create function.json for HTTP trigger
    $functionJsonPath = Join-Path $tempDir "function.json"
    $functionJson = @{
        bindings = @(
            @{
                authLevel = "function"
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
    $zipPath = Join-Path $env:TEMP "function-app-$timestamp-$PID.zip"
    
    # Create zip using PowerShell compression
    Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force
    
    # Deploy using az functionapp deployment
    az functionapp deployment source config-zip `
        --resource-group $ResourceGroupName `
        --name $FunctionAppName `
        --src $zipPath | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Warning: Function deployment may have failed, but the function app is created." "Yellow"
        Write-ColorOutput "You can manually upload the function code through the Azure Portal." "Yellow"
    } else {
        Write-ColorOutput "✓ Function code deployed" "Green"
    }
    
    # Clean up temp files
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
    Write-Host ""

    # Configure IP restrictions
    if ($AllowedIpAddress -ne "0.0.0.0/0") {
        Write-ColorOutput "Configuring IP access restrictions for $AllowedIpAddress..." "Yellow"
        
        # Add IP restriction rule
        az functionapp config access-restriction add `
            --resource-group $ResourceGroupName `
            --name $FunctionAppName `
            --rule-name "AllowSpecificIP" `
            --action Allow `
            --ip-address $AllowedIpAddress `
            --priority 100 | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Warning: Failed to configure IP restrictions. You can configure this manually in the Azure Portal." "Yellow"
        } else {
            Write-ColorOutput "✓ IP access restrictions configured" "Green"
        }
    } else {
        Write-ColorOutput "⚠ No IP restrictions configured - function is accessible from all IPs" "Yellow"
    }
    Write-Host ""

    # Get function URL
    Write-ColorOutput "Retrieving function URL..." "Yellow"
    $functionKeysJson = az functionapp function keys list `
        --resource-group $ResourceGroupName `
        --name $FunctionAppName `
        --function-name GetToken 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Warning: Could not retrieve function keys. The function was created successfully." "Yellow"
        Write-ColorOutput "You can find the function URL in the Azure Portal." "Yellow"
        $functionUrl = "https://$FunctionAppName.azurewebsites.net/api/GetToken"
    } else {
        $functionKeys = $functionKeysJson | ConvertFrom-Json
        $defaultKey = $functionKeys.default
        $functionUrl = "https://$FunctionAppName.azurewebsites.net/api/GetToken?code=$defaultKey"
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
    exit 1
}
