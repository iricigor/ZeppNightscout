# Page Navigation Logging

## Overview
This feature adds logging to track user navigation between pages in the ZeppNightscout app. The app-side service now logs whenever users navigate from one page to another.

## Implementation Details

### What Was Added

1. **New Message Type** (`shared/message.js`)
   - Added `PAGE_NAVIGATION` message type to the MESSAGE_TYPES enum
   - This allows pages to communicate navigation events to the app-side service

2. **App-Side Handler** (`app-side/index.js`)
   - Added `logPageNavigation(page, action)` method that logs navigation events with timestamps
   - Added message handler for `MESSAGE_TYPES.PAGE_NAVIGATION` messages
   - Logs are in the format: `[timestamp] Page Navigation: page/name - action`

3. **Page Updates** (`page/index.js` and `page/page2.js`)
   - Added import of messaging module (`@zos/ble`)
   - Added import of MESSAGE_TYPES from shared/message.js
   - Send navigation events in `onInit()` when page loads
   - Send navigation events in `onDestroy()` when page unloads
   - Uses try-catch to handle cases where messaging might not be available

### Example Log Output

When a user navigates from page 1 to page 2, the app-side service will log:

```
[2025-12-14T21:38:24.018Z] Page Navigation: page/index - init
[2025-12-14T21:38:30.123Z] Page Navigation: page/index - destroy
[2025-12-14T21:38:30.456Z] Page Navigation: page/page2 - init
```

When navigating back:
```
[2025-12-14T21:38:35.789Z] Page Navigation: page/page2 - destroy
[2025-12-14T21:38:36.012Z] Page Navigation: page/index - init
```

## Benefits

1. **Visibility**: Developers can now see when users navigate between pages
2. **Debugging**: Helps identify navigation issues or unexpected page transitions
3. **Analytics**: Can be extended to track user behavior patterns
4. **Timestamped**: All events include ISO 8601 timestamps for precise tracking

## Testing

A comprehensive test suite (`tests/test-page-navigation.js`) verifies:
- The PAGE_NAVIGATION message type exists
- The app-side has the logPageNavigation handler
- Both pages send navigation events on init and destroy
- All message types are properly exported

Run the test with:
```bash
node tests/test-page-navigation.js
```

## Future Enhancements

Potential improvements:
- Store navigation events for analytics
- Add navigation timing metrics
- Track user flow patterns
- Send navigation data to external analytics services
