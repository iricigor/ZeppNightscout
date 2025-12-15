# Device-to-App-Side Communication Example

This document demonstrates how the app-side service can react to events happening on the device (watch).

## Overview

The Zepp OS architecture separates device-side code (running on the watch) from app-side code (running on the companion phone). Communication between them happens via BLE messaging using the `hmBle` global object on the device side.

## Implementation: "Get Secret" Feature

The second page (`page/page2.js`) demonstrates a complete device-to-app-side interaction:

### 1. Device Page Sends Message

When the user taps the "get secret" button on the watch:

```javascript
// Device side (page/page2.js)
// Note: Device pages use global hmBle object, NOT imports

// Access messageBuilder from globalData (set in app.js)
const { messageBuilder, MESSAGE_TYPES } = getApp().globalData;

// User taps button
const message = messageBuilder.request({
  type: MESSAGE_TYPES.GET_SECRET
});

// Send via hmBle (convert to buffer first)
const messageStr = JSON.stringify(message);
const messageBuffer = hmBle.str2buf(messageStr);
hmBle.send(messageBuffer, messageBuffer.byteLength);
```

### 2. App-Side Receives and Processes

The app-side service on the phone receives the message:

```javascript
// App-side (app-side/index.js)
import * as messaging from '@zos/ble';

messaging.peerSocket.addListener('message', (data) => {
  if (data.type === MESSAGE_TYPES.GET_SECRET) {
    this.getSecret();  // React to device event
  }
});
```

### 3. App-Side Performs Action

The app-side makes an HTTP request (which device can't do directly):

```javascript
getSecret() {
  // Make HTTP request to external API
  fetch({
    url: 'https://zeppnsapi.azurewebsites.net/api/GetToken',
    method: 'GET'
  })
  .then(response => {
    // Send response back to device
    this.sendSecretToDevice({
      success: true,
      token: response.body.token
    });
  });
}
```

### 4. Device Receives Response

The device page listens for the response:

```javascript
// Device side receives response via hmBle.createConnect
hmBle.createConnect(function(index, data, size) {
  // Convert buffer to string and parse
  const dataStr = hmBle.buf2str(data, size);
  const parsedData = JSON.parse(dataStr);
  
  if (parsedData.data.secret && parsedData.data.success) {
    // Update UI with token from app-side
    widgets.resultText.setProperty(hmUI.prop.TEXT, 'Token: ' + parsedData.data.token);
  }
});
```

## Page Navigation Logging

Both pages now log navigation events that can be observed:

### Device-Side Logs
```
Page Navigation: page/index - init
Page Navigation: page/index - destroy
Page Navigation: page/page2 - init
```

### App-Side Logs
```
[2025-12-14T22:00:00.000Z] App-side service initialized
[2025-12-14T22:00:05.000Z] Received message: {"type":"GET_SECRET"}
[2025-12-14T22:00:05.100Z] Getting secret token
[2025-12-14T22:00:05.500Z] Secret token response received
```

## Key Architecture Points

### Device Side (Watch)
- **Use global `hmBle` object** - Device pages use the global `hmBle` object, NOT ES6 imports
- **Cannot import `@zos/ble`** - ES6 imports in device page files cause build errors (`__$RQR$__` error)
- **Use `hmBle.createConnect(callback)`** - Set up BLE message listener with callback function
- **Use `hmBle.send(buffer, size)`** - Send messages as buffers (use `hmBle.str2buf()` to convert)
- **Use `hmBle.buf2str(data, size)`** - Convert received buffers to strings
- **Access via globalData** - messageBuilder and MESSAGE_TYPES come from `getApp().globalData`

### App Side (Phone)
- **Import `@zos/ble`** - App-side CAN import and use `@zos/ble`
- **Use `messaging.peerSocket`** - Standard BLE messaging API
- **Message listeners** - Receive messages from device via `addListener()`

### Shared Layer
- **app.js provides globalData** - Imports messageBuilder and MESSAGE_TYPES, makes them available to pages
- **shared/message.js** - Defines message protocol used by both sides

## Why This Pattern Works

1. **Separation of concerns**: Device and app-side have different capabilities and restrictions
2. **Global data sharing**: app.js sets up globalData that pages can access
3. **Different BLE APIs**: Device pages use global `hmBle`, app-side uses `@zos/ble` import
4. **Bidirectional**: Both sides can send and receive messages
5. **Event-driven**: App-side reacts to device events via message listeners
6. **Import restrictions**: Device page files cannot use ES6 imports - they must use global objects

## Testing

Run the GET_SECRET test to verify the implementation:

```bash
node tests/test-get-secret.js
```

Expected: All 24 GET_SECRET tests pass, including:
- ✓ page2.js should NOT import @zos/ble (uses global hmBle instead)
- ✓ page2.js should access MESSAGE_TYPES from globalData
- ✓ page2.js should use hmBle.createConnect for receiving messages
- ✓ page2.js should use hmBle.send for sending messages
- ✓ app-side should handle GET_SECRET message

## How to See It in Action

1. Build and install the app on your watch
2. Navigate to page 2 (swipe left from main page)
3. Tap the "get secret" button
4. Watch displays "Loading..." then shows the token
5. App-side logs show the entire interaction

This demonstrates that **app-side CAN and DOES react to device events** through the BLE messaging system. Device pages use the global `hmBle` object (not ES6 imports), while app-side uses `@zos/ble` imports. This is the correct pattern for Zepp OS device-to-app-side communication.
