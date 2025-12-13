# Azure Function Deployment Instructions

This guide provides detailed instructions for deploying and managing Azure Functions for ZeppNightscout using the PowerShell deployment scripts.

## Table of Contents

- [Quick Start](#quick-start)
- [Configuration Management](#configuration-management)
  - [Using -SaveConfig](#using--saveconfig)
  - [Using -LoadConfig](#using--loadconfig)
  - [Managing Configuration Files](#managing-configuration-files)
- [Available Commands](#available-commands)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Testing Your Deployment](#testing-your-deployment)
- [Troubleshooting](#troubleshooting)

## Quick Start

### Method 1: Direct Download and Execute (Azure Cloud Shell)

```powershell
# Download and load the cmdlets
iex (irm https://raw.githubusercontent.com/iricigor/ZeppNightscout/main/scripts/create-azure-function.ps1)

# Deploy with configuration save
Set-ZeppAzureFunction -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken-unique123" -SaveConfig

# Later, redeploy using saved configuration
Set-ZeppAzureFunction -LoadConfig
```

### Method 2: Clone Repository

```powershell
# Clone the repository
git clone https://github.com/iricigor/ZeppNightscout.git
cd ZeppNightscout/scripts

# Load the cmdlets
. ./create-azure-function.ps1

# Deploy with configuration save
Set-ZeppAzureFunction -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken" -SaveConfig
```

## Configuration Management

The deployment scripts support saving and loading configuration to make redeployments and testing easier.

### Using -SaveConfig

When you deploy an Azure Function, you can save the configuration for later use:

```powershell
Set-ZeppAzureFunction `
    -ResourceGroupName "rg-zeppnightscout" `
    -FunctionAppName "func-zepptoken" `
    -Location "eastus" `
    -AllowedIpAddress "203.0.113.10" `
    -SaveConfig
```

This saves the following information to a local configuration file:
- ResourceGroupName
- FunctionAppName
- Location
- AllowedIpAddress
- StorageAccountName
- DisableFunctionAuth

**Configuration File Location:**
- When running from repository: `scripts/zepp-azure-config.json`
- When running from home: `~/zepp-azure-config.json` (Linux/Mac) or `%USERPROFILE%\zepp-azure-config.json` (Windows)

### Using -LoadConfig

After saving a configuration, you can redeploy or test using the saved settings:

#### Redeploy with Saved Configuration

```powershell
# Deploy using all saved settings
Set-ZeppAzureFunction -LoadConfig
```

This is useful when:
- You need to redeploy after making changes
- You want to deploy to multiple regions with consistent settings
- You're troubleshooting and need to recreate the deployment

#### Test with Saved Configuration

```powershell
# Test the function using saved configuration
Test-ZeppAzureFunction -LoadConfig
```

This automatically constructs the function URL from your saved configuration and tests connectivity.

### Managing Configuration Files

#### Retrieve Current Configuration

```powershell
# View the saved configuration
Get-ZeppConfig

# Get configuration as JSON
Get-ZeppConfig -AsJson
```

#### Validate Configuration

```powershell
# Basic validation
Test-ZeppConfig

# Detailed validation with recommendations
Test-ZeppConfig -Detailed
```

The validation checks:
- ✓ Configuration file exists and is readable
- ✓ Required fields are present (ResourceGroupName, FunctionAppName)
- ✓ IP address format is valid
- ✓ Storage account name format is correct
- ⚠ Warnings for security best practices

#### Example Output

```
================================================
  Test Zepp Configuration
================================================

Checking configuration file existence...
✓ Configuration file exists

Loading configuration...
✓ Configuration file is readable

Validating required fields...
✓ ResourceGroupName is present
✓ FunctionAppName is present

Validating optional fields...
✓ Location is set
✓ AllowedIpAddress format is valid
⚠ StorageAccountName is not set (will be auto-generated)
✓ DisableFunctionAuth not set (will default to false)

================================================
  Configuration Validation Passed ✓
================================================

Summary:
  Configuration file: /home/user/zepp-azure-config.json
  Status: Valid ✓
  Resource Group: rg-zeppnightscout
  Function App: func-zepptoken

Configuration is ready for deployment with:
  Set-ZeppAzureFunction -LoadConfig
```

## Available Commands

### Set-ZeppAzureFunction

Creates an Azure Function App with Python runtime.

**Key Parameters:**
- `-ResourceGroupName`: Name of the Azure Resource Group
- `-FunctionAppName`: Name of the Function App (must be globally unique)
- `-Location`: Azure region (default: eastus)
- `-AllowedIpAddress`: IP address restriction (default: auto-detected)
- `-SaveConfig`: Save configuration for later use
- `-LoadConfig`: Load and use saved configuration
- `-DisableFunctionAuth`: Disable function-level authentication

**Examples:**

```powershell
# Basic deployment with auto-detected IP
Set-ZeppAzureFunction -ResourceGroupName "rg-zepp" -FunctionAppName "func-zepp"

# Deploy with specific IP and save config
Set-ZeppAzureFunction -ResourceGroupName "rg-zepp" -FunctionAppName "func-zepp" -AllowedIpAddress "203.0.113.10" -SaveConfig

# Deploy from saved config
Set-ZeppAzureFunction -LoadConfig

# Deploy to different region
Set-ZeppAzureFunction -ResourceGroupName "rg-zepp-eu" -FunctionAppName "func-zepp-eu" -Location "westeurope"
```

### Test-ZeppAzureFunction

Tests a deployed Azure Function.

**Key Parameters:**
- `-FunctionUrl`: Complete URL of the function to test
- `-ExpectedToken`: Optional expected token value for validation
- `-LoadConfig`: Load configuration and construct URL automatically

**Examples:**

```powershell
# Test with explicit URL
Test-ZeppAzureFunction -FunctionUrl "https://func-zepp.azurewebsites.net/api/GetToken?code=abc123"

# Test with expected token validation
Test-ZeppAzureFunction -FunctionUrl "https://func-zepp.azurewebsites.net/api/GetToken?code=abc123" -ExpectedToken "DUMMY-TOKEN"

# Test using saved configuration
Test-ZeppAzureFunction -LoadConfig
```

### Get-ZeppConfig

Retrieves the saved deployment configuration.

**Key Parameters:**
- `-ConfigName`: Optional custom configuration file name (default: zepp-azure-config)
- `-AsJson`: Return configuration as JSON string

**Examples:**

```powershell
# View current configuration
Get-ZeppConfig

# Get as JSON
Get-ZeppConfig -AsJson

# Use custom config file
Get-ZeppConfig -ConfigName "my-custom-config"
```

### Test-ZeppConfig

Validates the saved deployment configuration.

**Key Parameters:**
- `-ConfigName`: Optional custom configuration file name (default: zepp-azure-config)
- `-Detailed`: Show detailed validation results

**Examples:**

```powershell
# Basic validation
Test-ZeppConfig

# Detailed validation with recommendations
Test-ZeppConfig -Detailed

# Validate custom config file
Test-ZeppConfig -ConfigName "my-custom-config" -Detailed
```

## Step-by-Step Deployment

### Step 1: Initial Deployment

Start by deploying your Azure Function and saving the configuration:

```powershell
# Load the scripts
iex (irm https://raw.githubusercontent.com/iricigor/ZeppNightscout/main/scripts/create-azure-function.ps1)

# Deploy and save configuration
Set-ZeppAzureFunction `
    -ResourceGroupName "rg-zeppnightscout" `
    -FunctionAppName "func-zepptoken-$(Get-Random -Minimum 1000 -Maximum 9999)" `
    -SaveConfig
```

### Step 2: Verify Configuration

Check that the configuration was saved correctly:

```powershell
# View saved configuration
Get-ZeppConfig

# Validate configuration
Test-ZeppConfig -Detailed
```

### Step 3: Test the Deployment

Test your function using the saved configuration:

```powershell
# Test using saved config (constructs URL automatically)
Test-ZeppAzureFunction -LoadConfig
```

### Step 4: Make Changes (Optional)

If you need to update the function or configuration:

```powershell
# Redeploy using saved configuration
Set-ZeppAzureFunction -LoadConfig

# Or deploy with updated settings and save
Set-ZeppAzureFunction -ResourceGroupName "rg-zepp" -FunctionAppName "func-zepp-v2" -Location "westeurope" -SaveConfig
```

## Testing Your Deployment

### Quick Test with LoadConfig

The easiest way to test after deployment:

```powershell
Test-ZeppAzureFunction -LoadConfig
```

This command:
1. Loads your saved configuration
2. Constructs the function URL automatically
3. Tests HTTP connectivity
4. Validates the JSON response structure
5. Confirms the token field is present

### Manual Testing

You can also test manually with curl or PowerShell:

```powershell
# Using curl
curl "https://your-function-app.azurewebsites.net/api/GetToken?code=your-key"

# Using PowerShell
Invoke-RestMethod -Uri "https://your-function-app.azurewebsites.net/api/GetToken?code=your-key"
```

### Validation Testing

Validate configuration before deployment:

```powershell
# Check if configuration is valid
if (Test-ZeppConfig) {
    Write-Host "✓ Configuration is valid, proceeding with deployment"
    Set-ZeppAzureFunction -LoadConfig
} else {
    Write-Host "✗ Configuration is invalid, please fix issues"
}
```

## Troubleshooting

### Configuration File Not Found

**Problem:** `Get-ZeppConfig` or `Test-ZeppConfig` reports configuration file not found.

**Solution:**
```powershell
# Deploy and save configuration
Set-ZeppAzureFunction -ResourceGroupName "rg-zepp" -FunctionAppName "func-zepp" -SaveConfig

# Verify it was saved
Get-ZeppConfig
```

### Invalid Configuration

**Problem:** `Test-ZeppConfig` reports validation errors.

**Solution:**
```powershell
# View detailed validation errors
Test-ZeppConfig -Detailed

# Common issues:
# - Missing ResourceGroupName or FunctionAppName: Redeploy with -SaveConfig
# - Invalid IP format: Use format like "1.2.3.4" or "1.2.3.0/24"
# - Invalid storage account name: Use 3-24 lowercase alphanumeric characters
```

### LoadConfig Fails

**Problem:** `Set-ZeppAzureFunction -LoadConfig` or `Test-ZeppAzureFunction -LoadConfig` fails.

**Solution:**
```powershell
# First, validate the configuration
Test-ZeppConfig -Detailed

# If validation passes, check if you're logged into Azure
Get-AzContext

# If not logged in
Connect-AzAccount
```

### Function URL Not Working

**Problem:** `Test-ZeppAzureFunction -LoadConfig` can't construct the URL.

**Solution:**
```powershell
# Check if FunctionAppName is in the configuration
Get-ZeppConfig

# If missing, redeploy with SaveConfig
Set-ZeppAzureFunction -ResourceGroupName "rg-zepp" -FunctionAppName "func-zepp" -SaveConfig
```

### Multiple Configurations

If you need to manage multiple configurations:

```powershell
# Save with custom name
# Note: This requires manual editing of the config file path
# The cmdlets currently use a fixed config name

# Workaround: Save configs manually
$config = @{
    ResourceGroupName = "rg-zepp-prod"
    FunctionAppName = "func-zepp-prod"
    Location = "eastus"
}
$config | ConvertTo-Json | Set-Content "my-prod-config.json"
```

## Best Practices

1. **Always use -SaveConfig on first deployment**
   ```powershell
   Set-ZeppAzureFunction -ResourceGroupName "rg-zepp" -FunctionAppName "func-zepp" -SaveConfig
   ```

2. **Validate before redeployment**
   ```powershell
   Test-ZeppConfig -Detailed
   Set-ZeppAzureFunction -LoadConfig
   ```

3. **Test immediately after deployment**
   ```powershell
   Test-ZeppAzureFunction -LoadConfig
   ```

4. **Use descriptive resource names**
   ```powershell
   # Good: func-zepptoken-prod, func-zepptoken-dev
   # Bad: func1, myfunction
   ```

5. **Specify IP restrictions for production**
   ```powershell
   Set-ZeppAzureFunction -ResourceGroupName "rg-zepp" -FunctionAppName "func-zepp" -AllowedIpAddress "203.0.113.10" -SaveConfig
   ```

## Next Steps

- Read the full [Azure Function README](README-AZURE-FUNCTION.md)
- Learn about [editing the function in Azure Portal](README-AZURE-FUNCTION.md#editing-the-function)
- Understand [security considerations](README-AZURE-FUNCTION.md#security-considerations)
- Set up [monitoring and debugging](README-AZURE-FUNCTION.md#debugging-and-monitoring)

## Support

For issues or questions:
- Check the [main README](../README.md)
- Review the [Azure Function README](README-AZURE-FUNCTION.md)
- Open an issue in the GitHub repository
