# Fix for App Crash on Page 2 - ES6 Import Issue

## Issue Summary

**Error**: `ReferenceError: '__$RQR$__' is not defined`  
**Location**: `page/page2.js` - occurred when navigating to second page  
**Cause**: ES6 `import` statement in device page file  
**Impact**: App crashed immediately when opening second page  

## Root Cause Analysis

The error `'__$RQR$__' is not defined` is a build system placeholder that appears when the Zepp OS bundler fails to properly resolve an ES6 `import` statement. The issue was caused by:

```javascript
import * as messaging from '@zos/ble';  // This doesn't work in device page files!
```

### Why Imports Don't Work in Device Pages

Zepp OS has different module systems for different file types:

| File Type | Import Support | API Access |
|-----------|---------------|------------|
| `app.js` | ✅ ES6 imports work | Can import from `shared/` and `@zos/*` |
| `app-side/index.js` | ✅ ES6 imports work | Can import from `shared/` and `@zos/*` |
| `page/*.js` | ❌ ES6 imports fail | Must use global objects (`hmBle`, `hmUI`, etc.) |
| `setting/index.js` | ❌ ES6 imports fail | Must use global objects |

Device page files are processed differently by the Zepp OS build system and don't support ES6 module syntax. They must use global objects provided by the Zepp OS runtime.

## The Fix

### Before (Broken Code)

```javascript
// page/page2.js
import * as messaging from '@zos/ble';  // ❌ Causes crash

Page({
  onInit() {
    // Send message
    messaging.peerSocket.send(message);
    
    // Receive messages
    messaging.peerSocket.addListener('message', (data) => {
      const parsedData = typeof data === 'string' ? JSON.parse(data) : data;
      // Process data...
    });
  }
});
```

### After (Fixed Code)

```javascript
// page/page2.js
// No import statement - use global hmBle object

Page({
  onInit() {
    // Send message - convert to buffer
    const messageStr = JSON.stringify(message);
    const messageBuffer = hmBle.str2buf(messageStr);
    hmBle.send(messageBuffer, messageBuffer.byteLength);
    
    // Receive messages - set up connection callback
    hmBle.createConnect(function(index, data, size) {
      const dataStr = hmBle.buf2str(data, size);
      const parsedData = JSON.parse(dataStr);
      // Process data...
    });
  },
  
  onDestroy() {
    // Clean up BLE connection
    hmBle.disConnect();
  }
});
```

## Key Differences Between Device and App-Side APIs

### Device Side (uses `hmBle`)

```javascript
// Setup connection
hmBle.createConnect(function(index, data, size) {
  // Callback receives buffer data
  const dataStr = hmBle.buf2str(data, size);
  const parsedData = JSON.parse(dataStr);
});

// Send message
const messageStr = JSON.stringify(message);
const buffer = hmBle.str2buf(messageStr);
hmBle.send(buffer, buffer.byteLength);

// Cleanup
hmBle.disConnect();
```

### App-Side (uses `@zos/ble`)

```javascript
import * as messaging from '@zos/ble';

// Setup listener
messaging.peerSocket.addListener('message', (data) => {
  const parsedData = typeof data === 'string' ? JSON.parse(data) : data;
});

// Send message
messaging.peerSocket.send(message);  // No buffer conversion needed
```

## Implementation Details

### Changes Made

1. **Removed import statement** from `page/page2.js`
2. **Replaced `messaging.peerSocket.send()`** with `hmBle.send()` + buffer conversion
3. **Replaced `messaging.peerSocket.addListener()`** with `hmBle.createConnect()`
4. **Added `hmBle.disConnect()`** in `onDestroy()` for cleanup
5. **Added error handling** for buffer conversion operations
6. **Improved error logging** to include message size

### Test Updates

Updated `tests/test-get-secret.js` to verify:
- ✅ Page2.js should NOT import @zos/ble
- ✅ Page2.js should use `hmBle.createConnect` for receiving
- ✅ Page2.js should use `hmBle.send` for sending
- ✅ Page2.js should use `hmBle.buf2str` for parsing
- ✅ Page2.js should use `hmBle.str2buf` for encoding

All 24/24 tests pass.

### Documentation Updates

1. **DEVICE-TO-APP-SIDE-COMMUNICATION.md** - Updated with correct patterns
2. **FIX-SECRET-FETCH-ISSUE.md** - Added correction notice
3. **FIX-APP-CRASH-IMPORT-ISSUE.md** (this file) - Comprehensive fix documentation

## Testing Results

- ✅ All automated tests pass (24/24 GET_SECRET tests)
- ✅ All other test suites pass (parser, validation, checkbox)
- ✅ Code syntax validation passes
- ✅ Security scan completed with 0 alerts
- ✅ Code review completed and feedback addressed

## How to Verify the Fix

1. Build the app: `zeus build`
2. Install on device: `zeus install`
3. Open the app and navigate to page 2 (swipe left or tap button)
4. Verify:
   - Page 2 opens without crashing
   - "You made it!" message displays
   - "Get secret" button is functional
   - Swipe right navigation works

## Lessons Learned

### DO in Device Page Files:
- ✅ Use global objects: `hmBle`, `hmUI`, `hmApp`, `hmSetting`
- ✅ Use `hmBle.createConnect()` for BLE message receiving
- ✅ Use `hmBle.send()` with buffer conversion for sending
- ✅ Convert messages to/from buffers using `hmBle.str2buf()` and `hmBle.buf2str()`
- ✅ Clean up BLE connection in `onDestroy()` with `hmBle.disConnect()`

### DON'T in Device Page Files:
- ❌ Don't use ES6 `import` statements
- ❌ Don't use `import * as messaging from '@zos/ble'`
- ❌ Don't use `messaging.peerSocket` API (that's for app-side only)
- ❌ Don't send objects directly (must convert to buffers)

### DO in App-Side Files:
- ✅ Use ES6 imports: `import * as messaging from '@zos/ble'`
- ✅ Use `messaging.peerSocket.addListener()` for receiving
- ✅ Use `messaging.peerSocket.send()` for sending
- ✅ Can send objects directly (no buffer conversion needed)

## Related Files

- `page/page2.js` - Main fix applied here
- `tests/test-get-secret.js` - Tests updated to verify fix
- `docs/DEVICE-TO-APP-SIDE-COMMUNICATION.md` - API patterns documented
- `docs/FIX-SECRET-FETCH-ISSUE.md` - Original issue with correction notice

## Historical Context

This issue was introduced in PR #187, which attempted to fix device-to-app-side communication by adding `import * as messaging from '@zos/ble'` to device page files. While this pattern works in app-side files, it causes build/runtime errors in device page files. The correct approach is to use the global `hmBle` object in device pages, as documented in the official Zepp OS documentation.

## Security Note

No security vulnerabilities were introduced by this fix. CodeQL analysis shows 0 alerts.
