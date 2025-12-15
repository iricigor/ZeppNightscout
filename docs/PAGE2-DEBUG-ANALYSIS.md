# Page 2 Communication Issue - Debug Analysis

## Problem Statement

The app is not crashing but still shows error "not a function" and is not receiving responses from app-side when the "get secret" button is clicked on page 2.

## Historical Attempts (Last 10 PRs)

### PR #184 - Initial Implementation
**Approach:** Device-to-app-side communication with globalData pattern
**What was tried:**
- Used `getApp()._options.globalData` to access messageBuilder
- Used `hmBle.createListener()` for receiving messages
- Used `hmBle.send()` for sending messages

**Why it failed:**
- `getApp()._options.globalData` - incorrect path (should be `getApp().globalData`)
- `hmBle.createListener()` - this method doesn't exist in Zepp OS

### PR #186 - First Fix Attempt
**Approach:** Fixed the listener method
**What was tried:**
- Changed `hmBle.createListener()` to `hmBle.on('message', ...)`
- Added type-safe parsing for received data

**Why it failed:**
- `hmBle.on()` method also doesn't exist in Zepp OS device-side API

### PR #187 - Second Fix Attempt
**Approach:** Use standard @zos/ble module  
**What was tried:**
- Imported `@zos/ble` in device page (page/page2.js)
- Used `messaging.peerSocket.send()` for sending
- Used `messaging.peerSocket.addListener('message', ...)` for receiving
- Fixed globalData access to `getApp().globalData`

**Why it failed:**
- **CRITICAL**: ES6 imports (`import * as messaging from '@zos/ble'`) cause app to crash with `ReferenceError: '__$RQR$__' is not defined`
- Device page files cannot use ES6 imports - they must use global objects

### PR #189 - Third Fix Attempt (Current State)
**Approach:** Use global hmBle object without imports
**What was tried:**
- Removed ES6 import from page/page2.js
- Used `hmBle.createConnect(callback)` for receiving messages
- Used `hmBle.send(buffer, size)` with buffer conversion for sending
- Added buffer conversion: `hmBle.str2buf()` and `hmBle.buf2str()`
- Added `hmBle.disConnect()` cleanup in onDestroy

**Current status:**
- ✅ App doesn't crash
- ❌ Shows "not a function" error
- ❌ No response received from app-side
- ❌ Button stuck in "Loading..." state

## Current Issue Analysis

**Symptoms:**
1. "TypeError: not a function" appears in logs
2. App-side doesn't receive the message OR
3. Device-side doesn't receive the response

**Possible causes:**
1. `hmBle.createConnect()` might be the wrong method or have incorrect signature
2. Buffer conversion might be failing
3. Message format might be incompatible
4. Timing issue - listener not set up before message is received

## What We Haven't Tried Yet

### Option 1: Direct hmBle.mstOnConnect Pattern
Some Zepp OS examples use a different pattern:
```javascript
hmBle.mstPrepare();
hmBle.mstOnConnect = function(index, data, size) {
  // Handle incoming data
};
```

### Option 2: Simpler Send Without Buffer Conversion
Try sending as string directly:
```javascript
hmBle.send(JSON.stringify(message));
```

### Option 3: Check Connection State
Verify BLE is actually connected before sending:
```javascript
const isConnected = hmBle.isConnected();
if (!isConnected) {
  hmBle.connect();
}
```

### Option 4: Use Different Message Encoding
Instead of JSON, try simpler encoding:
```javascript
// Send just the message type as string
hmBle.send('GET_SECRET');
```

## Current Implementation with Extensive Logging

The current code now includes extensive logging to help identify the exact issue:

### At Init:
- ✅ Logs getApp() availability
- ✅ Logs globalData existence and contents  
- ✅ Logs messageBuilder and MESSAGE_TYPES types
- ✅ Logs all hmBle methods and their types

### When Sending Message:
- ✅ Logs hmBle availability
- ✅ Logs all hmBle methods (send, str2buf, buf2str, etc.)
- ✅ Logs message string and length
- ✅ Logs buffer creation success/failure
- ✅ Logs buffer byte length
- ✅ Logs send result
- ✅ Catches and logs all errors with full details

### When Receiving Message:
- ✅ Logs callback invocation with parameters
- ✅ Logs data type and value
- ✅ Logs each step of buffer-to-string conversion
- ✅ Logs JSON parsing
- ✅ Logs response data structure
- ✅ Catches and logs all errors with full details

## How to Debug

### Step 1: Run the app and collect logs
```bash
# In simulator
zeus dev

# Or on real device
adb logcat | grep Nightscout
```

### Step 2: Look for these log patterns

**Page 2 initialization:**
```
=== PAGE2 INIT START ===
Checking getApp(): EXISTS
app instance: EXISTS
app.globalData: EXISTS
globalData keys: messageBuilder, MESSAGE_TYPES
messageBuilder: function
MESSAGE_TYPES: object
```

**BLE setup:**
```
=== BLE RECEIVE SETUP START ===
typeof hmBle: object
typeof hmBle.createConnect: function
createConnect result: [value]
=== BLE RECEIVE SETUP END ===
```

**Message sending:**
```
=== BLE SEND START ===
typeof hmBle: object
hmBle.send: function
hmBle.str2buf: function
Message string: {"type":"request","messageType":"GET_SECRET"}
Buffer created: YES
Buffer byteLength: [number]
hmBle.send() result: [value]
=== BLE SEND END ===
```

**Message receiving:**
```
=== BLE MESSAGE RECEIVED ===
Callback invoked with index: [number] size: [number]
data type: object
Buffer converted, string length: [number]
Data string: {"type":"response","data":{...}}
JSON parsed successfully
Parsed data: {...}
=== BLE MESSAGE RECEIVED END ===
```

### Step 3: Identify the failure point

**If "not a function" error appears:**
- Check which hmBle method is being called when error occurs
- The log will show: `Error name: TypeError`, `Error message: X is not a function`

**If message sent but no response:**
- Check if app-side logs show message received
- Check if BLE MESSAGE RECEIVED callback is ever invoked

**If callback not invoked:**
- Check if `createConnect result` is undefined or null
- This means the listener was not set up correctly

## Next Steps Based on Logs

### If hmBle.createConnect is not a function:
Try alternative approaches from "Option 1" or "Option 3" above

### If buffer conversion fails:
Try "Option 2" - send without buffer conversion

### If callback never invoked but send succeeds:
Check app-side is actually sending response back

### If callback invoked but parsing fails:
Check data format - may need different parsing approach

## Alternative Implementations Created

To help diagnose and fix the issue, I've created two additional files:

### 1. page/page2-alternative.js
An alternative implementation that tries multiple BLE communication patterns:
- **Direct string send** without buffer conversion
- **Buffer send** with conversion (current approach)
- **createConnect** listener (current approach)
- **mstOnConnect** pattern (alternative)
- **onMessage** callback (alternative)

### 2. page/ble-inspector.js  
A diagnostic page that inspects and reports all available BLE APIs:
- Lists all methods on the `hmBle` object
- Checks for specific methods we need
- Reports types and availability
- Can be used to see what's actually available at runtime

## How to Use Alternative Implementation

To test the alternative page2 implementation:

1. Temporarily rename current page2.js:
   ```bash
   mv page/page2.js page/page2-original.js
   mv page/page2-alternative.js page/page2.js
   ```

2. Build and run:
   ```bash
   zeus build
   zeus install
   # Or: zeus dev
   ```

3. Check logs for which pattern works

4. Once identified, restore and update original:
   ```bash
   mv page/page2.js page/page2-test-results.js
   mv page/page2-original.js page/page2.js
   # Update page2.js with working pattern
   ```

## How to Use BLE Inspector

To see what BLE APIs are actually available:

1. Add inspector to app.json pages:
   ```json
   "pages": [
     "page/index",
     "page/page2", 
     "page/ble-inspector"
   ]
   ```

2. Build and run the app

3. Navigate to BLE inspector page

4. Read the output to see available methods

5. Use this info to implement correct pattern

## Testing the Fix

Once we identify and fix the issue, verify:
1. ✅ No "not a function" error in logs
2. ✅ Message sends successfully (BLE SEND END appears)
3. ✅ Callback invoked (BLE MESSAGE RECEIVED appears)
4. ✅ Message parsed successfully
5. ✅ Token displayed on screen OR error message shown
6. ✅ Button returns to "get secret" state (not stuck on "Loading...")

## Summary

We've tried 4 different approaches and identified that:
- ES6 imports don't work in device pages
- `hmBle.createListener()` and `hmBle.on()` don't exist
- Current approach uses `hmBle.createConnect()` but something is still wrong

With the extensive logging now in place, we should be able to pinpoint exactly:
- Which method is causing the "not a function" error
- Whether messages are being sent/received
- What the exact data format issues are (if any)

The user should run the app, collect the logs, and share them so we can identify the exact failure point and implement the correct solution.
