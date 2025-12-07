# Nightscout Integration Features

This document describes the Nightscout integration features implemented in the ZeppNightscout app.

## Feature Overview

### 1. URL Verification Button

A "Verify" button has been added next to the API URL setting field to allow users to verify their Nightscout URL before fetching data.

**Location**: Next to the API URL display (top right of settings area)

**Functionality**:
- Calls the `/api/v1/status` endpoint on the Nightscout server
- Does NOT transfer CGM data during verification
- Provides visual feedback on verification status
- Shows success (green) or failure (red) messages

**Verification Endpoint**: `{nightscout-url}/api/v1/status`

This endpoint returns server status information:
```json
{
  "status": "ok",
  "name": "Nightscout",
  "version": "14.2.6",
  "serverTime": "2024-12-07T12:00:00.000Z",
  "apiEnabled": true
}
```

### 2. Enhanced Data Fetching

The data fetch has been updated to request **200 glucose values** instead of 10.

**Rationale**: 
- Average Amazfit watch screen width is ~200 pixels
- Display uses pixel-per-value rendering (1 pixel = 1 glucose reading)
- Provides more detailed glucose trend visualization

**API Endpoint**: `{nightscout-url}/api/v1/entries.json?count=200`

**Data Display**:
- Graph renders 200 data points across the canvas width
- Each pixel represents one glucose reading
- Auto-scaling ensures all values are visible
- Smooth line drawing shows glucose trends over time

### 3. Visual Feedback

**Verification Status Messages**:
- "Verifying..." (gray) - During verification
- "✓ URL verified" (green) - Successful verification
- "✗ Connection failed" (red) - Failed to connect
- "✗ Invalid response" (red) - Invalid server response

**Status Location**: Below the API URL, above the BG value display

## UI Layout

```
┌─────────────────────────────────────┐
│           Nightscout                │  Title
├─────────────────────────────────────┤
│ API URL:                            │  Settings Label
│ https://your-ns.com      [Verify]   │  Settings Value + Verify Button
│ ✓ URL verified                      │  Verification Status
├─────────────────────────────────────┤
│                                     │
│              120                    │  Current BG (Large)
│                                     │
├──────────────────┬──────────────────┤
│   Trend: →       │    Δ: +2         │  Calculated Values
├──────────────────┴──────────────────┤
│        Last: 5 min ago              │  Timestamp
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │  ~~~~~~~~ glucose graph ~~~ │   │  Graph Canvas (200 points)
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│        [ Fetch Data ]               │  Fetch Button
└─────────────────────────────────────┘
```

## Implementation Details

### Message Types

Three message types are supported for device-to-app communication:

1. **FETCH_DATA**: Request 200 glucose readings
2. **UPDATE_SETTINGS**: Update app configuration
3. **VERIFY_URL**: Verify Nightscout URL (new)

### Device-Side (page/index.js)

**New State Variables**:
- `verificationStatus`: Stores verification message text

**New UI Widgets**:
- `verifyButton`: Button to trigger URL verification
- `verificationStatus`: Text widget to display verification result

**New Methods**:
- `verifyUrl()`: Initiates URL verification
- `simulateVerification()`: Simulates verification response (for testing)

**Updated Methods**:
- `updateWithDummyData()`: Generates 200 data points instead of 8
- `drawGraph()`: Adjusted canvas height to 80px (was 100px)

### App-Side (app-side/index.js)

**New Methods**:
- `verifyNightscoutUrl(apiUrl)`: Calls `/api/v1/status` endpoint
- `sendVerificationResultToDevice(result)`: Sends verification result to device

**Updated Methods**:
- `fetchNightscoutData(apiUrl)`: Now requests 200 entries (was 10)
- `setupMessageHandlers()`: Added handler for VERIFY_URL message
- `request(options)`: Enhanced to handle both status and entries endpoints

## Usage Flow

### URL Verification Flow

1. User taps "Verify" button
2. Device sends VERIFY_URL message to app-side
3. App-side calls `/api/v1/status` endpoint
4. Server responds with status information
5. App-side validates response
6. App-side sends verification result to device
7. Device displays success/failure message

### Data Fetch Flow

1. User taps "Fetch Data" button
2. Device sends FETCH_DATA message to app-side
3. App-side calls `/api/v1/entries.json?count=200`
4. Server responds with 200 glucose entries
5. App-side parses and processes data
6. App-side sends data to device
7. Device updates UI and redraws graph with 200 points

## Benefits

1. **URL Verification**: Users can verify their Nightscout URL is correct before attempting data transfer
2. **No Wasted Data Transfer**: Verification uses a lightweight status endpoint
3. **Better Visualization**: 200 data points provide detailed glucose trends
4. **Pixel-Perfect Display**: One glucose value per pixel matches watch screen width
5. **Clear Feedback**: Visual indicators show verification and fetch status

## Security Considerations

- Verification endpoint does not transfer sensitive CGM data
- Status endpoint only reveals server configuration (name, version, status)
- Full CGM data is only transferred during explicit "Fetch Data" action
- HTTPS should be used for all Nightscout connections
- Read-only tokens recommended for API access

## Future Enhancements

Potential improvements:
- Auto-verify URL when settings are updated
- Cache verification result to avoid repeated checks
- Show server version in verification status
- Add timeout handling for slow connections
- Support custom verification endpoints
- Allow configuration of data point count

## Testing

To test the new features:

1. **URL Verification**:
   - Tap "Verify" button
   - Observe verification status changes
   - Verify message shows success/failure

2. **200 Data Points**:
   - Tap "Fetch Data" button
   - Observe graph rendering with 200 points
   - Verify smooth line across full canvas width

3. **Error Handling**:
   - Test with invalid URL
   - Test with network disconnection
   - Verify appropriate error messages display

## Compatibility

- Works with Nightscout API v1
- Compatible with all Nightscout server versions supporting `/api/v1/status`
- Tested with standard Nightscout endpoints
- Screen dimensions: 480×480 pixels (adjustable for different devices)

## References

- [Nightscout API Documentation](http://www.nightscout.info/)
- [Nightscout Status Endpoint](http://www.nightscout.info/wiki/welcome/website-features/0-9-features/status)
- [Zepp OS Documentation](https://docs.zepp.com/)
