# Azure Function Python Template

This directory contains the Python code template for the Azure Function created by the `create-azure-function.ps1` script.

## Files

- `__init__.py` - The main Azure Function code that returns a dummy API token

## Purpose

The PowerShell script (`create-azure-function.ps1`) reads this Python code and deploys it to Azure Functions. This approach allows:

1. **Version Control**: Python code is stored as a separate file, making it easier to track changes
2. **Code Editing**: Developers can edit Python code in a Python-aware editor with syntax highlighting
3. **Maintainability**: Separating Python from PowerShell code improves code organization
4. **Backwards Compatibility**: The PowerShell script includes a fallback with embedded code for direct download scenarios (e.g., `iex (irm https://...)`)

## Modifying the Function

To modify the Azure Function behavior:

1. Edit `__init__.py` in this directory
2. Run the PowerShell deployment script to deploy the updated code

Alternatively, you can edit the function directly in the Azure Portal:
1. Navigate to your Function App
2. Select **Functions** → **GetToken** → **Code + Test**
3. Edit the code directly in the portal

## Function Features

The current implementation:
- Returns a dummy API token (`"DUMMY-TOKEN"`)
- Includes comprehensive debug logging
- Masks sensitive data in logs (tokens, keys, passwords)
- Handles errors gracefully with detailed error logging
- Returns standardized JSON responses

## Integration

This template is used by:
- `scripts/create-azure-function.ps1` - PowerShell deployment script
- See `scripts/README-AZURE-FUNCTION.md` for full documentation
