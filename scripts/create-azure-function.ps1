#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Provides cmdlets to create and test Azure Function Apps for ZeppNightscout API token serving.

.DESCRIPTION
    This script defines the Set-ZeppAzureFunction and Test-ZeppAzureFunction cmdlets and can be downloaded and executed directly.
    
    Usage:
    # Direct download and execute
    iex (irm https://raw.githubusercontent.com/iricigor/ZeppNightscout/main/scripts/create-azure-function.ps1)
    Set-ZeppAzureFunction -ResourceGroupName "rg-zepp" -FunctionAppName "func-zepp" -AllowedIpAddress "1.2.3.4"
    Test-ZeppAzureFunction -FunctionUrl "https://func-zepp.azurewebsites.net/api/GetToken?code=abc123"

.NOTES
    This script is optimized for Azure Cloud Shell where Az module is pre-installed.
#>

# Shared helper function for colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Helper function to validate IPv4 address
function Test-IPv4Address {
    param(
        [string]$IpAddress
    )
    
    if ([string]::IsNullOrWhiteSpace($IpAddress)) {
        return $false
    }
    
    # Check format and validate each octet
    if ($IpAddress -match '^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$') {
        $octets = $IpAddress.Split('.')
        foreach ($octet in $octets) {
            $num = [int]$octet
            if ($num -lt 0 -or $num -gt 255) {
                return $false
            }
        }
        return $true
    }
    
    return $false
}

# Helper function to ensure IP address is in CIDR format
function ConvertTo-CIDRFormat {
    param(
        [string]$IpAddress
    )
    
    if ([string]::IsNullOrWhiteSpace($IpAddress)) {
        return $IpAddress
    }
    
    # If already in CIDR format (IP/prefix), validate and return as-is
    # Check for IP address format followed by / and prefix length
    if ($IpAddress -match '^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/(\d{1,2})$') {
        $ip = $Matches[1]
        $prefix = [int]$Matches[2]
        
        # Validate prefix length is 0-32 for IPv4
        if ($prefix -ge 0 -and $prefix -le 32 -and (Test-IPv4Address -IpAddress $ip)) {
            return $IpAddress
        }
    }
    
    # If it's a plain IP address (without /), append /32
    if (Test-IPv4Address -IpAddress $IpAddress) {
        return "$IpAddress/32"
    }
    
    # Return as-is if it's not a valid IP (let Azure handle the error)
    return $IpAddress
}

function Set-ZeppAzureFunction {
    <#
    .SYNOPSIS
        Creates an Azure Function App with a Python HTTP trigger that returns a dummy API token.

    .DESCRIPTION
        This cmdlet creates an Azure Function App with the following features:
        - Python runtime (version 3.11)
        - HTTP trigger function that returns "DUMMY-TOKEN"
        - Automatic IP detection and firewall configuration for Azure Cloud Shell compatibility
        - IP access restrictions to allow access from specific IP addresses
        - Function code editable in the Azure Portal
        - Uses Azure PowerShell (Az module) - designed for Azure Cloud Shell

    .PARAMETER ResourceGroupName
        Name of the Azure Resource Group. Will be created if it doesn't exist.

    .PARAMETER FunctionAppName
        Name of the Azure Function App. Must be globally unique.

    .PARAMETER Location
        Azure region for the resources. Default: eastus

    .PARAMETER AllowedIpAddress
        IP address that will be allowed to access the function. 
        If not specified, your current public IP is automatically detected and used.
        When specified and running in Azure Cloud Shell, both your detected IP and the specified IP will be added.
        Set to "0.0.0.0/0" to allow all IPs (not recommended for production).
        Default: Auto-detected from your current public IP

    .PARAMETER StorageAccountName
        Name of the storage account for the function app. If not provided, will be auto-generated.

    .PARAMETER DisableFunctionAuth
        Disables function-level authentication. When enabled, relies solely on IP firewall for security.
        WARNING: Only use this with proper IP restrictions configured!

    .EXAMPLE
        Set-ZeppAzureFunction -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken"
        
        Creates a function with auto-detected IP restrictions (recommended for Azure Cloud Shell).

    .EXAMPLE
        Set-ZeppAzureFunction -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken" -AllowedIpAddress "203.0.113.10"
        
        Creates a function with specific IP restriction. In Azure Cloud Shell, both the detected IP and 203.0.113.10 will be allowed.

    .EXAMPLE
        Set-ZeppAzureFunction -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken" -Location "westeurope" -DisableFunctionAuth
        
        Creates a function in West Europe with auto-detected IP and no function-level authentication.

    .NOTES
        Prerequisites:
        - Azure PowerShell (Az module) - pre-installed in Azure Cloud Shell
        - User must be logged in to Azure (Connect-AzAccount)
        - User must have permissions to create resources in the subscription
        
        This cmdlet is optimized for Azure Cloud Shell where Az module is pre-installed.
        The script automatically detects your public IP using online services (ifconfig.me, ipify.org, icanhazip.com).
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

    # Auto-detect current public IP address for Azure Cloud Shell compatibility
    Write-ColorOutput "Detecting current public IP address..." "Yellow"
    try {
        # Try multiple services for reliability
        $detectedIp = $null
        $services = @(
            "https://iiric.azurewebsites.net/MyIP",
            "https://ifconfig.me/ip",
            "https://api.ipify.org",
            "https://icanhazip.com"
        )
        
        foreach ($service in $services) {
            try {
                $response = Invoke-RestMethod -Uri $service -TimeoutSec 5 -ErrorAction Stop
                if ($null -ne $response) {
                    $ipCandidate = $response.ToString().Trim()
                    if (Test-IPv4Address -IpAddress $ipCandidate) {
                        $detectedIp = $ipCandidate
                        break
                    }
                }
            } catch {
                # Service failed, try next one
                continue
            }
        }
        
        if ($detectedIp) {
            Write-ColorOutput "✓ Detected public IP: $detectedIp" "Green"
            
            # If AllowedIpAddress is default (0.0.0.0/0), use detected IP
            # Otherwise, ensure detected IP is included
            if ($AllowedIpAddress -eq "0.0.0.0/0") {
                $AllowedIpAddress = ConvertTo-CIDRFormat -IpAddress $detectedIp
                Write-ColorOutput "  Automatically setting IP restriction to detected IP" "Cyan"
            } else {
                # Check if the detected IP is different from the specified one
                if ($AllowedIpAddress -ne $detectedIp) {
                    Write-ColorOutput "  Note: Specified IP ($AllowedIpAddress) differs from detected IP ($detectedIp)" "Yellow"
                    Write-ColorOutput "  Adding both IPs to firewall for Azure Cloud Shell compatibility" "Cyan"
                    # We'll add both IPs later in the IP restriction configuration
                }
            }
        } else {
            Write-ColorOutput "⚠ Could not detect public IP address automatically" "Yellow"
            if ($AllowedIpAddress -eq "0.0.0.0/0") {
                Write-ColorOutput "  Function will be accessible from all IPs (0.0.0.0/0)" "Yellow"
            }
        }
    } catch {
        Write-ColorOutput "⚠ Error detecting public IP: $($_.Exception.Message)" "Yellow"
        if ($AllowedIpAddress -eq "0.0.0.0/0") {
            Write-ColorOutput "  Function will be accessible from all IPs (0.0.0.0/0)" "Yellow"
        }
    }
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
import traceback
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP trigger function that returns a dummy API token.
    
    This function can be edited directly in the Azure Portal.
    Simply navigate to your Function App, select this function,
    and use the Code + Test feature to modify the response.
    """
    try:
        # Log function invocation with detailed request information
        logging.info('=== GetToken Function Invoked ===')
        logging.info(f'Request Method: {req.method}')
        logging.info(f'Request URL: {req.url}')
        
        # Log query parameters (if any)
        try:
            params = dict(req.params)
            # Mask sensitive data in logs (like 'code' parameter)
            if 'code' in params:
                params['code'] = '***REDACTED***'
            logging.info(f'Query Parameters: {params}')
        except Exception as e:
            logging.warning(f'Could not parse query parameters: {str(e)}')
        
        # Log headers (exclude sensitive ones)
        try:
            safe_headers = {}
            for key, value in req.headers.items():
                if key.lower() in ['authorization', 'x-functions-key', 'cookie']:
                    safe_headers[key] = '***REDACTED***'
                else:
                    safe_headers[key] = value
            logging.info(f'Request Headers: {safe_headers}')
        except Exception as e:
            logging.warning(f'Could not parse headers: {str(e)}')
        
        # Log request body (if present)
        try:
            if req.get_body():
                logging.info(f'Request Body Length: {len(req.get_body())} bytes')
        except Exception as e:
            logging.warning(f'Could not read request body: {str(e)}')
        
        logging.info('Generating token response...')
        
        # Prepare the response data
        response_data = {
            "token": "DUMMY-TOKEN",
            "message": "This is a dummy API token for testing purposes"
        }
        
        # Convert to JSON
        response_json = json.dumps(response_data)
        logging.info(f'Response prepared successfully: {len(response_json)} bytes')
        
        # Return the dummy token
        response = func.HttpResponse(
            body=response_json,
            mimetype="application/json",
            status_code=200
        )
        
        logging.info('=== GetToken Function Completed Successfully ===')
        return response
        
    except Exception as e:
        # Comprehensive error logging
        logging.error('=== GetToken Function ERROR ===')
        logging.error(f'Exception Type: {type(e).__name__}')
        logging.error(f'Exception Message: {str(e)}')
        logging.error(f'Traceback: {traceback.format_exc()}')
        
        # Return error response with details
        error_response = {
            "error": "Internal server error",
            "message": str(e),
            "type": type(e).__name__
        }
        
        return func.HttpResponse(
            body=json.dumps(error_response),
            mimetype="application/json",
            status_code=500
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
        logging = @{
            logLevel = @{
                default = "Information"
                Function = "Information"
                Host = "Information"
            }
            applicationInsights = @{
                samplingSettings = @{
                    isEnabled = $true
                    maxTelemetryItemsPerSecond = 20
                }
            }
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
    
    # Deploy using Kudu API zip deployment
    try {
        # Get publishing credentials
        $publishingProfile = Invoke-AzResourceAction `
            -ResourceType "Microsoft.Web/sites/config" `
            -ResourceGroupName $ResourceGroupName `
            -ResourceName "$FunctionAppName/publishingcredentials" `
            -Action list `
            -ApiVersion "2022-03-01" `
            -Force
        
        $username = $publishingProfile.Properties.publishingUserName
        $password = $publishingProfile.Properties.publishingPassword
        
        # Create Basic Auth header
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${username}:${password}"))
        
        # Deploy zip file using Kudu API
        $zipDeployUrl = "https://$FunctionAppName.scm.azurewebsites.net/api/zipdeploy"
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
        }
        
        # Deploy with retry logic
        $maxRetries = 3
        $retryCount = 0
        $deployed = $false
        
        while (-not $deployed -and $retryCount -lt $maxRetries) {
            try {
                Invoke-RestMethod -Uri $zipDeployUrl -Method Post -Headers $headers -InFile $zipPath -ContentType "application/zip" -TimeoutSec 300 | Out-Null
                $deployed = $true
                Write-ColorOutput "✓ Function code deployed" "Green"
            } catch {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Write-ColorOutput "Deployment attempt $retryCount failed, retrying..." "Yellow"
                    Start-Sleep -Seconds 5
                } else {
                    throw
                }
            }
        }
    } catch {
        Write-ColorOutput "Warning: Function deployment may have failed, but the function app is created." "Yellow"
        Write-ColorOutput "You can manually upload the function code through the Azure Portal." "Yellow"
        Write-ColorOutput "Error details: $($_.Exception.Message)" "Red"
    } finally {
        # Clear sensitive credentials from memory
        Remove-Variable -Name username -ErrorAction SilentlyContinue
        Remove-Variable -Name password -ErrorAction SilentlyContinue
        Remove-Variable -Name base64AuthInfo -ErrorAction SilentlyContinue
    }
    
    # Clean up temp files
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
    Write-Host ""

    # Configure IP restrictions
    if ($AllowedIpAddress -ne "0.0.0.0/0") {
        Write-ColorOutput "Configuring IP access restrictions..." "Yellow"
        
        try {
            # Collect all IPs to add to firewall with descriptive names
            $ipRules = @()
            
            # Add the specified IP (ensure it's in CIDR format)
            $convertedIp = ConvertTo-CIDRFormat -IpAddress $AllowedIpAddress
            $ipRules += @{
                IpAddress = $convertedIp
                RuleName = "AllowSpecifiedIP"
                Description = "Specified IP"
            }
            Write-ColorOutput "  Adding specified IP: $convertedIp" "White"
            
            # If we detected a different IP earlier, add it too for Azure Cloud Shell compatibility
            if ($detectedIp -and $detectedIp -ne $AllowedIpAddress -and (Test-IPv4Address -IpAddress $detectedIp)) {
                $convertedDetectedIp = ConvertTo-CIDRFormat -IpAddress $detectedIp
                $ipRules += @{
                    IpAddress = $convertedDetectedIp
                    RuleName = "AllowDetectedIP"
                    Description = "Auto-detected IP (Azure Cloud Shell)"
                }
                Write-ColorOutput "  Adding detected IP: $convertedDetectedIp (for Azure Cloud Shell)" "White"
            }
            
            # Remove any existing rules with our names (including legacy names for backwards compatibility)
            $existingRules = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ErrorAction SilentlyContinue
            if ($existingRules -and $existingRules.MainSiteAccessRestrictions) {
                $ruleNamesToRemove = @("AllowSpecifiedIP", "AllowDetectedIP", "AllowSpecificIP")
                foreach ($rule in $existingRules.MainSiteAccessRestrictions) {
                    if ($rule.RuleName -in $ruleNamesToRemove -or $rule.RuleName -like "AllowSpecificIP_*") {
                        Remove-AzWebAppAccessRestrictionRule `
                            -ResourceGroupName $ResourceGroupName `
                            -WebAppName $FunctionAppName `
                            -Name $rule.RuleName `
                            -ErrorAction SilentlyContinue | Out-Null
                    }
                }
            }
            
            # Add IP restriction rules
            $priority = 100
            foreach ($ipRule in $ipRules) {
                Add-AzWebAppAccessRestrictionRule `
                    -ResourceGroupName $ResourceGroupName `
                    -WebAppName $FunctionAppName `
                    -Name $ipRule.RuleName `
                    -Action Allow `
                    -IpAddress $ipRule.IpAddress `
                    -Priority $priority | Out-Null
                $priority += 10
            }
            
            Write-ColorOutput "✓ IP access restrictions configured for $($ipRules.Count) IP(s)" "Green"
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

function Test-ZeppAzureFunction {
    <#
    .SYNOPSIS
        Tests a deployed Azure Function to verify it returns the expected API token response.

    .DESCRIPTION
        This cmdlet tests a deployed Azure Function by making an HTTP request to the function URL
        and validating that it returns the expected JSON payload with a token field.
        
        The function validates:
        - HTTP connectivity to the function endpoint
        - Valid JSON response format
        - Presence of required 'token' field
        - Optional validation of 'message' field

    .PARAMETER FunctionUrl
        The complete URL of the Azure Function to test, including any query parameters (like the code parameter).
        Example: https://zeppnsapi.azurewebsites.net/api/GetToken?code=your-function-key

    .PARAMETER ExpectedToken
        Optional. The expected token value to verify. If not provided, only checks that a token field exists.

    .EXAMPLE
        Test-ZeppAzureFunction -FunctionUrl "https://zeppnsapi.azurewebsites.net/api/GetToken?code=abc123"
        
        Tests the function and validates it returns a JSON response with a token field.

    .EXAMPLE
        Test-ZeppAzureFunction -FunctionUrl "https://zeppnsapi.azurewebsites.net/api/GetToken?code=abc123" -ExpectedToken "DUMMY-TOKEN"
        
        Tests the function and validates it returns "DUMMY-TOKEN" as the token value.

    .NOTES
        This cmdlet uses Invoke-RestMethod to make HTTP requests.
        Ensure you have network connectivity to the Azure Function endpoint.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FunctionUrl,

        [Parameter(Mandatory = $false)]
        [string]$ExpectedToken
    )

    # Set error action preference
    $ErrorActionPreference = "Stop"

    try {
        Write-ColorOutput "================================================" "Cyan"
        Write-ColorOutput "  Azure Function Test" "Cyan"
        Write-ColorOutput "================================================" "Cyan"
        Write-Host ""

        # Validate URL format
        Write-ColorOutput "Validating function URL..." "Yellow"
        if ($FunctionUrl -notmatch '^https?://') {
            throw "Function URL must start with http:// or https://"
        }
        Write-ColorOutput "✓ URL format is valid" "Green"
        Write-Host ""

        # Make HTTP request to the function
        Write-ColorOutput "Testing HTTP connectivity..." "Yellow"
        Write-ColorOutput "URL: $FunctionUrl" "White"
        
        try {
            $response = Invoke-RestMethod -Uri $FunctionUrl -ErrorAction Stop
        } catch {
            Write-ColorOutput "✗ Failed to connect to the function" "Red"
            Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
            
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
                Write-ColorOutput "HTTP Status Code: $statusCode" "Red"
            }
            
            throw "Failed to connect to Azure Function"
        }
        
        Write-ColorOutput "✓ Successfully connected to function" "Green"
        Write-Host ""

        # Validate response structure
        Write-ColorOutput "Validating response structure..." "Yellow"
        
        # Check if response is an object (PowerShell converts JSON to PSCustomObject)
        if ($null -eq $response -or $response -eq '') {
            throw "Response is empty or null"
        }
        Write-ColorOutput "✓ Response is not empty" "Green"
        
        # Check for token field
        if (-not ($response.PSObject.Properties.Name -contains "token")) {
            throw "Response does not contain required 'token' field"
        }
        Write-ColorOutput "✓ Response contains 'token' field" "Green"
        
        $tokenValue = if ($null -eq $response.token) { '<null>' } else { $response.token }
        Write-ColorOutput "  Token value: $tokenValue" "White"
        
        # Check for message field (optional but expected)
        if ($response.PSObject.Properties.Name -contains "message") {
            Write-ColorOutput "✓ Response contains 'message' field" "Green"
            Write-ColorOutput "  Message: $($response.message)" "White"
        } else {
            Write-ColorOutput "⚠ Response does not contain 'message' field (optional)" "Yellow"
        }
        Write-Host ""

        # Validate expected token if provided
        if ($ExpectedToken) {
            Write-ColorOutput "Validating token value..." "Yellow"
            if ($tokenValue -eq $ExpectedToken) {
                Write-ColorOutput "✓ Token matches expected value: $ExpectedToken" "Green"
            } else {
                Write-ColorOutput "✗ Token mismatch!" "Red"
                Write-ColorOutput "  Expected: $ExpectedToken" "Red"
                Write-ColorOutput "  Actual:   $tokenValue" "Red"
                throw "Token value does not match expected value"
            }
            Write-Host ""
        }

        # Success summary
        Write-ColorOutput "================================================" "Cyan"
        Write-ColorOutput "  Test Completed Successfully! ✓" "Green"
        Write-ColorOutput "================================================" "Cyan"
        Write-Host ""
        Write-ColorOutput "Summary:" "Cyan"
        Write-ColorOutput "  Function URL: $FunctionUrl" "White"
        Write-ColorOutput "  Status: Passed ✓" "Green"
        Write-ColorOutput "  Token: $tokenValue" "White"
        if ($response.message) {
            Write-ColorOutput "  Message: $($response.message)" "White"
        }
        Write-Host ""

        return $true

    } catch {
        Write-ColorOutput "" "Red"
        Write-ColorOutput "================================================" "Red"
        Write-ColorOutput "  TEST FAILED: $($_.Exception.Message)" "Red"
        Write-ColorOutput "================================================" "Red"
        Write-Host ""
        return $false
    }
}

# Display usage information when script is loaded (only in interactive sessions)
if ([Environment]::UserInteractive -and -not $PSBoundParameters.Count) {
    Write-Host ""
    Write-Host "✓ Azure Function cmdlets loaded successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Available cmdlets:" -ForegroundColor Cyan
    Write-Host "  1. Set-ZeppAzureFunction  - Create Azure Function" -ForegroundColor White
    Write-Host "  2. Test-ZeppAzureFunction - Test Azure Function" -ForegroundColor White
    Write-Host ""
    Write-Host "Usage examples:" -ForegroundColor Cyan
    Write-Host "  Set-ZeppAzureFunction -ResourceGroupName 'rg-zepp' -FunctionAppName 'func-zepp' -AllowedIpAddress '1.2.3.4'" -ForegroundColor White
    Write-Host "  Test-ZeppAzureFunction -FunctionUrl 'https://func-zepp.azurewebsites.net/api/GetToken?code=abc123'" -ForegroundColor White
    Write-Host ""
    Write-Host "For help:" -ForegroundColor Cyan
    Write-Host "  Get-Help Set-ZeppAzureFunction -Detailed" -ForegroundColor White
    Write-Host "  Get-Help Test-ZeppAzureFunction -Detailed" -ForegroundColor White
    Write-Host ""
}
