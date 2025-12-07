# Testing Guide

This guide explains how to test the ZeppNightscout app functionality in both local development and on your personal watch.

## Table of Contents

- [Overview](#overview)
- [Continuous Integration](#continuous-integration)
- [Prerequisites](#prerequisites)
- [Local Development Testing](#local-development-testing)
- [Simulator Testing](#simulator-testing)
- [Testing on Personal Watch](#testing-on-personal-watch)
- [Testing Checklist](#testing-checklist)
- [Troubleshooting](#troubleshooting)

## Overview

The ZeppNightscout app can be tested at multiple levels:

1. **Code-level testing**: Verify JavaScript code functions correctly
2. **Simulator testing**: Test the app in the Zepp OS simulator
3. **Device testing**: Deploy and test on your actual watch
4. **Automated CI testing**: GitHub Actions runs tests on every PR

## Continuous Integration

This project uses GitHub Actions to automatically run tests on every pull request and push to main/master branches.

### What Gets Tested

When you open a PR or push code, the following tests run automatically:

1. **JavaScript Syntax Check**: Validates all JS files for syntax errors
2. **Unit Tests**: Runs the data parser test suite (26 assertions)
3. **Help Command**: Verifies the help script works correctly

### Viewing Test Results

1. Go to the **Pull Requests** tab in GitHub
2. Select your PR
3. Scroll down to the **Checks** section
4. Click on **Test** to see detailed results

All tests must pass before merging a PR.

### GitHub Actions Workflow

The test workflow is defined in `.github/workflows/test.yml` and includes:

```yaml
- Check JavaScript syntax
- Run unit tests
- Test help command
```

To run the same tests locally before pushing:

```bash
npm run test:syntax  # Check syntax
npm test             # Run unit tests
npm run help         # Test help command
```

## Prerequisites

### For Local Development

- Node.js 20 or later
- npm or yarn package manager
- Git
- VS Code (recommended) or any text editor

### For Simulator Testing

- Zepp OS Developer Tools
- Zeus CLI (Command-line tool for Zepp OS)
- A Zepp developer account

### For Device Testing

- A compatible Zepp OS watch (e.g., Amazfit GTR 3, GTR 4, etc.)
- Zepp app installed on your phone
- Developer mode enabled on your watch
- Physical connection (via USB or WiFi debugging)

## Local Development Testing

### 1. Setup Development Environment

If using GitHub Codespaces (recommended):

```bash
# Open this project in Codespaces
# The environment is automatically configured
```

If developing locally:

```bash
# Clone the repository
git clone https://github.com/iricigor/ZeppNightscout.git
cd ZeppNightscout

# Install dependencies (if any)
npm install
```

### 2. Code Validation

#### Check Code Syntax

```bash
# Run linting (if configured)
npm run lint

# Or check syntax with Node.js
node --check page/index.js
node --check app-side/index.js
node --check shared/message.js
```

#### Manual Code Review

Review the following key files:

- `page/index.js` - Device-side UI logic
- `app-side/index.js` - App-side service and API integration
- `shared/message.js` - Message communication layer
- `app.json` - App configuration

### 3. Configuration Testing

#### Test API URL Configuration

Edit `page/index.js` and set your Nightscout URL:

```javascript
state: {
  apiUrl: 'https://your-nightscout-instance.herokuapp.com',
  // ...
}
```

#### Verify App Manifest

Check `app.json` for proper configuration:

```json
{
  "app": {
    "appId": "com.nightscout.zepp",
    "appName": "Nightscout",
    "version": {
      "code": 1,
      "name": "1.0.0"
    }
  },
  "permissions": [
    "internet",
    "data:user.info"
  ]
}
```

### 4. Mock Testing (Code Level)

You can test the data parsing logic without a simulator:

```bash
# Create a test script
node test-parser.js
```

Example test script (`test-parser.js` - create this in the project root):

```javascript
// Test data parsing logic
const mockApiResponse = [
  {
    sgv: 120,
    direction: 'Flat',
    dateString: new Date().toISOString(),
    date: Date.now()
  },
  {
    sgv: 118,
    direction: 'Flat',
    dateString: new Date(Date.now() - 300000).toISOString(),
    date: Date.now() - 300000
  }
];

// Test the parsing logic (extracted from app-side/index.js)
function parseNightscoutData(entries) {
  if (!entries || entries.length === 0) {
    return null;
  }

  const latest = entries[0];
  const previous = entries[1];

  let delta = 0;
  let deltaDisplay = '--';
  if (previous && latest.sgv && previous.sgv) {
    delta = latest.sgv - previous.sgv;
    deltaDisplay = (delta >= 0 ? '+' : '') + delta;
  }

  const trendMap = {
    'DoubleUp': '⇈',
    'SingleUp': '↑',
    'FortyFiveUp': '↗',
    'Flat': '→',
    'FortyFiveDown': '↘',
    'SingleDown': '↓',
    'DoubleDown': '⇊',
    'NOT COMPUTABLE': '-',
    'RATE OUT OF RANGE': '⇕'
  };
  const trend = trendMap[latest.direction] || '?';

  const dataPoints = entries.map(entry => entry.sgv || 0);

  return {
    currentBG: latest.sgv ? latest.sgv.toString() : '--',
    trend: trend,
    delta: deltaDisplay,
    dataPoints: dataPoints,
    rawData: latest
  };
}

console.log('Testing data parser...');
const result = parseNightscoutData(mockApiResponse);
console.log('Result:', JSON.stringify(result, null, 2));

// Verify results
console.assert(result.currentBG === '120', 'Current BG should be 120');
console.assert(result.trend === '→', 'Trend should be Flat arrow');
console.assert(result.delta === '+2', 'Delta should be +2');
console.log('✓ All assertions passed!');
```

Run the test:

```bash
node test-parser.js
```

## Simulator Testing

### 1. Install Zeus CLI

The Zeus CLI is the official command-line tool for Zepp OS development.

```bash
# Install Zeus CLI globally
npm install -g @zeppos/zeus-cli
```

### 2. Initialize Zeus Project

If not already initialized:

```bash
# Initialize Zeus in the project
zeus init
```

### 3. Build the App

```bash
# Build the app for simulator
zeus build

# Or for production
zeus build --production
```

### 4. Run in Simulator

```bash
# Start the simulator
zeus dev

# The simulator will open with your app loaded
```

### 5. Test in Simulator

Once the simulator is running:

1. **Test UI Elements**:
   - Verify all text displays correctly
   - Check button responsiveness
   - Verify graph canvas renders

2. **Test API Integration**:
   - Click the "Verify" button to test URL verification
   - Click "Fetch Data" to test data fetching
   - Verify data displays correctly after fetch

3. **Test Error Handling**:
   - Try with an invalid URL
   - Test with no internet connection (if simulator supports it)
   - Verify error messages display correctly

### 6. Simulator Debugging

The simulator provides debugging capabilities:

```bash
# View console logs
# Check the simulator console for console.log() output
```

## Testing on Personal Watch

### 1. Enable Developer Mode

On your Zepp OS watch:

1. Go to **Settings** → **System** → **About**
2. Tap the **Version Number** 7 times to enable Developer Mode
3. Go back to **Settings** → **Developer Options**
4. Enable **ADB Debugging** or **WiFi Debugging**

### 2. Connect Watch to Computer

#### Via USB (if supported):

```bash
# Check if watch is connected
adb devices
```

#### Via WiFi:

```bash
# Find your watch IP address in Developer Options
# Connect to the watch
adb connect <watch-ip-address>:5555

# Verify connection
adb devices
```

### 3. Build for Device

```bash
# Build the app
zeus build --production

# This creates a .zip file in the output directory
```

### 4. Install on Watch

Using Zeus CLI:

```bash
# Install to connected device
zeus install

# Or manually install the .zip file
zeus install --file output/target/com.nightscout.zepp.zip
```

Using Zepp App (alternative method):

1. Open the Zepp app on your phone
2. Go to **Profile** → **My Apps**
3. Select **Install App from Package**
4. Navigate to the built `.zip` file
5. Install the app

### 5. Test on Watch

Once installed on your watch:

1. **Launch the App**:
   - Find "Nightscout" in your watch apps
   - Open it

2. **Configure Nightscout URL**:
   - The current version shows the URL in the UI
   - For now, you need to rebuild with your URL in the code
   - Future versions will have a settings page

3. **Test URL Verification**:
   - Tap the "Verify" button
   - Wait for the verification result
   - Should show "✓ URL verified" if successful

4. **Test Data Fetching**:
   - Tap "Fetch Data" button
   - Wait for data to load (may take a few seconds)
   - Verify glucose value displays
   - Check trend arrow is correct
   - Verify delta calculation
   - Check last update time
   - Verify graph displays correctly

5. **Test Real-World Usage**:
   - Test with your actual Nightscout instance
   - Verify data matches your Nightscout dashboard
   - Test multiple times throughout the day
   - Verify trend arrows match expectations
   - Check graph accuracy with multiple readings

### 6. Device Debugging

View logs from the watch:

```bash
# View device logs
adb logcat | grep Nightscout

# Or view all logs
adb logcat
```

## Testing Checklist

Use this checklist to ensure thorough testing:

### UI Testing

- [ ] App icon displays correctly
- [ ] Title renders properly
- [ ] API URL label shows correct text
- [ ] Verify button is clickable and positioned correctly
- [ ] Verification status text updates correctly
- [ ] Large BG value displays in correct size and color
- [ ] Trend arrow shows correct symbol
- [ ] Delta value calculates and displays correctly
- [ ] Last update time formats properly
- [ ] Graph canvas renders without errors
- [ ] Fetch Data button is clickable
- [ ] All UI elements fit on screen without overlap

### Functionality Testing

#### URL Verification
- [ ] Valid Nightscout URL returns success (green checkmark)
- [ ] Invalid URL returns error (red X)
- [ ] Verification status message updates correctly
- [ ] Network errors handled gracefully

#### Data Fetching
- [ ] Button triggers data fetch
- [ ] Loading state shows while fetching
- [ ] Current BG updates with fetched value
- [ ] Trend arrow matches Nightscout data
- [ ] Delta calculates correctly (current - previous)
- [ ] Last update time is accurate
- [ ] Graph plots all 200 data points
- [ ] Graph scales correctly to data range
- [ ] Multiple fetches work without issues

#### Error Handling
- [ ] Network timeout shows error message
- [ ] Invalid API response handled
- [ ] Empty data response handled
- [ ] Console errors are logged properly
- [ ] App doesn't crash on errors

### Integration Testing

- [ ] Device-to-app-side messaging works
- [ ] App-side-to-device messaging works
- [ ] HTTP requests to Nightscout succeed
- [ ] JSON parsing works correctly
- [ ] Data transformation is accurate
- [ ] Watch phone connection is stable

### Performance Testing

- [ ] App launches quickly
- [ ] UI renders smoothly
- [ ] Data fetching doesn't freeze UI
- [ ] Graph drawing is efficient
- [ ] Memory usage is acceptable
- [ ] Battery impact is minimal

### Real-World Testing

- [ ] Accurate glucose readings compared to Nightscout
- [ ] Trend arrows match CGM device
- [ ] Graph visualization is helpful
- [ ] App usable in daily routine
- [ ] Updates work when switching from other apps
- [ ] Data refreshes appropriately

## Troubleshooting

### Common Issues

#### "Cannot connect to simulator"

**Solution:**
```bash
# Restart Zeus CLI
zeus dev --reset

# Or reinstall Zeus CLI
npm uninstall -g @zeppos/zeus-cli
npm install -g @zeppos/zeus-cli
```

#### "ADB device not found"

**Solution:**
```bash
# Check USB connection
adb devices

# Restart ADB server
adb kill-server
adb start-server

# For WiFi, reconnect
adb connect <watch-ip>:5555
```

#### "App crashes on launch"

**Solution:**
1. Check console logs: `adb logcat | grep Nightscout`
2. Verify all imports are correct
3. Check app.json configuration
4. Rebuild the app: `zeus build --production`

#### "No data displays"

**Solution:**
1. Verify Nightscout URL is correct
2. Check internet connection on phone
3. Test URL in browser: `https://your-nightscout.com/api/v1/status`
4. Check permissions in app.json include `"internet"`
5. Review app-side logs for API errors

#### "Graph not rendering"

**Solution:**
1. Verify dataPoints array has values
2. Check canvas widget creation
3. Verify drawing code has no errors
4. Test with sample data first

#### "Build fails"

**Solution:**
```bash
# Clear build cache
rm -rf output/
rm -rf .zeus/

# Rebuild
zeus build
```

### Getting Help

If you encounter issues:

1. **Check Documentation**:
   - [Zepp OS Official Docs](https://docs.zepp.com/)
   - [Zeus CLI Documentation](https://github.com/zepp-health/zeppos-docs)
   - This repository's README.md and DEVELOPMENT.md

2. **Review Logs**:
   - Simulator console logs
   - Device logs via `adb logcat`
   - Browser console (for web debugging)

3. **Community Support**:
   - Zepp OS Developer Forum
   - GitHub Issues in this repository
   - Nightscout community

## Testing Best Practices

1. **Test Early, Test Often**:
   - Test after each code change
   - Use the simulator for rapid iteration
   - Deploy to device for final validation

2. **Start Simple**:
   - Begin with UI testing
   - Then test with mock data
   - Finally test with real Nightscout API

3. **Document Issues**:
   - Keep track of bugs found
   - Note steps to reproduce
   - Document workarounds

4. **Version Control**:
   - Commit working code frequently
   - Tag stable versions
   - Create branches for experimental features

5. **Security Testing**:
   - Never commit API tokens to code
   - Test with read-only Nightscout tokens
   - Verify HTTPS is used for all API calls

## Next Steps

After successful testing:

1. **Optimize Performance**: Profile and improve slow operations
2. **Add Features**: Implement alarms, settings page, etc.
3. **Polish UI**: Refine colors, layouts, animations
4. **Write Tests**: Add automated unit tests
5. **Prepare Release**: Package for public distribution

## Related Documentation

- [README.md](./README.md) - Project overview and features
- [DEVELOPMENT.md](./DEVELOPMENT.md) - Development setup and workflow
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical architecture details
- [Zepp OS Documentation](https://docs.zepp.com/) - Official Zepp OS docs
