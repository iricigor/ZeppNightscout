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
// Access messageBuilder from globalData (set in app.js)
const { messageBuilder, MESSAGE_TYPES } = getApp()._options.globalData;

// User taps button
const message = messageBuilder.request({
  type: MESSAGE_TYPES.GET_SECRET
});

// Send via hmBle (global object provided by Zepp OS)
hmBle.send(JSON.stringify(message));
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
// Device side receives response via hmBle.on
hmBle.on('message', (data) => {
  const parsedData = typeof data === 'string' ? JSON.parse(data) : data;
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
- **No `@zos/ble` imports** - Device pages cannot import `@zos/ble`
- **Use `hmBle` global** - Zepp OS provides `hmBle` as a global object
- **Access via globalData** - messageBuilder and MESSAGE_TYPES come from `getApp()._options.globalData`
- **JSON serialization** - Messages are sent as JSON strings via `hmBle.send()`

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
3. **Native BLE APIs**: Uses platform-provided `hmBle` on device, `@zos/ble` on app-side
4. **Bidirectional**: Both sides can send and receive messages
5. **Event-driven**: App-side reacts to device events via message listeners

## Testing

Run the GET_SECRET test to verify the implementation:

```bash
node tests/test-get-secret.js
```

Expected: All 21 GET_SECRET tests pass, including:
- ✓ page2.js should NOT import @zos/ble
- ✓ page2.js should access MESSAGE_TYPES from globalData
- ✓ page2.js should have messaging listener
- ✓ app-side should handle GET_SECRET message

## How to See It in Action

1. Build and install the app on your watch
2. Navigate to page 2 (swipe left from main page)
3. Tap the "get secret" button
4. Watch displays "Loading..." then shows the token
5. App-side logs show the entire interaction

This demonstrates that **app-side CAN and DOES react to device events** through the BLE messaging system, using the correct pattern for Zepp OS device pages.
