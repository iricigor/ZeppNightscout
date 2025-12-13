#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Provides cmdlets to create and test Azure Function Apps for ZeppNightscout API token serving.

.DESCRIPTION
    This script loads cmdlets for managing Azure Functions for ZeppNightscout:
    - Set-ZeppAzureFunction: Creates Azure Function App
    - Test-ZeppAzureFunction: Tests Azure Function
    - Update-ZeppAzureToken: Securely updates the API token
    - Get-ZeppConfig: Retrieves saved configuration
    - Test-ZeppConfig: Validates saved configuration
    
    When run from repository, loads functions from separate files in functions/ directory.
    When downloaded directly (via irm), includes all functions inline for backwards compatibility.
    
    Usage:
    # Direct download and execute
    iex (irm https://raw.githubusercontent.com/iricigor/ZeppNightscout/main/scripts/create-azure-function.ps1)
    Set-ZeppAzureFunction -ResourceGroupName "rg-zepp" -FunctionAppName "func-zepp" -SaveConfig
    Update-ZeppAzureToken -LoadConfig

.NOTES
    This script is optimized for Azure Cloud Shell where Az module is pre-installed.
#>

# Determine the script directory
$scriptDir = if ($PSScriptRoot) {
    $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
    # Fallback for when script is executed via dot-sourcing or certain PowerShell hosts
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    # When executed via iex/irm, we don't have a script directory
    $null
}

# Load helper functions first (only if we have a script directory)
$functionsDir = if ($scriptDir) {
    Join-Path $scriptDir "functions"
} else {
    $null
}

# Check if we're running from repository (functions directory exists)
if ($functionsDir -and (Test-Path $functionsDir)) {
    # Load functions from separate files when running from repository
    $functionFiles = @(
        "Helper-Functions.ps1",
        "Get-ZeppConfig.ps1",
        "Test-ZeppConfig.ps1",
        "Set-ZeppAzureFunction.ps1",
        "Test-ZeppAzureFunction.ps1",
        "Update-ZeppAzureToken.ps1"
    )

    foreach ($file in $functionFiles) {
        $filePath = Join-Path $functionsDir $file
        if (Test-Path $filePath) {
            . $filePath
        } else {
            Write-Warning "Function file not found: $filePath"
        }
    }
} else {
    # Running via irm or functions dir not available - load embedded functions
    # This maintains backward compatibility
    
    # Shared helper function for colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Helper function to get config file path
function Get-ConfigFilePath {
    param(
        [string]$ConfigName = "zepp-azure-config"
    )
    
    # Use script directory if available, otherwise use user's home directory
    $configDir = if ($PSScriptRoot) {
        $PSScriptRoot
    } elseif ($env:HOME) {
        # Unix/Linux/macOS
        $env:HOME
    } elseif ($env:USERPROFILE) {
        # Windows
        $env:USERPROFILE
    } else {
        # Fallback to current directory
        $PWD.Path
    }
    
    return Join-Path $configDir "$ConfigName.json"
}

# Internal helper function to save configuration
function SaveZeppConfigInternal {
    param(
        [hashtable]$Config,
        [string]$ConfigPath
    )
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
        Write-ColorOutput "✓ Configuration saved to: $ConfigPath" "Green"
        return $true
    } catch {
        Write-ColorOutput "⚠ Failed to save configuration: $($_.Exception.Message)" "Yellow"
        return $false
    }
}

# Internal helper function to load configuration
function LoadZeppConfigInternal {
    param(
        [string]$ConfigPath
    )
    
    try {
        if (Test-Path $ConfigPath) {
            $config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
            Write-ColorOutput "✓ Configuration loaded from: $ConfigPath" "Green"
            
            # Convert PSCustomObject to hashtable for easier manipulation
            $hashtable = @{}
            $config.PSObject.Properties | ForEach-Object {
                $hashtable[$_.Name] = $_.Value
            }
            
            return $hashtable
        } else {
            Write-ColorOutput "⚠ Configuration file not found: $ConfigPath" "Yellow"
            return $null
        }
    } catch {
        Write-ColorOutput "⚠ Failed to load configuration: $($_.Exception.Message)" "Yellow"
        return $null
    }
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
        - Configuration save/load support for easier re-deployment

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

    .PARAMETER SaveConfig
        Saves the provided configuration to a local file for later reuse with -LoadConfig.

    .PARAMETER LoadConfig
        Loads configuration from a previously saved file (created with -SaveConfig).

    .EXAMPLE
        Set-ZeppAzureFunction -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken"
        
        Creates a function with auto-detected IP restrictions (recommended for Azure Cloud Shell).

    .EXAMPLE
        Set-ZeppAzureFunction -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken" -AllowedIpAddress "203.0.113.10"
        
        Creates a function with specific IP restriction. In Azure Cloud Shell, both the detected IP and 203.0.113.10 will be allowed.

    .EXAMPLE
        Set-ZeppAzureFunction -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken" -SaveConfig
        
        Creates a function and saves the configuration for later reuse.

    .EXAMPLE
        Set-ZeppAzureFunction -LoadConfig
        
        Creates a function using previously saved configuration.

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

    [CmdletBinding(DefaultParameterSetName = "Direct")]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Direct")]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true, ParameterSetName = "Direct")]
        [string]$FunctionAppName,

        [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
        [string]$Location = "eastus",

        [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
        [string]$AllowedIpAddress = "0.0.0.0/0",

        [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
        [string]$StorageAccountName,

        [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
        [switch]$DisableFunctionAuth,

        [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
        [switch]$SaveConfig,

        [Parameter(Mandatory = $true, ParameterSetName = "LoadConfig")]
        [switch]$LoadConfig
    )

    # Set error action preference
    $ErrorActionPreference = "Stop"

    # Get config file path
    $configPath = Get-ConfigFilePath

    # Load configuration if requested
    if ($LoadConfig) {
        Write-ColorOutput "Loading configuration from file..." "Yellow"
        $loadedConfig = LoadZeppConfigInternal -ConfigPath $configPath
        
        if ($null -eq $loadedConfig) {
            throw "Failed to load configuration. Please run Set-ZeppAzureFunction with parameters and -SaveConfig first."
        }
        
        # Apply loaded configuration
        $ResourceGroupName = $loadedConfig.ResourceGroupName
        $FunctionAppName = $loadedConfig.FunctionAppName
        $Location = if ($loadedConfig.Location) { $loadedConfig.Location } else { "eastus" }
        $AllowedIpAddress = if ($loadedConfig.AllowedIpAddress) { $loadedConfig.AllowedIpAddress } else { "0.0.0.0/0" }
        $StorageAccountName = $loadedConfig.StorageAccountName
        $DisableFunctionAuth = [bool]$loadedConfig.DisableFunctionAuth
        
        Write-Host ""
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
    
    # Try to locate the template file first
    $functionJsonContent = $null
    if ($PSCommandPath) {
        $scriptDir = Split-Path -Parent $PSCommandPath
        $templatePath = Join-Path $scriptDir "azure-function-template" "function.json"
        
        if (Test-Path $templatePath) {
            Write-ColorOutput "  Reading function.json from template: $templatePath" "White"
            $functionJsonContent = Get-Content -Path $templatePath -Raw -Encoding UTF8
            
            # Parse JSON to modify authLevel if needed
            $functionJson = $functionJsonContent | ConvertFrom-Json
            $functionJson.bindings[0].authLevel = $authLevel
            $functionJsonContent = $functionJson | ConvertTo-Json -Depth 10
            
            Set-Content -Path $functionJsonPath -Value $functionJsonContent -Encoding UTF8
        }
    }
    
    # If template not found locally, download from GitHub main branch
    if (-not $functionJsonContent) {
        Write-ColorOutput "  Downloading function.json from GitHub main branch..." "Yellow"
        $githubUrl = "https://raw.githubusercontent.com/iricigor/ZeppNightscout/main/scripts/azure-function-template/function.json"
        
        try {
            $functionJson = Invoke-RestMethod -Uri $githubUrl -TimeoutSec 10 -ErrorAction Stop
            
            # Modify authLevel if needed
            $functionJson.bindings[0].authLevel = $authLevel
            $functionJsonContent = $functionJson | ConvertTo-Json -Depth 10
            
            Set-Content -Path $functionJsonPath -Value $functionJsonContent -Encoding UTF8
            Write-ColorOutput "  ✓ Downloaded and configured function.json from main branch" "Green"
        } catch {
            Write-ColorOutput "  Warning: Could not download template from GitHub: $($_.Exception.Message)" "Yellow"
            Write-ColorOutput "  Using embedded fallback (this may be outdated)" "Yellow"
            
            # Final fallback: generate inline (for backwards compatibility)
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
        }
    }
    
    # Create __init__.py with the function code
    # Read the Python code from the separate template file
    $initPyPath = Join-Path $tempDir "__init__.py"
    
    # Try to locate the template file (handles both normal execution and direct download scenarios)
    $pythonCode = $null
    if ($PSCommandPath) {
        $scriptDir = Split-Path -Parent $PSCommandPath
        $templatePath = Join-Path $scriptDir "azure-function-template" "__init__.py"
        
        if (Test-Path $templatePath) {
            Write-ColorOutput "  Reading Python code from template: $templatePath" "White"
            $pythonCode = Get-Content -Path $templatePath -Raw -Encoding UTF8
        }
    }
    
    # If template not found locally, download from GitHub main branch
    if (-not $pythonCode) {
        Write-ColorOutput "  Downloading __init__.py from GitHub main branch..." "Yellow"
        $githubUrl = "https://raw.githubusercontent.com/iricigor/ZeppNightscout/main/scripts/azure-function-template/__init__.py"
        
        try {
            $pythonCode = Invoke-RestMethod -Uri $githubUrl -TimeoutSec 10 -ErrorAction Stop
            Write-ColorOutput "  ✓ Downloaded __init__.py from main branch" "Green"
        } catch {
            Write-ColorOutput "  Warning: Could not download template from GitHub: $($_.Exception.Message)" "Yellow"
            Write-ColorOutput "  Using embedded fallback (this may be outdated)" "Yellow"
            
            # Final fallback: use embedded code (for backwards compatibility, e.g., when downloaded via irm)
            $pythonCode = @'
import logging
import json
import traceback
import azure.functions as func

# Configuration constants
MAX_BODY_LOG_SIZE = 1024 * 1024  # 1MB
SENSITIVE_PARAM_NAMES = {'code', 'key', 'token', 'secret', 'password', 'api_key', 'apikey', 'auth'}
SENSITIVE_HEADER_NAMES = {'authorization', 'x-functions-key', 'cookie'}

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
            # Mask sensitive data in logs (using set for O(1) lookup performance)
            for param_name in params:
                param_name_lower = param_name.lower()
                if param_name_lower in SENSITIVE_PARAM_NAMES:
                    params[param_name] = '***REDACTED***'
            logging.info(f'Query Parameters: {params}')
        except Exception as e:
            logging.warning(f'Could not parse query parameters: {str(e)}')
        
        # Log headers (exclude sensitive ones - using set for O(1) lookup performance)
        try:
            safe_headers = {}
            for key, value in req.headers.items():
                key_lower = key.lower()
                if key_lower in SENSITIVE_HEADER_NAMES:
                    safe_headers[key] = '***REDACTED***'
                else:
                    safe_headers[key] = value
            logging.info(f'Request Headers: {safe_headers}')
        except Exception as e:
            logging.warning(f'Could not parse headers: {str(e)}')
        
        # Log request body (if present, with size limit protection)
        try:
            body = req.get_body()
            if body:
                body_len = len(body)
                # Protect against logging very large bodies
                if body_len > MAX_BODY_LOG_SIZE:
                    logging.info(f'Request Body Length: {body_len} bytes (too large for detailed logging)')
                else:
                    logging.info(f'Request Body Length: {body_len} bytes')
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
        
        # Return generic error response (detailed error info is in logs only)
        error_response = {
            "error": "Internal server error",
            "message": "An error occurred while processing your request. Please check the function logs for details."
        }
        
        return func.HttpResponse(
            body=json.dumps(error_response),
            mimetype="application/json",
            status_code=500
        )
'@
    }
    
    Set-Content -Path $initPyPath -Value $pythonCode -Encoding UTF8
    
    # Create host.json
    $hostJsonPath = Join-Path (Split-Path $tempDir -Parent) "host.json"
    
    # Try to locate the template file first
    $hostJsonContent = $null
    if ($PSCommandPath) {
        $scriptDir = Split-Path -Parent $PSCommandPath
        $templatePath = Join-Path $scriptDir "azure-function-template" "host.json"
        
        if (Test-Path $templatePath) {
            Write-ColorOutput "  Reading host.json from template: $templatePath" "White"
            Copy-Item -Path $templatePath -Destination $hostJsonPath -Force
            $hostJsonContent = "loaded"
        }
    }
    
    # If template not found locally, download from GitHub main branch
    if (-not $hostJsonContent) {
        Write-ColorOutput "  Downloading host.json from GitHub main branch..." "Yellow"
        $githubUrl = "https://raw.githubusercontent.com/iricigor/ZeppNightscout/main/scripts/azure-function-template/host.json"
        
        try {
            $hostJson = Invoke-RestMethod -Uri $githubUrl -TimeoutSec 10 -ErrorAction Stop
            $hostJsonContent = $hostJson | ConvertTo-Json -Depth 10
            Set-Content -Path $hostJsonPath -Value $hostJsonContent -Encoding UTF8
            Write-ColorOutput "  ✓ Downloaded host.json from main branch" "Green"
        } catch {
            Write-ColorOutput "  Warning: Could not download template from GitHub: $($_.Exception.Message)" "Yellow"
            Write-ColorOutput "  Using embedded fallback (this may be outdated)" "Yellow"
            
            # Final fallback: generate inline
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
        }
    }
    
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

    # Save configuration if requested
    if ($SaveConfig) {
        Write-Host ""
        Write-ColorOutput "Saving configuration..." "Yellow"
        $configToSave = @{
            ResourceGroupName = $ResourceGroupName
            FunctionAppName = $FunctionAppName
            Location = $Location
            AllowedIpAddress = $AllowedIpAddress
            StorageAccountName = $StorageAccountName
            DisableFunctionAuth = [bool]$DisableFunctionAuth
        }
        
        SaveZeppConfigInternal -Config $configToSave -ConfigPath $configPath
        Write-Host ""
    }

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

    .PARAMETER LoadConfig
        Loads configuration from a previously saved file (created with Set-ZeppAzureFunction -SaveConfig)
        and constructs the function URL automatically.

    .EXAMPLE
        Test-ZeppAzureFunction -FunctionUrl "https://zeppnsapi.azurewebsites.net/api/GetToken?code=abc123"
        
        Tests the function and validates it returns a JSON response with a token field.

    .EXAMPLE
        Test-ZeppAzureFunction -FunctionUrl "https://zeppnsapi.azurewebsites.net/api/GetToken?code=abc123" -ExpectedToken "DUMMY-TOKEN"
        
        Tests the function and validates it returns "DUMMY-TOKEN" as the token value.

    .EXAMPLE
        Test-ZeppAzureFunction -LoadConfig
        
        Tests the function using configuration loaded from a previously saved file.

    .NOTES
        This cmdlet uses Invoke-RestMethod to make HTTP requests.
        Ensure you have network connectivity to the Azure Function endpoint.
    #>

    [CmdletBinding(DefaultParameterSetName = "Direct")]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Direct")]
        [string]$FunctionUrl,

        [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
        [string]$ExpectedToken,

        [Parameter(Mandatory = $true, ParameterSetName = "LoadConfig")]
        [switch]$LoadConfig
    )

    # Set error action preference
    $ErrorActionPreference = "Stop"

    # Get config file path
    $configPath = Get-ConfigFilePath

    # Load configuration if requested
    if ($LoadConfig) {
        Write-ColorOutput "Loading configuration from file..." "Yellow"
        $loadedConfig = LoadZeppConfigInternal -ConfigPath $configPath
        
        if ($null -eq $loadedConfig) {
            throw "Failed to load configuration. Please run Set-ZeppAzureFunction with parameters and -SaveConfig first."
        }
        
        # Build function URL from saved configuration
        if (-not $loadedConfig.FunctionAppName) {
            throw "Configuration file does not contain FunctionAppName."
        }
        
        # Validate FunctionAppName format (alphanumeric and hyphens only)
        if ($loadedConfig.FunctionAppName -notmatch '^[a-zA-Z0-9\-]+$') {
            throw "Invalid FunctionAppName in configuration: contains invalid characters."
        }
        
        $FunctionUrl = "https://$($loadedConfig.FunctionAppName).azurewebsites.net/api/GetToken"
        
        Write-ColorOutput "✓ Function URL constructed from config: $FunctionUrl" "Green"
        Write-Host ""
    }

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

function Update-ZeppAzureToken {
    <#
    .SYNOPSIS
        Securely updates the API token in an Azure Function without portal access.

    .DESCRIPTION
        This cmdlet allows you to update the API token returned by your Azure Function
        directly from the command line without needing to edit code in the Azure Portal.
        
        The token can be provided as a parameter or entered securely when prompted.
        This is useful when portal editing is disabled or when you want to script token updates.

    .PARAMETER ResourceGroupName
        Name of the Azure Resource Group containing the Function App.

    .PARAMETER FunctionAppName
        Name of the Azure Function App.

    .PARAMETER Token
        The new API token value. If not provided, you will be prompted to enter it securely.

    .PARAMETER Message
        Optional custom message to include in the response. Defaults to a standard message.

    .PARAMETER LoadConfig
        Loads ResourceGroupName and FunctionAppName from saved configuration file.

    .EXAMPLE
        Update-ZeppAzureToken -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken"
        
        Prompts you to securely enter the new token and updates the function.

    .EXAMPLE
        Update-ZeppAzureToken -LoadConfig
        
        Loads configuration from saved file and prompts for the new token (recommended method).

    .EXAMPLE
        Update-ZeppAzureToken -LoadConfig -Token "my-secret-token-abc123" -Message "Production API token"
        
        Updates using saved configuration with specified token and custom message.
        WARNING: Passing tokens as parameters makes them visible in command history and process lists.
        Use the secure prompt method (without -Token parameter) for better security.

    .NOTES
        Prerequisites:
        - Azure PowerShell (Az module) - pre-installed in Azure Cloud Shell
        - User must be logged in to Azure (Connect-AzAccount)
        - User must have permissions to access and update the function
    #>

    [CmdletBinding(DefaultParameterSetName = "Direct")]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Direct")]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true, ParameterSetName = "Direct")]
        [string]$FunctionAppName,

        [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
        [Parameter(Mandatory = $false, ParameterSetName = "LoadConfig")]
        [string]$Token,

        [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
        [Parameter(Mandatory = $false, ParameterSetName = "LoadConfig")]
        [string]$Message = "This is a Nightscout API token",

        [Parameter(Mandatory = $true, ParameterSetName = "LoadConfig")]
        [switch]$LoadConfig
    )

    # Set error action preference
    $ErrorActionPreference = "Stop"

    # Get config file path
    $configPath = Get-ConfigFilePath

    # Load configuration if requested
    if ($LoadConfig) {
        Write-ColorOutput "Loading configuration from file..." "Yellow"
        $loadedConfig = Load-ZeppConfig -ConfigPath $configPath
        
        if ($null -eq $loadedConfig) {
            throw "Failed to load configuration. Please run Set-ZeppAzureFunction with parameters and -SaveConfig first."
        }
        
        # Apply loaded configuration
        $ResourceGroupName = $loadedConfig.ResourceGroupName
        $FunctionAppName = $loadedConfig.FunctionAppName
        
        Write-Host ""
    }

    # Prompt for token if not provided
    if ([string]::IsNullOrWhiteSpace($Token)) {
        Write-Host ""
        Write-ColorOutput "Enter the new API token (input will be hidden):" "Cyan"
        $secureToken = Read-Host -AsSecureString
        
        # Convert secure string to plain text
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
        try {
            $Token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        } finally {
            # Clear sensitive data from memory
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            Remove-Variable -Name BSTR -ErrorAction SilentlyContinue
        }
        
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw "Token cannot be empty. Operation cancelled."
        }
    }

    try {
        Write-ColorOutput "================================================" "Cyan"
        Write-ColorOutput "  Azure Function Token Update" "Cyan"
        Write-ColorOutput "================================================" "Cyan"
        Write-Host ""

        # Check if Az module is available
        Write-ColorOutput "Checking prerequisites..." "Yellow"
        if (-not (Get-Module -ListAvailable -Name Az.Functions)) {
            Write-ColorOutput "Az.Functions module not found. Installing..." "Yellow"
            Install-Module -Name Az.Functions -Force -AllowClobber -Scope CurrentUser
        }

        # Import required modules
        Import-Module Az.Functions -ErrorAction SilentlyContinue
        Write-ColorOutput "✓ Prerequisites ready" "Green"
        Write-Host ""

        # Verify function app exists
        Write-ColorOutput "Verifying Function App '$FunctionAppName'..." "Yellow"
        $functionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ErrorAction SilentlyContinue
        if (-not $functionApp) {
            throw "Function App '$FunctionAppName' not found in resource group '$ResourceGroupName'."
        }
        Write-ColorOutput "✓ Function App verified" "Green"
        Write-Host ""

        # Get publishing credentials
        Write-ColorOutput "Retrieving deployment credentials..." "Yellow"
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
        Write-ColorOutput "✓ Credentials retrieved" "Green"
        Write-Host ""

        # Download current function code
        Write-ColorOutput "Downloading current function code..." "Yellow"
        $vfsUrl = "https://$FunctionAppName.scm.azurewebsites.net/api/vfs/site/wwwroot/GetToken/__init__.py"
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
        }
        
        try {
            $currentCode = Invoke-RestMethod -Uri $vfsUrl -Method Get -Headers $headers
            Write-ColorOutput "✓ Current code downloaded" "Green"
        } catch {
            Write-ColorOutput "Warning: Could not download current code. Will use template instead." "Yellow"
            $currentCode = $null
        }
        Write-Host ""

        # Update the token in the code
        Write-ColorOutput "Updating token value..." "Yellow"
        
        # Escape special characters in token and message for JSON
        # Backslash must be escaped FIRST to avoid double-escaping other characters
        $escapedToken = $Token -replace '\\', '\\\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", '\r' -replace "`t", '\t'
        $escapedMessage = $Message -replace '\\', '\\\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", '\r' -replace "`t", '\t'
        
        if ($currentCode) {
            # Update existing code - preserve everything except the token and message values
            # Regex matches the field name, opening quote, any content (including escaped chars), and closing quote
            # Pattern: [^"\\]* matches non-quote/non-backslash, \\. matches escaped char sequence
            $updatedCode = $currentCode -replace '("token":\s*")[^"\\]*(?:\\.[^"\\]*)*(")', "`${1}$escapedToken`${2}"
            $updatedCode = $updatedCode -replace '("message":\s*")[^"\\]*(?:\\.[^"\\]*)*(")', "`${1}$escapedMessage`${2}"
        } else {
            # Use template code with new token
            # Use single-quoted here-string to avoid variable expansion, then replace placeholders
            $templateCode = @'
import logging
import json
import traceback
import azure.functions as func

# Configuration constants
MAX_BODY_LOG_SIZE = 1024 * 1024  # 1MB
SENSITIVE_PARAM_NAMES = {'code', 'key', 'token', 'secret', 'password', 'api_key', 'apikey', 'auth'}
SENSITIVE_HEADER_NAMES = {'authorization', 'x-functions-key', 'cookie'}

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP trigger function that returns an API token.
    
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
            # Mask sensitive data in logs (using set for O(1) lookup performance)
            for param_name in params:
                param_name_lower = param_name.lower()
                if param_name_lower in SENSITIVE_PARAM_NAMES:
                    params[param_name] = '***REDACTED***'
            logging.info(f'Query Parameters: {params}')
        except Exception as e:
            logging.warning(f'Could not parse query parameters: {str(e)}')
        
        # Log headers (exclude sensitive ones - using set for O(1) lookup performance)
        try:
            safe_headers = {}
            for key, value in req.headers.items():
                key_lower = key.lower()
                if key_lower in SENSITIVE_HEADER_NAMES:
                    safe_headers[key] = '***REDACTED***'
                else:
                    safe_headers[key] = value
            logging.info(f'Request Headers: {safe_headers}')
        except Exception as e:
            logging.warning(f'Could not parse headers: {str(e)}')
        
        # Log request body (if present, with size limit protection)
        try:
            body = req.get_body()
            if body:
                body_len = len(body)
                # Protect against logging very large bodies
                if body_len > MAX_BODY_LOG_SIZE:
                    logging.info(f'Request Body Length: {body_len} bytes (too large for detailed logging)')
                else:
                    logging.info(f'Request Body Length: {body_len} bytes')
        except Exception as e:
            logging.warning(f'Could not read request body: {str(e)}')
        
        logging.info('Generating token response...')
        
        # Prepare the response data
        response_data = {
            "token": "{{TOKEN_PLACEHOLDER}}",
            "message": "{{MESSAGE_PLACEHOLDER}}"
        }
        
        # Convert to JSON
        response_json = json.dumps(response_data)
        logging.info(f'Response prepared successfully: {len(response_json)} bytes')
        
        # Return the token
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
        
        # Return generic error response (detailed error info is in logs only)
        error_response = {
            "error": "Internal server error",
            "message": "An error occurred while processing your request. Please check the function logs for details."
        }
        
        return func.HttpResponse(
            body=json.dumps(error_response),
            mimetype="application/json",
            status_code=500
        )
'@
            # Replace placeholders with actual values
            $updatedCode = $templateCode -replace '\{\{TOKEN_PLACEHOLDER\}\}', $escapedToken
            $updatedCode = $updatedCode -replace '\{\{MESSAGE_PLACEHOLDER\}\}', $escapedMessage
        }
        
        Write-ColorOutput "✓ Token updated in code" "Green"
        Write-Host ""

        # Upload updated code
        Write-ColorOutput "Uploading updated function code..." "Yellow"
        try {
            Invoke-RestMethod -Uri $vfsUrl -Method Put -Headers $headers -Body $updatedCode -ContentType "text/plain" | Out-Null
            Write-ColorOutput "✓ Function code uploaded successfully" "Green"
        } catch {
            throw "Failed to upload updated code: $($_.Exception.Message)"
        }
        Write-Host ""

        # Clear sensitive data from memory
        Remove-Variable -Name Token -ErrorAction SilentlyContinue
        Remove-Variable -Name escapedToken -ErrorAction SilentlyContinue
        Remove-Variable -Name username -ErrorAction SilentlyContinue
        Remove-Variable -Name password -ErrorAction SilentlyContinue
        Remove-Variable -Name base64AuthInfo -ErrorAction SilentlyContinue

        Write-ColorOutput "================================================" "Cyan"
        Write-ColorOutput "  Token Updated Successfully! ✓" "Green"
        Write-ColorOutput "================================================" "Cyan"
        Write-Host ""
        Write-ColorOutput "Resource Group:   $ResourceGroupName" "White"
        Write-ColorOutput "Function App:     $FunctionAppName" "White"
        Write-ColorOutput "Function Name:    GetToken" "White"
        Write-Host ""
        Write-ColorOutput "The token has been updated in your Azure Function." "Cyan"
        Write-ColorOutput "Changes take effect immediately - no restart required." "Cyan"
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

# Helper function to validate storage account name
function Test-StorageAccountName {
    param(
        [string]$StorageAccountName
    )
    
    if ([string]::IsNullOrWhiteSpace($StorageAccountName)) {
        return $false
    }
    
    # Storage account name must be 3-24 characters, lowercase letters and numbers only
    return $StorageAccountName -match '^[a-z0-9]{3,24}$'
}

function Get-ZeppConfig {
    <#
    .SYNOPSIS
        Retrieves the saved Azure Function deployment configuration.

    .DESCRIPTION
        This cmdlet retrieves the deployment configuration that was previously saved using 
        Set-ZeppAzureFunction with the -SaveConfig parameter. The configuration includes:
        - ResourceGroupName
        - FunctionAppName
        - Location
        - AllowedIpAddress
        - StorageAccountName
        - DisableFunctionAuth

    .PARAMETER ConfigName
        Optional name for the configuration file. Default: zepp-azure-config

    .PARAMETER AsJson
        Returns the configuration as JSON string instead of PowerShell object.

    .EXAMPLE
        Get-ZeppConfig
        
        Retrieves the saved configuration as a PowerShell hashtable.

    .EXAMPLE
        Get-ZeppConfig -AsJson
        
        Retrieves the saved configuration as a JSON string.

    .EXAMPLE
        Get-ZeppConfig -ConfigName "my-custom-config"
        
        Retrieves configuration from a custom-named config file.

    .NOTES
        The configuration file is stored in the same directory as the script, or in the user's 
        home directory if the script directory is not available.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "zepp-azure-config",

        [Parameter(Mandatory = $false)]
        [switch]$AsJson
    )

    # Set error action preference
    $ErrorActionPreference = "Stop"

    try {
        # Get config file path
        $configPath = Get-ConfigFilePath -ConfigName $ConfigName

        Write-ColorOutput "================================================" "Cyan"
        Write-ColorOutput "  Get Zepp Configuration" "Cyan"
        Write-ColorOutput "================================================" "Cyan"
        Write-Host ""

        # Check if config file exists
        if (-not (Test-Path $configPath)) {
            Write-ColorOutput "⚠ Configuration file not found: $configPath" "Yellow"
            Write-Host ""
            Write-ColorOutput "To create a configuration file, run:" "Cyan"
            Write-ColorOutput "  Set-ZeppAzureFunction -ResourceGroupName 'rg-zepp' -FunctionAppName 'func-zepp' -SaveConfig" "White"
            Write-Host ""
            return $null
        }

        # Load configuration
        Write-ColorOutput "Loading configuration from: $configPath" "Yellow"
        $config = LoadZeppConfigInternal -ConfigPath $configPath

        if ($null -eq $config) {
            throw "Failed to load configuration from file."
        }

        Write-Host ""
        Write-ColorOutput "================================================" "Cyan"
        Write-ColorOutput "  Configuration Retrieved Successfully ✓" "Green"
        Write-ColorOutput "================================================" "Cyan"
        Write-Host ""

        # Display configuration
        Write-ColorOutput "Configuration Details:" "Cyan"
        Write-ColorOutput "  Resource Group:       $($config.ResourceGroupName)" "White"
        Write-ColorOutput "  Function App:         $($config.FunctionAppName)" "White"
        Write-ColorOutput "  Location:             $($config.Location)" "White"
        Write-ColorOutput "  Allowed IP:           $($config.AllowedIpAddress)" "White"
        Write-ColorOutput "  Storage Account:      $($config.StorageAccountName)" "White"
        Write-ColorOutput "  Disable Function Auth: $($config.DisableFunctionAuth)" "White"
        Write-Host ""
        Write-ColorOutput "Configuration File: $configPath" "Cyan"
        Write-Host ""

        # Return as JSON if requested
        if ($AsJson) {
            return $config | ConvertTo-Json -Depth 10
        }

        return $config

    } catch {
        Write-ColorOutput "" "Red"
        Write-ColorOutput "================================================" "Red"
        Write-ColorOutput "  ERROR: $($_.Exception.Message)" "Red"
        Write-ColorOutput "================================================" "Red"
        Write-Host ""
        return $null
    }
}

function Test-ZeppConfig {
    <#
    .SYNOPSIS
        Validates the saved Azure Function deployment configuration.

    .DESCRIPTION
        This cmdlet validates the deployment configuration that was previously saved using 
        Set-ZeppAzureFunction with the -SaveConfig parameter. It performs validation on:
        - Configuration file existence and readability
        - Required fields presence (ResourceGroupName, FunctionAppName)
        - IP address format validation
        - Storage account name format validation
        - Field value constraints and best practices

    .PARAMETER ConfigName
        Optional name for the configuration file. Default: zepp-azure-config

    .PARAMETER Detailed
        Shows detailed validation results for each field.

    .EXAMPLE
        Test-ZeppConfig
        
        Validates the saved configuration and returns true/false.

    .EXAMPLE
        Test-ZeppConfig -Detailed
        
        Validates the configuration with detailed output for each check.

    .EXAMPLE
        Test-ZeppConfig -ConfigName "my-custom-config"
        
        Validates a custom-named configuration file.

    .NOTES
        This function is useful for verifying configuration before deployment and 
        troubleshooting configuration issues.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "zepp-azure-config",

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    # Set error action preference
    $ErrorActionPreference = "Stop"

    try {
        # Get config file path
        $configPath = Get-ConfigFilePath -ConfigName $ConfigName

        Write-ColorOutput "================================================" "Cyan"
        Write-ColorOutput "  Test Zepp Configuration" "Cyan"
        Write-ColorOutput "================================================" "Cyan"
        Write-Host ""

        $validationPassed = $true
        $issues = @()

        # Check 1: Configuration file exists
        Write-ColorOutput "Checking configuration file existence..." "Yellow"
        if (-not (Test-Path $configPath)) {
            Write-ColorOutput "✗ Configuration file not found: $configPath" "Red"
            $validationPassed = $false
            $issues += "Configuration file does not exist"
            
            Write-Host ""
            Write-ColorOutput "To create a configuration file, run:" "Cyan"
            Write-ColorOutput "  Set-ZeppAzureFunction -ResourceGroupName 'rg-zepp' -FunctionAppName 'func-zepp' -SaveConfig" "White"
            Write-Host ""
            return $false
        }
        Write-ColorOutput "✓ Configuration file exists" "Green"
        if ($Detailed) {
            Write-ColorOutput "  Path: $configPath" "White"
        }
        Write-Host ""

        # Check 2: Configuration file is readable
        Write-ColorOutput "Loading configuration..." "Yellow"
        $config = $null
        try {
            $config = LoadZeppConfigInternal -ConfigPath $configPath
            if ($null -eq $config) {
                throw "Configuration loaded as null"
            }
            Write-ColorOutput "✓ Configuration file is readable" "Green"
        } catch {
            Write-ColorOutput "✗ Failed to load configuration: $($_.Exception.Message)" "Red"
            $validationPassed = $false
            $issues += "Configuration file is not readable or contains invalid JSON"
            Write-Host ""
            return $false
        }
        Write-Host ""

        # Check 3: Required fields
        Write-ColorOutput "Validating required fields..." "Yellow"
        
        # Check ResourceGroupName
        if ([string]::IsNullOrWhiteSpace($config.ResourceGroupName)) {
            Write-ColorOutput "✗ ResourceGroupName is missing or empty" "Red"
            $validationPassed = $false
            $issues += "ResourceGroupName is required"
        } else {
            Write-ColorOutput "✓ ResourceGroupName is present" "Green"
            if ($Detailed) {
                Write-ColorOutput "  Value: $($config.ResourceGroupName)" "White"
            }
        }

        # Check FunctionAppName
        if ([string]::IsNullOrWhiteSpace($config.FunctionAppName)) {
            Write-ColorOutput "✗ FunctionAppName is missing or empty" "Red"
            $validationPassed = $false
            $issues += "FunctionAppName is required"
        } else {
            Write-ColorOutput "✓ FunctionAppName is present" "Green"
            if ($Detailed) {
                Write-ColorOutput "  Value: $($config.FunctionAppName)" "White"
            }
        }
        Write-Host ""

        # Check 4: Optional fields validation
        Write-ColorOutput "Validating optional fields..." "Yellow"

        # Check Location
        if ([string]::IsNullOrWhiteSpace($config.Location)) {
            Write-ColorOutput "⚠ Location is not set (will default to 'eastus')" "Yellow"
            if ($Detailed) {
                Write-ColorOutput "  Recommendation: Set a specific Azure region" "White"
            }
        } else {
            Write-ColorOutput "✓ Location is set" "Green"
            if ($Detailed) {
                Write-ColorOutput "  Value: $($config.Location)" "White"
            }
        }

        # Check AllowedIpAddress format
        if ([string]::IsNullOrWhiteSpace($config.AllowedIpAddress)) {
            Write-ColorOutput "⚠ AllowedIpAddress is not set (will allow all IPs: 0.0.0.0/0)" "Yellow"
            if ($Detailed) {
                Write-ColorOutput "  Recommendation: Set a specific IP address for better security" "White"
            }
        } else {
            # Validate IP format
            $ipToValidate = $config.AllowedIpAddress
            # Remove CIDR notation for validation
            if ($ipToValidate -match '^([0-9.]+)/\d+$') {
                $ipToValidate = $Matches[1]
            }
            
            if ($config.AllowedIpAddress -eq "0.0.0.0/0") {
                Write-ColorOutput "⚠ AllowedIpAddress allows all IPs (0.0.0.0/0)" "Yellow"
                if ($Detailed) {
                    Write-ColorOutput "  Warning: This is not secure for production" "Yellow"
                }
            } elseif (Test-IPv4Address -IpAddress $ipToValidate) {
                Write-ColorOutput "✓ AllowedIpAddress format is valid" "Green"
                if ($Detailed) {
                    Write-ColorOutput "  Value: $($config.AllowedIpAddress)" "White"
                }
            } else {
                Write-ColorOutput "✗ AllowedIpAddress format is invalid" "Red"
                $validationPassed = $false
                $issues += "AllowedIpAddress must be a valid IPv4 address or CIDR notation"
                if ($Detailed) {
                    Write-ColorOutput "  Value: $($config.AllowedIpAddress)" "White"
                }
            }
        }

        # Check StorageAccountName format
        if ([string]::IsNullOrWhiteSpace($config.StorageAccountName)) {
            Write-ColorOutput "⚠ StorageAccountName is not set (will be auto-generated)" "Yellow"
        } else {
            if (Test-StorageAccountName -StorageAccountName $config.StorageAccountName) {
                Write-ColorOutput "✓ StorageAccountName format is valid" "Green"
                if ($Detailed) {
                    Write-ColorOutput "  Value: $($config.StorageAccountName)" "White"
                }
            } else {
                Write-ColorOutput "✗ StorageAccountName format is invalid" "Red"
                $validationPassed = $false
                $issues += "StorageAccountName must be 3-24 characters, lowercase letters and numbers only"
                if ($Detailed) {
                    Write-ColorOutput "  Value: $($config.StorageAccountName)" "White"
                    Write-ColorOutput "  Expected: 3-24 lowercase alphanumeric characters" "White"
                }
            }
        }

        # Check DisableFunctionAuth
        if ($config.PSObject.Properties.Name -contains "DisableFunctionAuth") {
            $authValue = [bool]$config.DisableFunctionAuth
            Write-ColorOutput "✓ DisableFunctionAuth is set" "Green"
            if ($Detailed) {
                Write-ColorOutput "  Value: $authValue" "White"
                if ($authValue) {
                    Write-ColorOutput "  Note: Function will rely only on IP firewall for security" "Yellow"
                }
            }
        } else {
            Write-ColorOutput "✓ DisableFunctionAuth not set (will default to false)" "Green"
            if ($Detailed) {
                Write-ColorOutput "  Default: Function-level authentication enabled" "White"
            }
        }
        Write-Host ""

        # Summary
        Write-ColorOutput "================================================" "Cyan"
        if ($validationPassed) {
            Write-ColorOutput "  Configuration Validation Passed ✓" "Green"
        } else {
            Write-ColorOutput "  Configuration Validation Failed ✗" "Red"
        }
        Write-ColorOutput "================================================" "Cyan"
        Write-Host ""

        if ($validationPassed) {
            Write-ColorOutput "Summary:" "Cyan"
            Write-ColorOutput "  Configuration file: $configPath" "White"
            Write-ColorOutput "  Status: Valid ✓" "Green"
            Write-ColorOutput "  Resource Group: $($config.ResourceGroupName)" "White"
            Write-ColorOutput "  Function App: $($config.FunctionAppName)" "White"
            Write-Host ""
            Write-ColorOutput "Configuration is ready for deployment with:" "Cyan"
            Write-ColorOutput "  Set-ZeppAzureFunction -LoadConfig" "White"
            Write-Host ""
        } else {
            Write-ColorOutput "Issues found:" "Red"
            foreach ($issue in $issues) {
                Write-ColorOutput "  • $issue" "Red"
            }
            Write-Host ""
            Write-ColorOutput "Please fix these issues before deploying." "Yellow"
            Write-Host ""
        }

        return $validationPassed

    } catch {
        Write-ColorOutput "" "Red"
        Write-ColorOutput "================================================" "Red"
        Write-ColorOutput "  ERROR: $($_.Exception.Message)" "Red"
        Write-ColorOutput "================================================" "Red"
        Write-Host ""
        return $false
    }
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
    Write-Host "  3. Update-ZeppAzureToken  - Update API token securely" -ForegroundColor White
    Write-Host "  4. Get-ZeppConfig         - Retrieve saved configuration" -ForegroundColor White
    Write-Host "  5. Test-ZeppConfig        - Validate saved configuration" -ForegroundColor White
    Write-Host ""
    Write-Host "Usage examples:" -ForegroundColor Cyan
    Write-Host "  Set-ZeppAzureFunction -ResourceGroupName 'rg-zepp' -FunctionAppName 'func-zepp' -SaveConfig" -ForegroundColor White
    Write-Host "  Set-ZeppAzureFunction -LoadConfig" -ForegroundColor White
    Write-Host "  Test-ZeppAzureFunction -LoadConfig" -ForegroundColor White
    Write-Host "  Update-ZeppAzureToken -LoadConfig" -ForegroundColor White
    Write-Host "  Get-ZeppConfig" -ForegroundColor White
    Write-Host "  Test-ZeppConfig -Detailed" -ForegroundColor White
    Write-Host ""
    Write-Host "For help:" -ForegroundColor Cyan
    Write-Host "  Get-Help Set-ZeppAzureFunction -Detailed" -ForegroundColor White
    Write-Host "  Get-Help Test-ZeppAzureFunction -Detailed" -ForegroundColor White
    Write-Host "  Get-Help Update-ZeppAzureToken -Detailed" -ForegroundColor White
    Write-Host "  Get-Help Get-ZeppConfig -Detailed" -ForegroundColor White
    Write-Host "  Get-Help Test-ZeppConfig -Detailed" -ForegroundColor White
    Write-Host ""
}
