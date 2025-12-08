# Release Workflow Modularization

This document describes the modular structure of the release workflow.

## Overview

The release workflow has been split into reusable components to improve maintainability, readability, and testability.

## Structure

### Main Workflow Files

1. **`.github/workflows/release.yml`** - Original workflow (fixed YAML syntax error)
2. **`.github/workflows/release-modular.yml`** - New modular workflow using composite actions

### Composite Actions

Located in `.github/actions/`, these are reusable workflow components:

#### 1. Version Management (`version-management/`)
- Gets version information from `app.json`
- Updates `app.json` with build version
- Outputs: `version`, `tag`, `base_version`

#### 2. Zeus CLI Setup (`zeus-setup/`)
- Installs Zeus CLI
- Configures authentication with Zepp credentials
- Outputs: `zeus_login_success`

#### 3. Zeus Build and Preview (`zeus-build-preview/`)
- Builds the app with Zeus CLI
- Generates Zeus preview QR code
- Outputs: `preview_url`, `zeus_qr_generated`

#### 4. Release Preparation (`release-preparation/`)
- Finds build artifacts
- Generates download QR codes
- Creates release notes
- Outputs: `artifact_path`, `artifact_name`, `download_url`, `qr_url`, `release_files`

### Helper Scripts

Located in `scripts/`:

1. **`generate-zeus-preview.sh`** - Automates Zeus preview QR code generation using expect
2. **`generate-release-notes.sh`** - Generates release notes with installation instructions

## Benefits

### Before (Original Workflow)
- 433 lines in a single file
- Complex nested logic with heredocs
- Difficult to test individual components
- YAML syntax issues with heredocs

### After (Modular Workflow)
- 91 lines in main workflow (78% reduction)
- 4 reusable composite actions
- 2 helper shell scripts
- Clear separation of concerns
- Easy to test and maintain
- No YAML syntax issues

## Migration Path

### Option 1: Use Modular Workflow (Recommended)
Replace `release.yml` with `release-modular.yml`:
```bash
mv .github/workflows/release.yml .github/workflows/release-legacy.yml
mv .github/workflows/release-modular.yml .github/workflows/release.yml
```

### Option 2: Keep Both
Keep both workflows for gradual migration:
- `release.yml` - Stable, original workflow (with YAML fix)
- `release-modular.yml` - New modular workflow for testing

## Testing

To test the modular workflow:
1. Trigger manually via workflow_dispatch
2. Push a test tag: `git tag v0.1.999 && git push origin v0.1.999`
3. Compare outputs with original workflow

## Future Improvements

- Add unit tests for helper scripts
- Create additional composite actions for other workflows
- Add workflow_call triggers to make actions reusable across repositories
- Add input validation and error handling
