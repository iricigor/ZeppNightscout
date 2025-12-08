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

1. **Zeus Login**: The workflow uses an `expect` script to automate the interactive `zeus login` command
2. **Zeus Preview**: After successful login, `zeus preview` is run to generate a preview URL
3. **QR Code Generation**: The preview URL is converted to a QR code image using `qrencode`
4. **Release Publishing**: The QR code image is uploaded as a release artifact and displayed in release notes

### Workflow Steps

```
1. Setup (Node.js, Zeus CLI, expect)
2. Zeus Login (automated with expect script)
   ├─ Success: Continue to preview
   └─ Failure: Skip preview, continue with download QR only
3. Build app (zeus build)
4. Generate Zeus Preview QR Code (if login successful)
   ├─ Run zeus preview
   ├─ Extract preview URL
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
| `ZEPP_USERNAME` | Zepp developer account email/username | Your Zepp developer account credentials |
| `ZEPP_PASSWORD` | Zepp developer account password | Your Zepp developer account credentials |

### Setup Instructions

1. **Get Zepp Developer Account**
   - If you don't have one, register at [developers.zepp.com](https://developers.zepp.com/)
   - If using third-party login (Google/Facebook), bind email and set password at [user.huami.com](https://user.huami.com/privacy2/#/bindEmail)

2. **Add Secrets to Repository**
   ```
   GitHub Repository → Settings → Secrets and variables → Actions → New repository secret
   
   Add:
   - Name: ZEPP_USERNAME, Value: your-email@example.com
   - Name: ZEPP_PASSWORD, Value: your-password
   ```

3. **Trigger a Release**
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
2. Rotate credentials periodically
3. Review workflow logs to ensure secrets are masked
4. Limit repository access to trusted collaborators
5. Use read-only tokens where possible (if Zepp supports)

## Troubleshooting

### Zeus Login Fails

**Symptoms:**
- Warning: "Zeus login failed. Preview QR code will not be generated."
- No Zeus Preview QR code in release

**Solutions:**
1. Verify secrets are configured correctly
2. Check credentials work with manual `zeus login`
3. For third-party login, ensure email/password are bound
4. Check workflow logs for detailed error messages
5. Retry the workflow run

**Note:** Releases will still succeed without Zeus preview QR code.

### Zeus Preview Times Out

**Symptoms:**
- "Preview timeout" in logs
- No QR code generated

**Solutions:**
1. Check Zepp service availability
2. Retry the workflow
3. Increase timeout if needed (currently 60 seconds)

### QR Code Not Displayed in Release

**Symptoms:**
- Release created but QR code missing
- "Could not extract preview URL" warning

**Solutions:**
1. Check that `zeus preview` output format hasn't changed
2. Review workflow logs for preview command output
3. Manually test `zeus preview` locally
4. Open an issue if Zeus CLI behavior changed

### Secrets Not Working

**Symptoms:**
- "ZEPP_USERNAME or ZEPP_PASSWORD secrets not set" warning

**Solutions:**
1. Verify secrets are named exactly: `ZEPP_USERNAME` and `ZEPP_PASSWORD`
2. Check they are set as **repository secrets**, not environment variables
3. Verify repository has access to secrets
4. Re-add secrets if needed

## Testing

### Before Merging

1. Configure secrets in your fork/branch
2. Trigger manual workflow dispatch
3. Check workflow logs for successful login
4. Verify release includes Zeus preview QR code
5. Test scanning QR code with Zepp App

### Automated Testing

The workflow includes built-in testing:
- Validates secrets are available (warns if missing)
- Tests Zeus login success
- Validates QR code generation
- Uploads artifacts for verification
- Creates comprehensive release notes

## Future Improvements

Potential enhancements for future versions:

1. **Session Caching**: Save Zeus session between workflow runs to avoid repeated logins
2. **QR Code Preview**: Display QR code in workflow summary
3. **Multiple Device Targets**: Generate QR codes for different watch models
4. **Expiration Handling**: Regenerate QR codes if they expire
5. **Alternative Auth**: Support token-based auth if Zeus CLI adds it

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

This feature was implemented to address the issue: "Zepp login - QR code must point out to Zepp website"

Implementation details:
- Uses `expect` for automated login
- Uses `qrencode` for QR code image generation
- Graceful fallback when secrets unavailable
- Comprehensive error handling and logging
