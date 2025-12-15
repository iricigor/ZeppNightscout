# Viewing App-Side Logs

This guide explains how to view logs from the app-side service, which runs on your phone (in the Zepp companion app), not on the watch.

## Understanding Zepp OS Architecture

```
┌─────────────────┐           ┌──────────────────────┐
│   Watch/Device  │  ◄─BLE─►  │   Phone (Zepp App)   │
│                 │           │                      │
│  Device-Side    │           │   App-Side Service   │
│  (page/*.js)    │           │   (app-side/*.js)    │
│                 │           │                      │
│  UI & Events    │           │  API Calls & Logic   │
└─────────────────┘           └──────────────────────┘
        ↓                              ↓
    Watch Logs                    Phone Logs
   (adb logcat)                 (Harder to access)
```

## Key Distinction

- **Device-Side Logs**: Run on the watch, easy to view via `adb logcat`
- **App-Side Logs**: Run on the phone inside Zepp app, harder to access

## Methods to View App-Side Logs

### Method 1: Simulator (Easiest for Development)

When running in the Zeus simulator, app-side logs appear in the same console:

```bash
# Start simulator
zeus dev

# Watch the console output
# You'll see both device-side and app-side console.log() output
```

**Example output:**
```
[Device] App starting
[Device] Page Navigation: page/index - init
[App-Side] App-side service initialized
[Device] Get secret button clicked - sending message to app-side
[App-Side] Received message: {"type":"GET_SECRET"}
[App-Side] Getting secret token
[App-Side] Secret token response received
[Device] Received message from app-side: {"type":"response","data":{...}}
```

### Method 2: Android Phone (ADB Logcat)

If you're using an Android phone paired with your watch, you can view Zepp app logs via ADB:

```bash
# Connect your Android phone via USB
adb devices

# View all Zepp app logs
adb logcat | grep -i zepp

# Filter for your app specifically
adb logcat | grep -E "jsapp.*1000089"

# View all JavaScript console logs
adb logcat | grep "jsapp"
```

**Requirements:**
- Android phone with USB debugging enabled
- USB cable to connect phone to computer
- ADB installed on your computer

**Enable USB Debugging on Android:**
1. Go to Settings → About Phone
2. Tap "Build Number" 7 times to enable Developer Options
3. Go to Settings → Developer Options
4. Enable "USB Debugging"
5. Connect phone via USB and accept the debugging prompt

### Method 3: iOS Phone (Not Available)

Unfortunately, **there is no easy way to view app-side logs on iOS** because:
- iOS doesn't allow ADB-style access to app logs
- Zepp app doesn't expose logs through any interface
- Console.log output from app-side is not accessible

**Workarounds for iOS:**
1. Use the simulator for development and debugging
2. Test on an Android phone for log access
3. Add remote logging to your app-side code (see Method 4)

### Method 4: Remote Logging Service (Advanced)

For production debugging on iOS or when you can't use ADB, you can add remote logging to your app-side code:

```javascript
// In app-side/index.js

// Add a remote logging function
function remoteLog(message, data) {
  // Send logs to a remote server
  fetch({
    url: 'https://your-logging-service.com/log',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      timestamp: new Date().toISOString(),
      appId: 1000089,
      message: message,
      data: data
    })
  }).catch(err => {
    // Fail silently if logging service is down
  });
}

// Use it alongside console.log
setupMessageHandlers() {
  messaging.peerSocket.addListener('message', (data) => {
    console.log('Received message:', data);
    remoteLog('Received message', data);  // Also send to remote service
    
    if (data.type === MESSAGE_TYPES.GET_SECRET) {
      this.getSecret();
    }
  });
}
```

**Remote Logging Services:**
- [Logtail](https://logtail.com/)
- [Papertrail](https://www.papertrail.com/)
- [LogDNA](https://www.logdna.com/)
- Your own server endpoint

### Method 5: Zeus Preview QR Code with Simulator Logs

When using `zeus preview`, you can still see logs if you have the simulator running:

```bash
# Terminal 1: Start simulator (for logs)
zeus dev

# Terminal 2: Create preview QR
zeus preview

# Scan QR code and install to watch
# Logs will appear in Terminal 1
```

## What App-Side Logs Look Like

App-side logs from `app-side/index.js` include:

```javascript
// Initialization
console.log('App-side service initialized');

// Message reception
console.log('Received message:', data);

// API calls
console.log('Fetching from Nightscout:', apiUrl);
console.log('Verifying Nightscout URL:', apiUrl);
console.log('Getting secret token');

// Responses
console.log('API response received');
console.log('Secret token response received');
console.log('Verification response received');

// Errors
console.error('Fetch error:', error);
console.error('Get secret error:', error);
console.error('Verification error:', error);
```

## Debugging App-Side Issues

### Issue: "No response from app-side"

**Steps to debug:**

1. **Check simulator logs** (easiest):
   ```bash
   zeus dev
   ```
   Look for:
   - `App-side service initialized` - Service started?
   - `Received message:` - Message received from device?
   - Any error messages

2. **Check Android phone logs** (if on real device):
   ```bash
   adb logcat | grep "jsapp.*1000089"
   ```
   Look for the same messages as above

3. **Verify messaging is working**:
   - Device logs should show: `Message sent successfully to app-side`
   - App-side logs should show: `Received message: {"type":"GET_SECRET"}`
   - App-side logs should show: `Getting secret token`
   - Device logs should show: `Received message from app-side`

### Issue: "TypeError or API errors in app-side"

**In simulator:**
```bash
zeus dev
# Look for red error messages in console
# Check stack traces for line numbers
```

**On Android phone:**
```bash
adb logcat | grep -i error
adb logcat | grep -i exception
```

## Quick Reference

| Scenario | Best Method | Command |
|----------|-------------|---------|
| Development | Simulator | `zeus dev` |
| Android Phone Testing | ADB Logcat | `adb logcat \| grep jsapp` |
| iOS Phone Testing | Simulator only | `zeus dev` |
| Production Debugging | Remote Logging | Add custom logging service |
| Watch Logs Only | ADB to Watch | `adb logcat \| grep Nightscout` |

## Common Log Messages

### Normal Operation

```
[App-Side] App-side service initialized
[App-Side] App-side service running
[App-Side] Received message: {"type":"GET_SECRET"}
[App-Side] Getting secret token
[App-Side] Secret token response received
```

### Error Messages

```
[App-Side] Fetch error: Network request failed
[App-Side] Get secret error: Timeout
[App-Side] JSON parse error: Unexpected token
[App-Side] Verification error: Connection refused
```

## Additional Resources

- [TESTING.md](TESTING.md) - Comprehensive testing guide
- [TESTING-QUICK-REFERENCE.md](TESTING-QUICK-REFERENCE.md) - Quick command reference
- [DEVICE-TO-APP-SIDE-COMMUNICATION.md](DEVICE-TO-APP-SIDE-COMMUNICATION.md) - Message architecture
- [Zeus CLI Documentation](https://docs.zepp.com/docs/guides/tools/cli/)

## Summary

**For most development work**: Use `zeus dev` simulator - it shows both device-side AND app-side logs in the same console.

**For real device testing on Android**: Use `adb logcat | grep jsapp` to see app-side logs from the Zepp app running on your phone.

**For real device testing on iOS**: No direct log access - rely on simulator testing or add remote logging for production debugging.
