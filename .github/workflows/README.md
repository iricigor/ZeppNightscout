# GitHub Actions Workflows

This directory contains automated workflows for the ZeppNightscout project.

## Workflows

### Release Workflow (`release.yml`)

Automated build and release pipeline that creates GitHub releases with Zeus preview QR codes.

**Triggers:**
- Tag push matching `v*.*.*`
- Manual workflow dispatch

**Features:**
- Automatic version numbering
- Zeus CLI build
- Zeus preview QR code generation (requires secrets)
- GitHub release creation with comprehensive notes
- Multiple installation options via QR codes

#### Required Secrets

To enable Zeus preview QR code generation, configure these repository secrets:

| Secret Name | Description | Required |
|-------------|-------------|----------|
| `ZEPP_USERNAME` | Your Zepp developer account email/username | Optional* |
| `ZEPP_PASSWORD` | Your Zepp developer account password | Optional* |

\* If not configured, the workflow will skip Zeus preview QR code generation but still create releases with download QR codes.

#### How to Configure Secrets

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add each secret:
   - Name: `ZEPP_USERNAME`, Value: your Zepp account email
   - Name: `ZEPP_PASSWORD`, Value: your Zepp account password

#### Zepp Developer Account

If you don't have a Zepp developer account:
1. Register at [developers.zepp.com](https://developers.zepp.com/)
2. If you registered with third-party login (Google/Facebook), bind an email and set a password at [user.huami.com](https://user.huami.com/privacy2/#/bindEmail)

#### Security

- Secrets are encrypted by GitHub
- Never exposed in logs or publicly visible
- Only accessible to authorized workflows
- Used for automated Zeus CLI login via expect script

### Test Workflow (`test.yml`)

Automated testing pipeline that runs on every pull request and push.

**Features:**
- JavaScript syntax validation
- Unit tests
- Build validation
- Zeus CLI build test

**No secrets required** - uses offline device cache for Zeus builds.

## Workflow Components

### Zeus CLI Integration

Both workflows use Zeus CLI for building Zepp OS apps:

**Release workflow:**
- Performs Zeus login (if credentials configured)
- Runs `zeus preview` to generate QR codes
- Runs `zeus build` for production builds

**Test workflow:**
- Uses offline device cache
- Runs `zeus build` for validation
- No login required

### QR Code Generation

The release workflow generates two types of QR codes:

1. **Zeus Preview QR Code** (requires login):
   - Direct installation via Zepp App
   - Generated from `zeus preview` command
   - Fastest installation method

2. **Download QR Code** (always available):
   - Downloads `.zab` file
   - Generated from GitHub release URL
   - Works without Zeus credentials

## Troubleshooting

### "ZEPP_USERNAME or ZEPP_PASSWORD secrets not set" warning

This is normal if you haven't configured the secrets. The workflow will continue without generating Zeus preview QR codes.

To fix:
1. Configure the secrets as described above
2. Re-run the workflow

### "Zeus login failed" error

Possible causes:
1. Incorrect credentials
2. Need to bind email/password for third-party login accounts
3. Network connectivity issues
4. Zepp service temporarily unavailable

The workflow will continue and create releases with download QR codes only.

### Zeus preview times out

The workflow uses a 60-second timeout for `zeus preview`. If it times out:
1. Check Zepp service status
2. Retry the workflow
3. Check workflow logs for detailed error messages

## Contributing

When modifying workflows:
1. Test with manual workflow dispatch first
2. Verify secrets are properly masked in logs
3. Check that release artifacts are correctly generated
4. Document any new secrets or requirements
