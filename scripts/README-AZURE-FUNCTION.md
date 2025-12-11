# Azure Function Creation Script

This directory contains a PowerShell script to create an Azure Function that provides a dummy API token for the ZeppNightscout application.

## Overview

The `create-azure-function.ps1` script automates the creation of:
- Azure Resource Group
- Azure Storage Account
- Azure Function App (Python 3.11 runtime)
- HTTP-triggered Python function that returns "DUMMY-TOKEN"
- IP access restrictions for security

## Prerequisites

Before running the script, ensure you have:

1. **Azure CLI** installed
   - Download from: https://docs.microsoft.com/cli/azure/install-azure-cli
   - Verify installation: `az --version`

2. **PowerShell** installed
   - Windows: Built-in (PowerShell 5.1+) or PowerShell 7+
   - Linux/macOS: Install PowerShell 7+ from https://github.com/PowerShell/PowerShell

3. **Azure Subscription**
   - Active Azure subscription with permissions to create resources
   - Log in with: `az login`

## Usage

### Basic Usage

```powershell
.\scripts\create-azure-function.ps1 `
    -ResourceGroupName "rg-zeppnightscout" `
    -FunctionAppName "func-zepptoken-unique123" `
    -AllowedIpAddress "203.0.113.10"
```

### Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `ResourceGroupName` | Yes | - | Name of the Azure Resource Group (will be created if it doesn't exist) |
| `FunctionAppName` | Yes | - | Name of the Function App (must be globally unique) |
| `Location` | No | `eastus` | Azure region for resources (e.g., `eastus`, `westeurope`, `southeastasia`) |
| `AllowedIpAddress` | No | `0.0.0.0/0` | IP address allowed to access the function (CIDR notation) |
| `StorageAccountName` | No | Auto-generated | Storage account name (3-24 lowercase alphanumeric chars) |

### Examples

#### Create function with specific IP restriction

```powershell
.\scripts\create-azure-function.ps1 `
    -ResourceGroupName "rg-zeppnightscout" `
    -FunctionAppName "func-zepptoken-prod" `
    -AllowedIpAddress "198.51.100.42"
```

#### Create function in a different region

```powershell
.\scripts\create-azure-function.ps1 `
    -ResourceGroupName "rg-zeppnightscout-eu" `
    -FunctionAppName "func-zepptoken-eu" `
    -Location "westeurope" `
    -AllowedIpAddress "198.51.100.42"
```

#### Create function without IP restrictions (development only)

```powershell
.\scripts\create-azure-function.ps1 `
    -ResourceGroupName "rg-zeppnightscout-dev" `
    -FunctionAppName "func-zepptoken-dev"
```

## What the Script Does

1. **Validates Prerequisites**
   - Checks if Azure CLI is installed
   - Verifies Azure login status

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
   - Uses function-level authentication
   - Provides secure function URL with access key

## Function Response

The deployed function returns the following JSON response:

```json
{
  "token": "DUMMY-TOKEN",
  "message": "This is a dummy API token for testing purposes"
}
```

## Testing the Function

After deployment, the script will output a function URL. Test it using:

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

### IP Restrictions

- **Recommended**: Always specify an IP address or CIDR range
- The function will only accept requests from the allowed IP(s)
- You can add multiple IP restrictions in the Azure Portal

### Function Key Authentication

- The function uses function-level authentication
- The `code` parameter in the URL is required for access
- Keep the function URL and key secure
- Regenerate keys if compromised (in Azure Portal)

### Best Practices

1. Use IP restrictions for production deployments
2. Keep function keys secure (don't commit to source control)
3. Use Azure Key Vault for sensitive configuration
4. Enable Application Insights for monitoring
5. Regularly review access logs

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

### Error: "Azure CLI is not installed"

**Solution**: Install Azure CLI from https://docs.microsoft.com/cli/azure/install-azure-cli

### Error: "Not logged in to Azure"

**Solution**: Run `az login` and follow the authentication prompts

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
2. Re-run the deployment using Azure Functions Core Tools
3. Check Azure Function App logs for details

## Cleanup

To delete all created resources:

```powershell
# Delete the entire resource group (removes all resources)
az group delete --name "rg-zeppnightscout" --yes
```

Or delete individual resources:

```powershell
# Delete only the function app
az functionapp delete --name "func-zepptoken" --resource-group "rg-zeppnightscout"

# Delete only the storage account
az storage account delete --name "stzepptoken" --resource-group "rg-zeppnightscout" --yes
```

## Integration with ZeppNightscout

This Azure Function is designed to provide an API token that can be used with the ZeppNightscout watch app. The function URL can be configured in the watch app to fetch the authentication token dynamically.

### Usage in ZeppNightscout

1. Deploy the Azure Function using this script
2. Edit the function in Azure Portal to return your actual Nightscout token
3. Configure the function URL in your ZeppNightscout app
4. The app will fetch the token from the Azure Function

## Additional Resources

- [Azure Functions Documentation](https://docs.microsoft.com/azure/azure-functions/)
- [Azure Functions Python Developer Guide](https://docs.microsoft.com/azure/azure-functions/functions-reference-python)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)
- [ZeppNightscout Project](https://github.com/iricigor/ZeppNightscout)

## Support

For issues or questions:
- Check the [main README](../README.md)
- Review Azure Function logs in the portal
- Open an issue in the GitHub repository
