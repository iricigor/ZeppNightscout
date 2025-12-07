# Three-Page Navigation System

This document describes the three-page navigation system implemented in the ZeppNightscout app.

## Overview

The app now features a three-page navigation system that separates concerns and improves usability:

1. **Page 1: Main Metrics** - Quick glance at current glucose status
2. **Page 2: Graph View** - Detailed glucose trend visualization with zoom
3. **Page 3: Settings/History** - Configuration and data history

## Navigation Methods

### Tap-Based Navigation

Users can navigate between pages by tapping the left or right edges of the screen:

- **Tap Left Edge** (80px zone): Navigate to the previous page
- **Tap Right Edge** (80px zone): Navigate to the next page

### Visual Indicators

#### Navigation Arrows
- **← Arrow**: Shows when previous page is available
- **→ Arrow**: Shows when next page is available
- **Empty Space**: Shows at boundaries (first/last page)

#### Page Indicators
Three dots at the bottom show the current page:
- **White, larger dot (radius: 6)**: Current page
- **Gray, smaller dots (radius: 4)**: Other pages

## Page Details

### Page 1: Main Metrics

**Purpose**: Quick glance at current glucose status

**Features**:
- Extra-large BG display (96px) for easy reading at a glance
- Trend arrow (⇈, ↑, ↗, →, ↘, ↓, ⇊)
- Delta change from previous reading
- Last update timestamp
- Fetch Data button for manual refresh

**Layout**:
```
┌─────────────────────────────┐
│      Nightscout             │
│                         →   │
│                             │
│        120                  │  (Large BG)
│                             │
│    ↗        +2              │  (Trend & Delta)
│                             │
│  Last: 5 min ago            │
│                             │
│    [Fetch Data]             │
│                             │
│ Tap edges to navigate       │
│         ●  ○  ○             │  (Page indicators)
└─────────────────────────────┘
```

**Navigation**: Tap right edge to go to Graph page

---

### Page 2: Graph View

**Purpose**: Detailed glucose trend visualization

**Features**:
- Large graph canvas (200px tall)
- Zoom controls (0.5x to 3.0x)
- Current BG and trend summary
- Up to 200 glucose readings displayed
- Auto-scaling based on visible data range

**Layout**:
```
┌─────────────────────────────┐
│   Glucose Graph             │
│  ←                      →   │
│                             │
│      120 →                  │  (BG summary)
│                             │
│  ┌─────────────────────┐   │
│  │    Graph Canvas     │   │  (200px tall)
│  │   (Line chart)      │   │
│  └─────────────────────┘   │
│                             │
│  Zoom: 1.0x  [+]  [-]      │  (Zoom controls)
│                             │
│ Tap edges to navigate       │
│         ○  ●  ○             │  (Page indicators)
└─────────────────────────────┘
```

**Zoom Functionality**:
- **Zoom In (3.0x)**: Shows recent 67 points in detail
- **Normal (1.0x)**: Shows all 200 points
- **Zoom Out (0.5x)**: Compresses view if more data available

**Navigation**: 
- Tap left edge to go back to Main page
- Tap right edge to go to Settings page

---

### Page 3: Settings/History

**Purpose**: Configuration and status information

**Features**:
- API URL display and verification
- Token validation with security indicators
- Data history count
- Configuration status messages

**Layout**:
```
┌─────────────────────────────┐
│       Settings              │
│  ←                          │
│                             │
│  API URL:                   │
│  your-nightscout.com [Verify]│
│  ✓ URL verified             │
│                             │
│  API Token (read-only):     │
│  token-here...        ?     │  (Click ? to validate)
│  ✅ Token is read-only      │
│                             │
│  History:                   │
│  Data points: 200           │
│                             │
│ Tap edges to navigate       │
│         ○  ○  ●             │  (Page indicators)
└─────────────────────────────┘
```

**Token Validation Icons**:
- `?` (Gray): Not validated yet
- `⌛` (Gray): Validating...
- `✅` (Green): Read-only access (safe)
- `❗` (Red): Admin access (dangerous)
- `✗` (Red): Invalid token

**Navigation**: Tap left edge to go back to Graph page

## Implementation Details

### State Management

The page system maintains shared state:

```javascript
{
  currentPage: 0,              // 0=Main, 1=Graph, 2=Settings
  graphZoom: 1.0,              // 0.5x to 3.0x
  currentBG: '--',
  trend: '--',
  delta: '--',
  lastUpdate: '--',
  dataPoints: [],              // Up to 200 glucose readings
  apiUrl: '...',
  apiToken: '...',
  verificationStatus: '',
  tokenValidationStatus: '...'
}
```

### Navigation Flow

```
┌──────────────┐    Tap Right    ┌──────────────┐    Tap Right    ┌──────────────┐
│   Page 1     │   ────────────> │   Page 2     │   ────────────> │   Page 3     │
│ Main Metrics │                 │ Graph View   │                 │   Settings   │
└──────────────┘                 └──────────────┘                 └──────────────┘
       ^                                 ^                                 ^
       │                                 │                                 │
       └─────────────────────────────────┴─────────────────────────────────┘
                          Tap left edge to go back
```

### Widget Lifecycle

1. **onInit()**: Initialize state and setup navigation
2. **buildUI()**: Create initial page
3. **refreshUI()**: Clear widgets and rebuild current page
4. **navigatePage()**: Change page and trigger refresh

### Performance Considerations

- **Widget Cleanup**: Widgets are individually deleted on page change to prevent memory leaks
- **Array Operations**: Uses loops instead of spread operators to avoid stack overflow with 200 data points
- **Null Checks**: All widget accesses check for existence before updating
- **Zoom Calculations**: Bounded to prevent out-of-range errors

## User Experience Guidelines

### First-Time Use

1. Start on Page 1 (Main Metrics)
2. Tap "Fetch Data" to load glucose data
3. Tap right edge to view detailed graph
4. Tap right edge again to configure settings

### Daily Use

- **Quick Check**: Stay on Page 1 for current BG and trend
- **Trend Analysis**: Switch to Page 2 to see graph with zoom
- **Configuration**: Use Page 3 as needed

### Navigation Tips

- Look for arrow indicators to see available navigation
- Page dots show which page you're on (1, 2, or 3)
- State persists across pages (data fetched once is available everywhere)

## Accessibility Features

- **Large Text**: 96px BG display for easy reading
- **Visual Cues**: Clear arrows and page indicators
- **Tap Targets**: 80px wide navigation zones for easy tapping
- **Consistent Layout**: Similar structure across all pages
- **Status Feedback**: Color-coded validation indicators

## Testing

All functionality has been tested with 51 assertions passing:
- ✅ Page navigation logic
- ✅ Widget cleanup and refresh
- ✅ Zoom calculations with bounds checking
- ✅ Data updates across pages
- ✅ Token validation states
- ✅ Graph rendering with various data sizes

## Future Enhancements

Potential improvements:
- Swipe gestures in addition to tap navigation
- Page transition animations
- Customizable page order
- Additional pages (e.g., alarms, statistics)
- Horizontal scroll on graph page for panning
- Long-press for quick actions
