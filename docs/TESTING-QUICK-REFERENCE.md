# Quick Testing Reference

Quick reference for common testing commands and workflows.

## Continuous Integration

**GitHub Actions automatically runs tests on all PRs**

- ✅ JavaScript syntax validation
- ✅ Unit tests (26 assertions)
- ✅ Build validation (31 assertions)
- ✅ Actual app build with Zeus CLI
- ✅ Command verification

View results in PR → Checks section.

## Prerequisites

```bash
# Install Zeus CLI (Zepp OS official tool)
npm install -g @zeppos/zeus-cli
```

## Local Testing

```bash
# Run data parser tests
npm test

# Check JavaScript syntax
npm run test:syntax

# Validate build requirements
npm run test:build

# View available commands
npm run help
```

## Simulator Testing

```bash
# Start development with simulator
zeus dev

# Build without simulator
zeus build

# Build for production
zeus build --production
```

## Quick Testing with QR Code (Easiest!)

```bash
# Login to Zeus (one-time setup)
zeus login

# Generate QR code and install to watch
zeus preview
```

**Steps:**
1. Run `zeus preview` in your terminal
2. Select your watch model (e.g., gtr-3)
3. A QR code will be displayed in the terminal
4. Open Zepp App → Profile → Your Device → Developer Mode
5. Tap "Scan" and scan the QR code
6. App installs directly to your watch!

**Note:** Developer Mode must be enabled in Zepp App (tap Zepp icon 7 times in Profile → Settings → About).

## Device Testing

### Connect Device

```bash
# Via WiFi (find IP in watch Developer Options)
adb connect <watch-ip>:5555

# Via USB
adb devices

# Verify connection
adb devices
```

### Install to Device

```bash
# Build and install
zeus build --production
zeus install

# View logs
adb logcat | grep Nightscout
```

## Testing Checklist

### Before Committing
- [ ] `npm run test:syntax` - No syntax errors
- [ ] `npm test` - All tests pass
- [ ] `npm run test:build` - Build requirements validated
- [ ] Code reviewed manually

### Before Deploying
- [ ] Test in simulator
- [ ] UI elements display correctly
- [ ] API integration works
- [ ] Error handling works

### On Device
- [ ] App installs successfully
- [ ] App launches without crashes
- [ ] Data fetches from Nightscout
- [ ] Graph displays correctly
- [ ] Trend arrows accurate

## Common Issues

| Issue | Solution |
|-------|----------|
| Simulator won't start | `zeus dev --reset` |
| ADB device not found | `adb kill-server && adb start-server` |
| Build fails | `rm -rf output/ .zeus/ && zeus build` |
| Can't connect to watch | Enable Developer Mode and ADB Debugging in watch settings |

## More Information

See [TESTING.md](TESTING.md) for comprehensive testing instructions.
