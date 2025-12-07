# Architecture Overview

This document describes the architecture of the Nightscout Zepp OS app.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub Codespaces                    │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Development Environment                        │   │
│  │  - Node.js 20                                   │   │
│  │  - GitHub Copilot                               │   │
│  │  - VS Code Extensions                           │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   Zepp OS Application                   │
│                                                         │
│  ┌──────────────────────┐    ┌───────────────────────┐ │
│  │   Device Side        │◄───►│   App Side            │ │
│  │   (Watch)            │    │   (Phone)              │ │
│  │                      │    │                        │ │
│  │  page/index.js       │    │  app-side/index.js    │ │
│  │  ┌────────────────┐  │    │  ┌──────────────────┐ │ │
│  │  │ UI Widgets:    │  │    │  │ API Fetching:    │ │ │
│  │  │ - TEXT         │  │    │  │ - HTTP Requests  │ │ │
│  │  │ - CANVAS       │  │    │  │ - Data Parsing   │ │ │
│  │  │ - BUTTON       │  │    │  │ - Error Handling │ │ │
│  │  └────────────────┘  │    │  └──────────────────┘ │ │
│  │                      │    │                        │ │
│  │  State Management:   │    │  Network Layer:        │ │
│  │  - apiUrl           │    │  - Fetch API           │ │
│  │  - currentBG        │    │  - Response Parsing    │ │
│  │  - trend            │    │  - Data Transformation │ │
│  │  - delta            │    │                        │ │
│  │  - dataPoints       │    │                        │ │
│  └──────────────────────┘    └───────────────────────┘ │
│            ▲                           │                │
│            │                           │                │
│            └───────shared/message.js───┘                │
│                   (Message Bridge)                      │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   Nightscout API                        │
│                                                         │
│  Endpoint: /api/v1/entries.json?count=10               │
│                                                         │
│  Response: [{sgv, direction, dateString, date}, ...]   │
└─────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Device Side (page/index.js)

**Responsibilities:**
- Render UI widgets
- Handle user interactions
- Display glucose data
- Draw graphs
- Manage local state

**Limitations:**
- No direct internet access
- Must communicate through app-side
- Limited to UI operations

**Key Methods:**
- `onInit()`: Initialize page and build UI
- `buildUI()`: Create all widgets
- `drawGraph()`: Render glucose graph on canvas
- `fetchData()`: Trigger data fetch request
- `updateWithDummyData()`: Update UI with new data

### 2. App Side (app-side/index.js)

**Responsibilities:**
- Make HTTP requests to Nightscout API
- Parse API responses
- Transform data for device display
- Handle errors
- Manage communication with device

**Capabilities:**
- Full internet access
- Runs on companion phone
- Can use more resources

**Key Methods:**
- `setupMessageHandlers()`: Listen for device messages
- `fetchNightscoutData()`: HTTP request to API
- `parseNightscoutData()`: Transform API response
- `sendDataToDevice()`: Send processed data to watch
- `formatTimeSince()`: Time formatting helper

### 3. Shared Layer (shared/message.js)

**Purpose:**
- Bridge communication between device and app-side
- Provide consistent message format
- Define message types

**Message Types:**
- `FETCH_DATA`: Request to fetch new glucose data
- `UPDATE_SETTINGS`: Update app configuration

**Structure:**
```javascript
{
  type: 'request' | 'response',
  data: { ... }
}
```

## Data Flow

### Fetch Data Flow

1. **User Action**: User taps "Fetch Data" button
2. **Device Request**: Device page sends message to app-side
3. **API Call**: App-side makes HTTP request to Nightscout
4. **Response**: Nightscout returns JSON with glucose entries
5. **Parsing**: App-side parses and transforms data
6. **Send to Device**: Processed data sent back to device
7. **UI Update**: Device page updates all widgets
8. **Graph Render**: Canvas redraws with new data points

### Message Flow

```
Device (page/index.js)
    │
    │ messageBuilder.request({ type: 'FETCH_DATA' })
    ▼
App-Side (app-side/index.js)
    │
    │ fetchNightscoutData()
    │ HTTP GET → Nightscout API
    ▼
Nightscout API
    │
    │ JSON Response
    ▼
App-Side
    │
    │ parseNightscoutData()
    │ messageBuilder.response({ data })
    ▼
Device
    │
    │ Update widgets
    │ Redraw graph
    ▼
User sees updated data
```

## Technology Stack

### Frontend (Device)
- **Language**: JavaScript (ES6+)
- **UI Framework**: Zepp OS hmUI
- **Graphics**: Canvas API
- **State Management**: Object-based state

### Backend (App-Side)
- **Language**: JavaScript (ES6+)
- **HTTP Client**: Fetch API / Zepp OS HTTP
- **Data Processing**: Native JavaScript
- **Messaging**: Zepp OS messaging API

### Development Environment
- **Container**: Docker (via devcontainer)
- **Runtime**: Node.js 20
- **IDE**: VS Code with Codespaces
- **AI Assistant**: GitHub Copilot
- **Code Quality**: ESLint + Prettier

## API Integration

### Nightscout API

**Base URL**: Configurable (e.g., https://your-nightscout.herokuapp.com)

**Endpoint**: `/api/v1/entries.json?count=10`

**Method**: GET

**Response Schema**:
```json
[
  {
    "sgv": 120,              // Blood glucose value
    "direction": "Flat",     // Trend direction
    "dateString": "ISO date",
    "date": 1234567890,      // Unix timestamp
    "type": "sgv",
    "device": "...",
    "...": "..."
  }
]
```

**Processed Data**:
```javascript
{
  currentBG: "120",
  trend: "→",
  delta: "+2",
  lastUpdate: "5 min ago",
  dataPoints: [110, 115, 118, 120, ...],
  rawData: { original API response }
}
```

## Configuration Management

### App Manifest (app.json)

- **App ID**: com.nightscout.zepp
- **Version**: 1.0.0
- **Permissions**: internet, data:user.info
- **Target Devices**: gtr-3 (expandable)
- **API Version**: 1.0.0+

### Package Configuration (package.json)

- **Name**: zepp-nightscout
- **Scripts**: dev, build, test
- **License**: MIT

### Dev Container (.devcontainer/devcontainer.json)

- **Base Image**: Node.js 20 (Debian Bullseye)
- **Features**: Node, GitHub CLI
- **Extensions**: ESLint, Prettier, Copilot
- **Ports**: 8080 (forwarded)
- **Post-Create**: npm install

## Security Considerations

1. **API Keys**: Store securely (not implemented yet)
2. **HTTPS**: Always use secure connections
3. **Input Validation**: Validate API URLs
4. **Error Handling**: Don't expose sensitive data in errors
5. **Permissions**: Request only necessary permissions

## Scalability

### Current Limitations
- Single API endpoint
- On-demand data fetching
- No caching
- No background updates

### Future Improvements
- Multiple endpoints support
- Periodic background fetching
- Local data caching
- Offline mode
- Push notifications

## Testing Strategy

### Manual Testing
- UI rendering verification
- Button interactions
- Data display accuracy
- Error scenarios

### Future Automated Testing
- Unit tests for data parsing
- Integration tests for API calls
- UI component tests
- End-to-end tests

## Performance Considerations

1. **Canvas Optimization**: Redraw only when data changes
2. **Message Efficiency**: Minimize device-app communication
3. **API Rate Limiting**: Implement request throttling
4. **Memory Management**: Clean up resources properly

## Development Workflow

1. **Local Development**: Edit files in Codespaces
2. **Copilot Assistance**: Use for code generation and help
3. **Testing**: Manual testing with simulators
4. **Debugging**: Console logs and error handling
5. **Version Control**: Git commits and PR reviews
6. **Deployment**: Build and package for Zepp OS

## Summary

The architecture follows Zepp OS best practices:
- ✅ Separation of concerns (device vs app-side)
- ✅ Clean message-based communication
- ✅ Modular code structure
- ✅ External API integration
- ✅ Modern development environment
- ✅ AI-assisted development ready
