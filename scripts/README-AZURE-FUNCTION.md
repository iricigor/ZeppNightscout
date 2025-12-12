# Azure Function Creation Script

This directory contains a PowerShell script that provides cmdlets to create and test an Azure Function that provides a dummy API token for the ZeppNightscout application.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
  - [Method 1: Direct Download and Execute](#method-1-direct-download-and-execute-recommended-for-azure-cloud-shell)
  - [Method 2: Clone Repository](#method-2-clone-repository)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [Creating Azure Function](#creating-azure-function)
  - [Testing Azure Function](#testing-azure-function)
- [What the Script Does](#what-the-script-does)
- [Function Response](#function-response)
- [Testing the Function](#testing-the-function)
  - [Using Test-ZeppAzureFunction Cmdlet](#using-test-zeppazurefunction-cmdlet)
  - [Using curl](#using-curl)
  - [Using PowerShell](#using-powershell)
  - [Using a Web Browser](#using-a-web-browser)
- [Editing the Function](#editing-the-function)
- [Security Considerations](#security-considerations)
- [Costs](#costs)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Integration with ZeppNightscout](#integration-with-zeppnightscout)
- [Additional Resources](#additional-resources)
- [Support](#support)

## Overview

The `create-azure-function.ps1` script provides two cmdlets:

1. **`Set-ZeppAzureFunction`** - Automates the creation of:
   - Azure Resource Group
   - Azure Storage Account
   - Azure Function App (Python 3.11 runtime)
   - HTTP-triggered Python function that returns "DUMMY-TOKEN"
   - IP access restrictions for security

2. **`Test-ZeppAzureFunction`** - Tests a deployed Azure Function to:
   - Verify HTTP connectivity
   - Validate JSON response format
   - Confirm proper token payload is returned

**This script is designed for Azure Cloud Shell** where Azure PowerShell (Az module) is pre-installed and pre-authenticated.

## Quick Start

### Method 1: Direct Download and Execute (Recommended for Azure Cloud Shell)

Open Azure Cloud Shell (PowerShell mode) and run:

```powershell
# Download and load the cmdlets
iex (irm https://raw.githubusercontent.com/iricigor/ZeppNightscout/main/scripts/create-azure-function.ps1)

# Create the Azure Function
Set-ZeppAzureFunction -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken-unique123" -AllowedIpAddress "203.0.113.10"

# Test the Azure Function (use the URL from previous command output)
Test-ZeppAzureFunction -FunctionUrl "https://func-zepptoken-unique123.azurewebsites.net/api/GetToken?code=your-function-key"
```

This will:
1. Download the script from GitHub
2. Load the `Set-ZeppAzureFunction` and `Test-ZeppAzureFunction` cmdlets into your session
3. Allow you to run the cmdlets with your parameters

### Method 2: Clone Repository

1. Go to [Azure Portal](https://portal.azure.com)
2. Click the Cloud Shell icon (>_) in the top navigation bar
3. Select **PowerShell** if prompted
4. Clone the repository:
   ```powershell
   git clone https://github.com/iricigor/ZeppNightscout.git
   cd ZeppNightscout
   ```
5. Load the cmdlet:
   ```powershell
   . ./scripts/create-azure-function.ps1
   ```
6. Run the cmdlet:
   ```powershell
   Set-ZeppAzureFunction -ResourceGroupName "rg-zeppnightscout" -FunctionAppName "func-zepptoken-unique123" -AllowedIpAddress "203.0.113.10"
   ```

## Prerequisites

### Recommended: Azure Cloud Shell (No Installation Required!)

The easiest way to run this script is through Azure Cloud Shell - no installation or authentication needed!

### Alternative: Local PowerShell

If running locally, you need:

1. **PowerShell** 7+ installed
   - Download from: https://github.com/PowerShell/PowerShell

2. **Azure PowerShell (Az module)**
   - Install with: `Install-Module -Name Az -AllowClobber -Scope CurrentUser`
   - Documentation: https://learn.microsoft.com/powershell/azure/

3. **Azure Subscription**
   - Active Azure subscription with permissions to create resources
   - Log in with: `Connect-AzAccount`

## Usage

### Creating Azure Function

#### Basic Usage

```powershell
Set-ZeppAzureFunction `
    -ResourceGroupName "rg-zeppnightscout" `
    -FunctionAppName "func-zepptoken-unique123" `
    -AllowedIpAddress "203.0.113.10"
```

#### Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `ResourceGroupName` | Yes | - | Name of the Azure Resource Group (will be created if it doesn't exist) |
| `FunctionAppName` | Yes | - | Name of the Function App (must be globally unique) |
| `Location` | No | `eastus` | Azure region for resources (e.g., `eastus`, `westeurope`, `southeastasia`) |
| `AllowedIpAddress` | No | `0.0.0.0/0` | IP address allowed to access the function (CIDR notation) |
| `StorageAccountName` | No | Auto-generated | Storage account name (3-24 lowercase alphanumeric chars) |
| `DisableFunctionAuth` | No | `false` | Switch to disable function-level authentication (relies only on IP firewall) |

### Examples

#### Create function with specific IP restriction

```powershell
Set-ZeppAzureFunction `
    -ResourceGroupName "rg-zeppnightscout" `
    -FunctionAppName "func-zepptoken-prod" `
    -AllowedIpAddress "198.51.100.42"
```

#### Create function in a different region

```powershell
Set-ZeppAzureFunction `
    -ResourceGroupName "rg-zeppnightscout-eu" `
    -FunctionAppName "func-zepptoken-eu" `
    -Location "westeurope" `
    -AllowedIpAddress "198.51.100.42"
```

#### Create function with IP restriction only (no function-level auth)

```powershell
Set-ZeppAzureFunction `
    -ResourceGroupName "rg-zeppnightscout" `
    -FunctionAppName "func-zepptoken-iponly" `
    -AllowedIpAddress "198.51.100.42" `
    -DisableFunctionAuth
```

**Note:** This relies solely on IP firewall for security. Only use when you have a static IP and want simpler URLs without access keys.

#### Get help for the cmdlet

```powershell
Get-Help Set-ZeppAzureFunction -Detailed
```

### Testing Azure Function

After deploying an Azure Function, you can test it using the `Test-ZeppAzureFunction` cmdlet to verify it's working correctly.

#### Basic Usage

```powershell
Test-ZeppAzureFunction -FunctionUrl "https://your-function-app.azurewebsites.net/api/GetToken?code=your-function-key"
```

This will:
- Test HTTP connectivity to the function
- Validate the response is valid JSON
- Check that the response contains a `token` field
- Optionally validate the `message` field if present
- Display a summary of the test results

#### Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `FunctionUrl` | Yes | - | Complete URL of the Azure Function to test, including query parameters (like the code parameter) |
| `ExpectedToken` | No | - | Optional expected token value. If provided, validates the token matches this value |

#### Examples

##### Test function connectivity and response structure

```powershell
Test-ZeppAzureFunction -FunctionUrl "https://func-zepptoken.azurewebsites.net/api/GetToken?code=abc123xyz"
```

This checks that:
- The function is accessible
- Returns valid JSON
- Contains a `token` field

##### Test function with expected token value

```powershell
Test-ZeppAzureFunction `
    -FunctionUrl "https://func-zepptoken.azurewebsites.net/api/GetToken?code=abc123xyz" `
    -ExpectedToken "DUMMY-TOKEN"
```

This additionally validates that the token value matches "DUMMY-TOKEN".

##### Test function without authentication (IP firewall only)

If you deployed with `-DisableFunctionAuth`, the URL doesn't need a code parameter:

```powershell
Test-ZeppAzureFunction -FunctionUrl "https://func-zepptoken.azurewebsites.net/api/GetToken"
```

#### Understanding Test Results

The cmdlet will output:
- ✓ Green checkmarks for successful validations
- ✗ Red X marks for failures
- ⚠ Yellow warnings for optional items
- A summary showing the function URL, status, and token value

**Example successful output:**
```
================================================
  Test Completed Successfully! ✓
================================================

Summary:
  Function URL: https://func-zepptoken.azurewebsites.net/api/GetToken?code=...
  Status: Passed ✓
  Token: DUMMY-TOKEN
  Message: This is a dummy API token for testing purposes
```

#### Get help for the cmdlet

```powershell
Get-Help Test-ZeppAzureFunction -Detailed
```

## What the Script Does

1. **Validates Prerequisites**
   - Checks if Azure PowerShell (Az module) is available
   - Verifies Azure login status
   - Installs missing Az modules if needed (in Cloud Shell, they're pre-installed)

2. **Creates Azure Resources**
   - Resource Group (if it doesn't exist)
   - Storage Account (required for Azure Functions)
   - Function App with Python 3.11 runtime
   - Consumption plan for cost-effective hosting

3. **Deploys Function Code**
   - Creates HTTP-triggered Python function named "GetToken"
   - Returns JSON response: `{"token": "DUMMY-TOKEN", "message": "..."}`
   - Code is editable directly in Azure Portal

4. **Configures Security**
   - Applies IP access restrictions (if specified)
   - Configures function-level authentication (unless disabled with `-DisableFunctionAuth`)
   - Provides secure function URL with access key (if auth enabled)

## Function Response

The deployed function returns the following JSON response:

```json
{
  "token": "DUMMY-TOKEN",
  "message": "This is a dummy API token for testing purposes"
}
```

## Testing the Function

After deployment, the script will output a function URL. You can test it using several methods:

### Using Test-ZeppAzureFunction Cmdlet

**Recommended:** Use the built-in test cmdlet for comprehensive validation:

```powershell
# Basic test
Test-ZeppAzureFunction -FunctionUrl "https://your-function-app.azurewebsites.net/api/GetToken?code=your-function-key"

# Test with expected token validation
Test-ZeppAzureFunction `
    -FunctionUrl "https://your-function-app.azurewebsites.net/api/GetToken?code=your-function-key" `
    -ExpectedToken "DUMMY-TOKEN"
```

See the [Testing Azure Function](#testing-azure-function) section above for more details and examples.

### Using curl

```bash
curl "https://your-function-app.azurewebsites.net/api/GetToken?code=your-function-key"
```

### Using PowerShell

```powershell
Invoke-RestMethod -Uri "https://your-function-app.azurewebsites.net/api/GetToken?code=your-function-key"
```

### Using a Web Browser

Simply paste the function URL (including the code parameter) into your browser.

## Editing the Function

To modify the function's response in the Azure Portal:

1. Go to https://portal.azure.com
2. Navigate to your Function App
3. Select **Functions** → **GetToken**
4. Click **Code + Test**
5. Edit the `__init__.py` file
6. Click **Save** to deploy your changes

### Example: Changing the Token Value

In the Azure Portal, modify the return statement in `__init__.py`:

```python
return func.HttpResponse(
    body=json.dumps({
        "token": "YOUR-CUSTOM-TOKEN-HERE",
        "message": "Custom message"
    }),
    mimetype="application/json",
    status_code=200
)
```

## Security Considerations

### Understanding Authentication Options

Azure Functions provides two layers of security that can be used independently or together:

#### 1. Function-Level Authentication (Default)

When enabled (default), the function requires an access key in the URL:
- **URL format:** `https://your-function.azurewebsites.net/api/GetToken?code=ACCESS_KEY`
- **Pros:** 
  - Works from any IP address
  - Can rotate keys without infrastructure changes
  - Multiple keys can be created for different clients
- **Cons:**
  - URL contains sensitive access key
  - Key could be exposed in logs, browser history, etc.

#### 2. IP Firewall Only (Use `-DisableFunctionAuth`)

When you disable function authentication and use IP restrictions:
- **URL format:** `https://your-function.azurewebsites.net/api/GetToken` (no access key needed)
- **Pros:**
  - Simpler URLs without sensitive data
  - No risk of key exposure in logs/history
  - Cleaner integration with applications
- **Cons:**
  - Requires static IP address
  - Must update firewall rules if IP changes
  - All traffic from allowed IP is trusted

**Recommendation:** Use IP firewall only (`-DisableFunctionAuth`) when:
- You have a static IP address
- You want simpler URLs without access keys
- You trust all applications/users from that IP

Use function-level authentication when:
- You need to access from multiple/dynamic IPs
- You want granular access control with multiple keys
- You need to rotate credentials without infrastructure changes

### IP Restrictions

- **Recommended**: Always specify an IP address or CIDR range
- The function will only accept requests from the allowed IP(s)
- You can add multiple IP restrictions in the Azure Portal

#### Changing IP Address After Deployment

To update the allowed IP address after deployment:

##### Option 1: Using Azure Portal (Easiest)
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your Function App
3. Select **Networking** → **Access restriction**
4. Edit the "AllowSpecificIP" rule or add new rules
5. Click **Save**

##### Option 2: Using PowerShell
```powershell
# Remove old IP restriction
Remove-AzWebAppAccessRestrictionRule `
    -ResourceGroupName "rg-zeppnightscout" `
    -WebAppName "func-zepptoken" `
    -Name "AllowSpecificIP"

# Add new IP restriction
Add-AzWebAppAccessRestrictionRule `
    -ResourceGroupName "rg-zeppnightscout" `
    -WebAppName "func-zepptoken" `
    -Name "AllowSpecificIP" `
    -Action Allow `
    -IpAddress "NEW.IP.ADDRESS.HERE" `
    -Priority 100
```

##### Option 3: Using Azure Cloud Shell (Alternative with Azure CLI)
Open Cloud Shell in Azure Portal and run these Azure CLI commands:
```bash
# Remove old rule
az functionapp config access-restriction remove \
    --resource-group rg-zeppnightscout \
    --name func-zepptoken \
    --rule-name AllowSpecificIP

# Add new rule
az functionapp config access-restriction add \
    --resource-group rg-zeppnightscout \
    --name func-zepptoken \
    --rule-name AllowSpecificIP \
    --action Allow \
    --ip-address NEW.IP.ADDRESS.HERE \
    --priority 100
```

**Note:** Azure Cloud Shell supports both PowerShell and Azure CLI. Use PowerShell (Option 2) for consistency with the deployment script.

### Function Key Authentication

- The function uses function-level authentication by default
- The `code` parameter in the URL is required for access
- Keep the function URL and key secure
- Regenerate keys if compromised:
  1. Go to Azure Portal → Function App → Functions → GetToken
  2. Select **Function Keys**
  3. Click **Regenerate** on the default key

### Best Practices

1. Use IP restrictions for production deployments
2. Consider disabling function auth if using IP firewall only (simpler URLs)
3. Keep function keys secure if using function-level auth (don't commit to source control)
4. Use Azure Key Vault for sensitive configuration
5. Enable Application Insights for monitoring
6. Regularly review access logs

## Costs

The script creates resources on Azure **Consumption Plan**:

- **Free Tier Includes**:
  - 1 million requests per month
  - 400,000 GB-s of execution time per month

- **Estimated Costs** (after free tier):
  - $0.20 per million executions
  - $0.000016 per GB-s of execution time

For detailed pricing, see: https://azure.microsoft.com/pricing/details/functions/

## Troubleshooting

### Error: "Az module not found"

**Solution**: If running locally (not in Cloud Shell), install Azure PowerShell:
```powershell
Install-Module -Name Az -AllowClobber -Scope CurrentUser
```

Or use Azure Cloud Shell where it's pre-installed.

### Error: "Not logged in to Azure"

**Solution**: 
- **In Azure Cloud Shell**: You're automatically authenticated - this shouldn't happen
- **Running locally**: Run `Connect-AzAccount` and follow the authentication prompts

### Error: "Function app name is already taken"

**Solution**: Function app names must be globally unique. Try a different name with a unique suffix:
```powershell
-FunctionAppName "func-zepptoken-$(Get-Random)"
```

### Error: "Storage account name is invalid"

**Solution**: Storage account names must be:
- 3-24 characters
- Lowercase letters and numbers only
- Globally unique

### Warning: "Function deployment may have failed"

The function app is created, but code deployment failed. You can:
1. Manually upload the function code in Azure Portal
2. Re-run the script
3. Check Azure Function App logs for details

### IP Restrictions Not Working

If you can't access the function from your allowed IP:
1. Verify your current public IP address: `curl ifconfig.me`
2. Check the IP restriction rules in Azure Portal (Networking → Access restriction)
3. Ensure the IP address format is correct (e.g., `1.2.3.4` or `1.2.3.0/24`)
4. Wait a few minutes for changes to propagate

## Cleanup

To delete all created resources:

### Using PowerShell

```powershell
# Delete the entire resource group (removes all resources)
Remove-AzResourceGroup -Name "rg-zeppnightscout" -Force
```

Or delete individual resources:

```powershell
# Delete only the function app
Remove-AzFunctionApp -Name "func-zepptoken" -ResourceGroupName "rg-zeppnightscout" -Force

# Delete only the storage account
Remove-AzStorageAccount -Name "stzepptoken" -ResourceGroupName "rg-zeppnightscout" -Force
```

### Using Azure Cloud Shell (Azure CLI)

```bash
# Delete the entire resource group
az group delete --name "rg-zeppnightscout" --yes

## Integration with ZeppNightscout

This Azure Function is designed to provide an API token that can be used with the ZeppNightscout watch app. The function URL can be configured in the watch app to fetch the authentication token dynamically.

### Usage in ZeppNightscout

1. Deploy the Azure Function using this script
2. Edit the function in Azure Portal to return your actual Nightscout token
3. Configure the function URL in your ZeppNightscout app
4. The app will fetch the token from the Azure Function

## Additional Resources

- [Azure Functions Documentation](https://learn.microsoft.com/azure/azure-functions/)
- [Azure Functions Python Developer Guide](https://learn.microsoft.com/azure/azure-functions/functions-reference-python)
- [Azure PowerShell Documentation](https://learn.microsoft.com/powershell/azure/)
- [ZeppNightscout Project](https://github.com/iricigor/ZeppNightscout)

## Support

For issues or questions:
- Check the [main README](../README.md)
- Review Azure Function logs in the portal
- Open an issue in the GitHub repository
