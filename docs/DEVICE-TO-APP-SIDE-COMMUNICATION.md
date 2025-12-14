# Device-to-App-Side Communication Example

This document demonstrates how the app-side service can react to events happening on the device (watch).

## Overview

The Zepp OS architecture separates device-side code (running on the watch) from app-side code (running on the companion phone). Communication between them happens via BLE messaging using the `@zos/ble` module.

## Implementation: "Get Secret" Feature

The second page (`page/page2.js`) demonstrates a complete device-to-app-side interaction:

### 1. Device Page Sends Message

When the user taps the "get secret" button on the watch:

```javascript
// Device side (page/page2.js)
import * as messaging from '@zos/ble';
import { messageBuilder, MESSAGE_TYPES } from '../shared/message';

// User taps button
const message = messageBuilder.request({
  type: MESSAGE_TYPES.GET_SECRET
});
messaging.peerSocket.send(message);
```

### 2. App-Side Receives and Processes

The app-side service on the phone receives the message:

```javascript
// App-side (app-side/index.js)
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
// Device side receives response
messaging.peerSocket.addListener('message', (data) => {
  if (data.data.secret && data.data.success) {
    // Update UI with token from app-side
    widgets.resultText.setProperty(hmUI.prop.TEXT, 'Token: ' + data.data.token);
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

## Why This Works

1. **@zos/ble on Device**: In Zepp OS 1.0.x, device pages CAN import `@zos/ble` for messaging
2. **Bidirectional**: Both device and app-side can send/receive messages
3. **Message Protocol**: Shared message.js defines consistent message format
4. **Event-Driven**: App-side reacts to device events via message listeners

## Testing

Run the GET_SECRET test to verify the implementation:

```bash
node tests/test-get-secret.js
```

Expected: 20 tests pass, including:
- ✓ page2.js should import MESSAGE_TYPES
- ✓ page2.js should send GET_SECRET message
- ✓ page2.js should have messaging listener
- ✓ app-side should handle GET_SECRET message

## How to See It in Action

1. Build and install the app on your watch
2. Navigate to page 2 (swipe left from main page)
3. Tap the "get secret" button
4. Watch displays "Loading..." then shows the token
5. App-side logs show the entire interaction

This demonstrates that **app-side CAN and DOES react to device events** through the BLE messaging system.
