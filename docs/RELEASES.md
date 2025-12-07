# Release Process

This document describes how to create and publish new releases of ZeppNightscout.

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

The release workflow (`.github/workflows/release.yml`) performs these steps:

1. **Trigger**: 
   - Automatically on tag push matching `v*.*.*`
   - Manually via workflow_dispatch with branch selection
   
2. **Version Calculation**:
   - Reads base version from `app.json` (e.g., "0.1.0")
   - Extracts MAJOR.MINOR (e.g., "0.1")
   - Appends GitHub run number as BUILD (e.g., "0.1.5")
   - Updates `app.json` with the full build version
   
3. **Setup**: Installs Node.js and Zeus CLI

4. **Build**: Compiles the app using `zeus build` with the updated version

5. **Artifacts**: Locates the generated `.zab` file

6. **QR Code**: Generates a QR code pointing to the download URL

7. **Release**: Creates a GitHub release with:
   - Version number including build number (e.g., "0.1.5")
   - Build metadata (run number, branch, base version)
   - Comprehensive release notes
   - QR code embedded in the notes
   - The `.zab` file attached as an artifact
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

## QR Code Feature

The release includes a QR code that users can scan to download the app directly to their phone:

- The QR code encodes the direct download URL
- Users can scan it with any QR code reader
- It points to the `.zab` file in the GitHub release
- Makes installation easier for end users

## Installation for End Users

After a release is published, users can install the app in three ways:

### Option 1: QR Code (Recommended)
1. Go to the [Releases page](https://github.com/iricigor/ZeppNightscout/releases)
2. Open the latest release
3. Scan the QR code with your phone
4. Download the `.zab` file
5. Use the Zepp app to install it on your watch

### Option 2: Direct Download
1. Go to the [Releases page](https://github.com/iricigor/ZeppNightscout/releases)
2. Download the `.zab` file from the latest release
3. Transfer it to your phone
4. Use the Zepp app to install it on your watch

### Option 3: Zeus CLI
1. Download the `.zab` file from the release
2. Use `zeus preview` to generate a QR code
3. Or use `zeus install` to install directly to a connected device

## Troubleshooting

### Release workflow fails

If the release workflow fails:

1. Check the [Actions tab](https://github.com/iricigor/ZeppNightscout/actions)
2. Look at the failed job logs
3. Common issues:
   - Zeus build failed: Check `app.json` syntax
   - Artifact not found: Zeus may have changed output directory
   - QR code generation failed: Check network connectivity
   - Version update failed: Check Node.js is available

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
