# Zeus Login and QR Code Generation Feature

## Overview

This document describes the new Zeus login and QR code generation feature added to the release workflow. This feature enables automatic generation of Zeus preview QR codes during releases, allowing users to install the app directly to their watch via the Zepp App.

## What's New

### Before

- Releases included a download QR code pointing to the GitHub release URL
- Users had to download the `.zab` file and manually install it
- Required multiple steps to get the app on the watch

### After

- Releases include **two types of QR codes**:
  1. **Zeus Preview QR Code** (new): Direct installation via Zepp App
  2. **Download QR Code** (existing): Download the `.zab` file
- Users can choose the fastest method for their needs
- Zeus preview QR code requires one-time secret configuration

## How It Works

### Technical Implementation

1. **Zeus Authentication**: The workflow uses `zeus config set` to configure authentication tokens directly
2. **Zeus Preview**: After successful configuration, `zeus preview` is run to generate a preview URL
   - Uses `expect` to automate interactive device selection
   - Captures output with full logging enabled for diagnostics
   - Supports both `zepp://` deep links and `https://` URLs
   - 120-second timeout to allow for network delays
3. **QR Code Generation**: The preview URL is converted to a QR code image using `qrencode`
4. **Release Publishing**: The QR code image is uploaded as a release artifact and displayed in release notes

### Workflow Steps

```
1. Setup (Node.js, Zeus CLI)
2. Zeus Authentication (configure via zeus config set)
   ├─ Success: Continue to preview
   └─ Failure: Skip preview, continue with download QR only
3. Build app (zeus build)
4. Generate Zeus Preview QR Code (if authentication successful)
   ├─ Run zeus preview with expect automation
   ├─ Capture full output to log file
   ├─ Extract preview URL (zepp:// or https://)
   ├─ Generate QR code image
   └─ Upload as artifact
5. Generate Download QR Code (always)
6. Create GitHub Release
   ├─ Zeus Preview QR Code (if available)
   ├─ Download QR Code (always)
   └─ .zab file artifact
```

## Configuration

### Required Secrets

To enable Zeus preview QR code generation, add these secrets to your repository:

| Secret | Description | How to Get |
|--------|-------------|------------|
| `ZEPP_APP_TOKEN` | Zepp OAuth application token | Run `zeus login` then `zeus config list`, copy `____user_zepp_com__token` |
| `ZEPP_USER_ID` | Zepp user ID | Run `zeus login` then `zeus config list`, copy `____user_zepp_com__userid` |
| `ZEPP_CNAME` | Zepp account display name | Run `zeus login` then `zeus config list`, copy `____user_zepp_com__cname` |

### Setup Instructions

1. **Get Zepp Developer Account**
   - If you don't have one, register at [developers.zepp.com](https://developers.zepp.com/)
   - Complete the browser-based OAuth login flow

2. **Obtain Authentication Tokens**
   ```bash
   # Login via browser OAuth
   zeus login
   
   # List configuration to get token values
   zeus config list
   
   # Copy these three values:
   # - ____user_zepp_com__token
   # - ____user_zepp_com__userid
   # - ____user_zepp_com__cname
   ```

3. **Add Secrets to Repository**
   ```
   GitHub Repository → Settings → Secrets and variables → Actions → New repository secret
   
   Add:
   - Name: ZEPP_APP_TOKEN, Value: [token from config list]
   - Name: ZEPP_USER_ID, Value: [userid from config list]
   - Name: ZEPP_CNAME, Value: [cname from config list]
   ```

4. **Trigger a Release**
   - Push a tag: `git tag v0.1.0 && git push origin v0.1.0`
   - Or manually trigger via Actions tab

### Optional Configuration

- **Skip Zeus QR Code**: Don't configure the secrets - workflow will skip Zeus preview and only generate download QR code
- **Test First**: Use manual workflow dispatch to test before creating official releases

## User Benefits

### For End Users

**Fastest Installation (Zeus Preview QR Code)**
1. Enable Developer Mode in Zepp App
2. Scan Zeus Preview QR code from release page
3. App installs directly to watch
4. Done! (No downloads or file transfers needed)

**Traditional Installation (Download QR Code)**
1. Scan Download QR code
2. Download `.zab` file
3. Install via Zepp App

### For Developers

- **Non-interactive authentication**: Uses command-line configuration instead of interactive login
- **Minimal dependencies**: Uses `expect` only for device selection (Zeus CLI limitation)
- **Automated**: No manual QR code generation needed
- **Consistent**: Same QR code for all users
- **Flexible**: Works with or without Zeus credentials
- **Secure**: Credentials stored as encrypted secrets
- **Documented**: Clear instructions for setup

## Security Considerations

### Credential Safety

- Secrets are **encrypted** by GitHub
- **Never exposed** in logs or public output
- Only accessible to **authorized workflows**
- Can be **rotated** at any time without code changes

### Best Practices

1. Use a dedicated Zepp developer account for CI/CD
2. Refresh tokens periodically (they may expire)
3. Review workflow logs to ensure secrets are masked
4. Limit repository access to trusted collaborators
5. Keep local Zeus CLI updated to ensure token compatibility

## Troubleshooting

### Zeus Authentication Fails

**Symptoms:**
- Warning: "Zeus authentication configuration failed. Preview QR code will not be generated."
- No Zeus Preview QR code in release

**Solutions:**
1. Verify secrets are configured correctly (ZEPP_APP_TOKEN, ZEPP_USER_ID, ZEPP_CNAME)
2. Refresh tokens by running `zeus login` locally and updating secrets
3. Check workflow logs for detailed error messages
4. Ensure token values don't have extra spaces or newlines
5. Retry the workflow run

**Note:** Releases will still succeed without Zeus preview QR code.

### Zeus Preview Times Out

**Symptoms:**
- "Preview timeout after 120 seconds" in logs
- No QR code generated

**Solutions:**
1. Check Zepp service availability
2. Review the full preview output logs in the workflow run
3. Retry the workflow
4. Check for network connectivity issues
5. Verify Zeus CLI version is up to date

**Note:** The timeout has been increased to 120 seconds and full logging is enabled for better diagnostics.

### QR Code Not Displayed in Release

**Symptoms:**
- Release created but QR code missing
- "Could not extract preview URL" warning

**Solutions:**
1. Check the workflow logs for the full `zeus preview` output
2. Look for both `zepp://` and `https://` URLs in the output
3. Check the log file contents displayed in the workflow output
4. Verify that `zeus preview` output format hasn't changed
5. Manually test `zeus preview` locally to see the actual output
6. Open an issue with the full workflow logs if the problem persists

### Secrets Not Working

**Symptoms:**
- "ZEPP_APP_TOKEN, ZEPP_USER_ID, or ZEPP_CNAME secrets not set" warning

**Solutions:**
1. Verify secrets are named exactly: `ZEPP_APP_TOKEN`, `ZEPP_USER_ID`, and `ZEPP_CNAME`
2. Check they are set as **repository secrets**, not environment variables
3. Verify repository has access to secrets
4. Re-add secrets if needed

## Testing

### Before Merging

1. Configure secrets in your fork/branch
2. Trigger manual workflow dispatch
3. Check workflow logs for successful authentication
4. Verify release includes Zeus preview QR code
5. Test scanning QR code with Zepp App

### Automated Testing

The workflow includes built-in testing:
- Validates secrets are available (warns if missing)
- Tests Zeus authentication success
- Validates QR code generation
- Uploads artifacts for verification
- Creates comprehensive release notes

## Future Improvements

Potential enhancements for future versions:

1. **Token Refresh**: Automatically refresh expired tokens if Zeus CLI supports it
2. **QR Code Preview**: Display QR code in workflow summary
3. **Multiple Device Targets**: Generate QR codes for different watch models
4. **Expiration Handling**: Regenerate QR codes if they expire
5. **Environment Variables**: Support setting tokens via environment variables for local testing

## Documentation

Related documentation:
- [Release Process](RELEASES.md) - Complete release workflow documentation
- [Workflow README](../.github/workflows/README.md) - GitHub Actions workflow details
- [Quick Start](../QUICK-START.md) - Getting started with zeus preview

## Support

If you encounter issues:
1. Check this document's troubleshooting section
2. Review workflow logs in Actions tab
3. Verify secrets are configured correctly
4. Open an issue with detailed error messages
5. Check Zepp OS documentation for Zeus CLI updates

## Credits

This feature was implemented to provide automated Zeus preview QR code generation in CI/CD pipelines.

Implementation details:
- Uses `zeus config set` for non-interactive authentication
- Uses `qrencode` for QR code image generation
- Uses `expect` for automating device selection in `zeus preview` (Zeus CLI limitation)
- Graceful fallback when secrets unavailable
- Comprehensive error handling and logging
