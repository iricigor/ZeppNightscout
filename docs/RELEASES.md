# Release Process

This document describes how to create and publish new releases of ZeppNightscout.

## Prerequisites

### Required GitHub Secrets

To enable Zeus preview QR code generation in releases, you need to configure the following repository secrets:

1. **ZEPP_APP_TOKEN**: Your Zepp OAuth application token
2. **ZEPP_USER_ID**: Your Zepp user ID
3. **ZEPP_CNAME**: Your Zepp account display name

**To add these secrets:**

1. Go to your repository's **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add the three secrets with their corresponding values

**How to get these values:**

These are OAuth tokens stored by Zeus CLI after login. To obtain them:

1. Run `zeus login` on your local machine and complete the browser OAuth flow
2. After successful login, run: `zeus config list`
3. Look for the values:
   - `____user_zepp_com__token` → use as **ZEPP_APP_TOKEN**
   - `____user_zepp_com__userid` → use as **ZEPP_USER_ID**
   - `____user_zepp_com__cname` → use as **ZEPP_CNAME**

**Note:** If these secrets are not configured, the release workflow will still work but will skip the Zeus preview QR code generation step. You'll see a warning in the workflow logs.

**Security:** These credentials are encrypted and only accessible to GitHub Actions workflows. They are never exposed in logs or publicly visible.

## Version Numbering

ZeppNightscout uses a versioning scheme that combines semantic versioning with build numbers:

- **MAJOR.MINOR.BUILD** (e.g., 0.1.1, 0.1.2, etc.)
- **MAJOR.MINOR**: Set in `app.json` (e.g., 0.1)
- **BUILD**: Automatically assigned from GitHub Actions run number
- The build number increments with each release workflow run

Current base version: **0.1** (builds will be 0.1.1, 0.1.2, 0.1.3, etc.)

### Examples

- First release: `0.1.1` (run #1)
- Second release: `0.1.2` (run #2)
- After updating to 0.2 in app.json: `0.2.3` (run #3)

## Creating a New Release

There are two ways to create a release:

### Method 1: Manual Release (Recommended for Testing)

This method allows you to create a release from any branch, perfect for testing:

1. Go to the [Actions tab](https://github.com/iricigor/ZeppNightscout/actions)
2. Select the "Release" workflow
3. Click "Run workflow"
4. Select the branch to build from (default: main)
5. Click "Run workflow"

The workflow will:
- Build the app with version MAJOR.MINOR.RUN_NUMBER
- Create a pre-release on GitHub
- Generate QR code for download

### Method 2: Tagged Release (For Official Releases)

This method creates an official release from a version tag:

1. **Update Base Version** (if needed)

   Update the version in `app.json` to set the MAJOR.MINOR:
   
   ```json
   // app.json
   "version": {
     "code": 1,
     "name": "0.2.0"
   }
   ```

2. **Commit Version Changes**

   ```bash
   git checkout main
   git pull
   git add app.json
   git commit -m "Bump base version to 0.2"
   git push
   ```

3. **Create and Push Tag**

   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

4. **Automated Release**

   The workflow will automatically:
   - Build with version 0.2.RUN_NUMBER
   - Create an official release (not pre-release)
   - Generate QR code for download
   - Detect the new tag
   - Build the app using Zeus CLI
   - Create a `.zab` file (Zepp App Bundle)
   - Generate a QR code for easy download
   - Create a GitHub release with:
     - Release notes
     - Download link
     - QR code for direct download
     - Installation instructions
     - The `.zab` file as an artifact

5. **Verify the Release**

   - Go to the [Releases page](https://github.com/iricigor/ZeppNightscout/releases)
   - Verify the new release is created
   - Test the download link
   - Scan the QR code to verify it works
   - Download the `.zab` file and test installation

## How It Works

The release workflow (`.github/workflows/release-modular.yml`) performs these steps:

1. **Trigger**: 
   - Automatically on tag push matching `v*.*.*`
   - Manually via workflow_dispatch with branch selection
   
2. **Version Calculation**:
   - Reads base version from `app.json` (e.g., "0.1.0")
   - Extracts MAJOR.MINOR (e.g., "0.1")
   - Appends GitHub run number as BUILD (e.g., "0.1.5")
   - Updates `app.json` with the full build version
   
3. **Setup**: Installs Node.js and Zeus CLI

4. **Zeus Authentication** (if tokens configured):
   - Configures Zeus CLI authentication using `zeus config set`
   - Uses ZEPP_APP_TOKEN, ZEPP_USER_ID, and ZEPP_CNAME secrets
   - Enables Zeus preview QR code generation

5. **Build**: Compiles the app using `zeus build` with the updated version

6. **Zeus Preview QR Code** (if login successful):
   - Runs `zeus preview` to generate a preview URL
   - Creates a QR code image from the preview URL
   - This QR code allows direct installation via Zepp App

7. **Artifacts**: Locates the generated `.zab` file

8. **Download QR Code**: Generates a QR code pointing to the GitHub release download URL

9. **Release**: Creates a GitHub release with:
   - Version number including build number (e.g., "0.1.5")
   - Build metadata (run number, branch, base version)
   - Comprehensive release notes
   - Zeus preview QR code (for direct installation via Zepp App)
   - Download QR code (for downloading .zab file)
   - The `.zab` file attached as an artifact
   - Zeus QR code image attached as an artifact
   - Marked as pre-release for manual triggers, regular release for tags

## Release Types

### Pre-release (Manual Trigger)
- Created from any branch via manual workflow dispatch
- Marked as "pre-release" in GitHub
- Useful for testing and development builds
- Version includes run number (e.g., 0.1.15)

### Official Release (Tag Trigger)
- Created from tags pushed to the repository
- Marked as official release
- Recommended for production/user-facing releases
- Version includes run number (e.g., 0.2.42)

## QR Code Features

The release includes two types of QR codes:

### 1. Zeus Preview QR Code (Recommended)
- Generated from `zeus preview` command
- **Direct installation**: Scan with Zepp App to install directly to your watch
- **Fastest method**: No need to download files manually
- **Requirement**: Zepp developer credentials must be configured in repository secrets
- **How to use**: 
  1. Enable Developer Mode in Zepp App (Profile → Settings → About → tap Zepp icon 7 times)
  2. Open Zepp App → Profile → Your Device → Developer Mode
  3. Tap "Scan" and scan the Zeus Preview QR code
  4. App installs automatically to your watch

### 2. Download QR Code (Fallback)
- Points to the GitHub release download URL
- **For downloading**: Scan to download the `.zab` file to your phone
- **Always available**: Generated even if Zeus credentials are not configured
- **How to use**:
  1. Scan the QR code with any QR reader
  2. Download the `.zab` file
  3. Use Zepp App to install the file

## Installation for End Users

After a release is published, users can install the app in four ways:

### Option 1: Zeus Preview QR Code (Fastest) ⭐
1. Go to the [Releases page](https://github.com/iricigor/ZeppNightscout/releases)
2. Open the latest release
3. Enable Developer Mode in Zepp App (Profile → Settings → About → tap Zepp icon 7 times)
4. Open Zepp App → Profile → Your Device → Developer Mode
5. Tap "Scan" and scan the Zeus Preview QR code
6. App installs directly to your watch!

### Option 2: Download QR Code
1. Go to the [Releases page](https://github.com/iricigor/ZeppNightscout/releases)
2. Open the latest release
3. Scan the Download QR code with your phone
4. Download the `.zab` file
5. Use the Zepp app to install it on your watch

### Option 3: Direct Download
1. Go to the [Releases page](https://github.com/iricigor/ZeppNightscout/releases)
2. Download the `.zab` file from the latest release
3. Transfer it to your phone
4. Use the Zepp app to install it on your watch

### Option 4: Zeus CLI
1. Download the `.zab` file from the release
2. Use `zeus preview` to generate a QR code
3. Or use `zeus install` to install directly to a connected device

## Troubleshooting

### Zeus authentication failed

If you see warnings about Zeus authentication failing:

1. **Check secrets are configured**: Verify that `ZEPP_APP_TOKEN`, `ZEPP_USER_ID`, and `ZEPP_CNAME` are set in repository secrets
2. **Verify token values**: Make sure the tokens are obtained from a successful `zeus login` on your local machine
3. **Refresh tokens**: If tokens are old, run `zeus login` again and update the secrets with fresh values
4. **Check token format**: Ensure no extra spaces or characters were added when copying the token values

**Note:** If Zeus authentication fails, the release will still succeed but without the Zeus Preview QR code. Users can still use the Download QR code.

### Release workflow fails

If the release workflow fails:

1. Check the [Actions tab](https://github.com/iricigor/ZeppNightscout/actions)
2. Look at the failed job logs
3. Common issues:
   - Zeus build failed: Check `app.json` syntax
   - Artifact not found: Zeus may have changed output directory
   - QR code generation failed: Check network connectivity
   - Version update failed: Check Node.js is available
   - Zeus authentication failed: Check ZEPP_APP_TOKEN, ZEPP_USER_ID, and ZEPP_CNAME secrets

### Tag already exists

If you need to recreate a tag:

```bash
# Delete local tag
git tag -d v0.2.0

# Delete remote tag
git push --delete origin v0.2.0

# Create new tag
git tag v0.2.0
git push origin v0.2.0
```

Note: The build number will still increment based on the workflow run number.

## Understanding Build Numbers

The build number is the GitHub Actions run number for the Release workflow:

- It increments for every run of the workflow
- It's independent of the base version in `app.json`
- It provides a unique identifier for each build
- It helps track which build a user has installed

Example progression:
1. Run #1: Version 0.1.1
2. Run #2: Version 0.1.2
3. Update base to 0.2 in app.json
4. Run #3: Version 0.2.3
5. Run #4: Version 0.2.4

## Monitoring Releases

- Watch the [Releases page](https://github.com/iricigor/ZeppNightscout/releases) for new versions
- Subscribe to release notifications in GitHub
- Check the [Actions tab](https://github.com/iricigor/ZeppNightscout/actions) for workflow status
