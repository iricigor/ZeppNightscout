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
    When downloaded directly (via irm), downloads function files from GitHub.
    
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

# Define the list of function files to load
$functionFiles = @(
    "Helper-Functions.ps1",
    "Get-ZeppConfig.ps1",
    "Test-ZeppConfig.ps1",
    "Set-ZeppAzureFunction.ps1",
    "Test-ZeppAzureFunction.ps1",
    "Update-ZeppAzureToken.ps1"
)

# Check if we're running from repository (functions directory exists)
if ($functionsDir -and (Test-Path $functionsDir)) {
    # Load functions from separate files when running from repository
    foreach ($file in $functionFiles) {
        $filePath = Join-Path $functionsDir $file
        if (Test-Path $filePath) {
            . $filePath
        } else {
            Write-Warning "Function file not found: $filePath"
        }
    }
} else {
    # Running via irm or functions dir not available - download functions from GitHub
    # This ensures we always use the latest version from the main branch
    $githubBaseUrl = "https://raw.githubusercontent.com/iricigor/ZeppNightscout/main/scripts/functions"
    
    
    # Download and execute each function file from GitHub
    foreach ($file in $functionFiles) {
        $url = "$githubBaseUrl/$file"
        try {
            Write-Verbose "Downloading function file from: $url"
            $functionCode = Invoke-RestMethod -Uri $url -ErrorAction Stop
            # Execute the downloaded code to define the functions
            Invoke-Expression $functionCode
        } catch {
            Write-Error "Failed to download function file '$file' from GitHub: $($_.Exception.Message)"
            Write-Error "This script requires internet access to download function files when run via 'iex (irm ...)'."
            throw
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
