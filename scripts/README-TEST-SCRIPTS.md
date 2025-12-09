# Test Scripts for Zeus CLI Release Pipeline

This directory contains standalone test scripts that replicate the critical parts of the GitHub Actions release pipeline. These scripts allow you to test the Zeus CLI setup and build/preview process locally before committing changes.

## Overview

The release pipeline consists of two main components:

1. **Zeus CLI Setup** - Installs and configures Zeus CLI with authentication
2. **Zeus Build and Preview** - Builds the app and generates a preview QR code

## Prerequisites

- Node.js and npm installed
- Access to Zepp developer credentials (for QR code generation):
  - `ZEPP_APP_TOKEN` - Your Zepp app token
  - `ZEPP_USER_ID` - Your Zepp user ID  
  - `ZEPP_CNAME` - Your Zepp cname

## Scripts

### `test-zeus-setup.sh`

Replicates the `.github/actions/zeus-setup` action.

**What it does:**
- Installs Zeus CLI globally via npm
- Configures Zeus CLI with authentication tokens
- Outputs success/failure status

**Usage:**
```bash
# Set environment variables with your credentials
export ZEPP_APP_TOKEN="your_token_here"
export ZEPP_USER_ID="your_user_id_here"
export ZEPP_CNAME="your_cname_here"

# Run the setup script
bash scripts/test-zeus-setup.sh
```

**Without credentials:**
```bash
# The script will run but skip authentication
bash scripts/test-zeus-setup.sh
```

### `test-zeus-build-preview.sh`

Replicates the `.github/actions/zeus-build-preview` action.

**What it does:**
- Builds the app using `zeus build`
- Generates Zeus preview QR code (if authenticated)
- Saves the QR code as both ASCII art (in console) and PNG image (`zeus_preview_qr.png`)

**Usage:**
```bash
# After running test-zeus-setup.sh, run this script
bash scripts/test-zeus-build-preview.sh
```

**Combined usage:**
```bash
# Set credentials and run both scripts in sequence
export ZEPP_APP_TOKEN="your_token_here"
export ZEPP_USER_ID="your_user_id_here"
export ZEPP_CNAME="your_cname_here"

bash scripts/test-zeus-setup.sh && bash scripts/test-zeus-build-preview.sh
```

## Expected Output

### Successful Execution

When everything works correctly, you should see:

1. Zeus CLI installed successfully
2. Authentication configured (if credentials provided)
3. App built successfully
4. QR code displayed in the console (ASCII art)
5. QR code saved as `zeus_preview_qr.png`

### Success Criteria

The release pipeline is considered successful when:

✅ Zeus CLI is installed and configured  
✅ App builds without errors  
✅ Zeus preview QR code is generated and captured  
✅ `zeus_preview_qr.png` file exists

## Troubleshooting

### Zeus CLI Not Found

**Error:** `zeus: command not found`

**Solution:** Make sure Zeus CLI is installed:
```bash
npm install -g @zeppos/zeus-cli
```

### Authentication Failed

**Error:** `Zeus authentication configuration failed`

**Solution:** Verify your credentials are correct and properly exported:
```bash
echo $ZEPP_APP_TOKEN
echo $ZEPP_USER_ID
echo $ZEPP_CNAME
```

### QR Code Not Generated

**Warning:** `Could not extract preview URL from zeus preview output`

**What this means:** The QR code was displayed in the console as ASCII art, but the script couldn't automatically decode it to create a PNG image. This is not a critical error - the QR code is still usable from the console output.

**Solution:** Manually scan the ASCII QR code from the console output using the Zepp app on your phone.

### Build Failed

**Error:** `Zeus build failed`

**Solution:** Check that:
- You're in the project root directory
- All dependencies are installed
- The `app.json` file is present and valid

## Testing Without Credentials

You can test the build process without Zepp credentials:

```bash
# This will build the app but skip QR code generation
bash scripts/test-zeus-setup.sh
bash scripts/test-zeus-build-preview.sh
```

The build will complete successfully, but you'll see warnings that QR code generation was skipped.

## Integration with GitHub Actions

These scripts mirror the following GitHub Actions:

- **test-zeus-setup.sh** → `.github/actions/zeus-setup/action.yml`
- **test-zeus-build-preview.sh** → `.github/actions/zeus-build-preview/action.yml`

Changes tested locally with these scripts should work in the GitHub Actions pipeline.

## Support

For issues or questions about the Zeus CLI or release pipeline:
- Check the [Zeus CLI documentation](https://docs.zepp.com/docs/guides/tools/cli/)
- Review the GitHub Actions workflow at `.github/workflows/release-modular.yml`
- Open an issue in the repository

## Related Files

- `.github/actions/zeus-setup/action.yml` - GitHub Action for Zeus CLI setup
- `.github/actions/zeus-build-preview/action.yml` - GitHub Action for build and preview
- `.github/workflows/release-modular.yml` - Main release workflow
- `scripts/generate-zeus-preview.sh` - Script that generates the preview QR code
