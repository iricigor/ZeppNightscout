# UI Components Overview

This document describes all the UI components implemented in the Nightscout Zepp OS app.

## Three-Page Navigation System

The app now implements a **three-page navigation system** with the following structure:

### Page 1: Main Metrics (Current BG, Trend, Delta)
- **Purpose**: Quick glance at current glucose status
- **Navigation**: Tap right edge to go to Graph page

### Page 2: Graph (Glucose Trend Visualization)
- **Purpose**: Detailed glucose trend graph with zoom controls
- **Navigation**: Tap left edge to go back to Main, tap right edge to go to Settings

### Page 3: Settings/History
- **Purpose**: Configure API settings and view history
- **Navigation**: Tap left edge to go back to Graph page

## Navigation Methods

### Tap-Based Navigation
- **Left Edge**: Tap the left 80px of the screen to navigate to the previous page
- **Right Edge**: Tap the right 80px of the screen to navigate to the next page
- **Navigation Arrows**: Visual indicators (← →) show available navigation directions
- **Page Indicators**: Three dots at the bottom show current page (1, 2, or 3)

## Page 1: Main Metrics Layout

The main page focuses on displaying critical glucose information at a glance:

### 1. Title Display
- **Type**: TEXT widget
- **Position**: Top of screen (y: 20)
- **Content**: "Nightscout" app name
- **Styling**: White text, 32px font, center-aligned

### 2. Navigation Arrows
- **Left Arrow**: Empty (first page)
- **Right Arrow**: → (indicates Graph page is available)
- **Position**: Top right area
- **Purpose**: Visual navigation cue

### 3. Current Blood Glucose Display
- **Type**: TEXT widget (Extra large display)
- **Position**: Center area
- **Content**: Current BG value (e.g., "120")
- **Styling**: 
  - Very large font (96px) - increased from 72px for better visibility
  - Green color (0x00ff00) - can be dynamic based on range
  - Center-aligned
  - Main focus of the app

### 4. Trend and Delta Indicators
- **Trend Widget**: Shows direction arrow
  - Position: Left half
  - Content: Arrow symbols (⇈, ↑, ↗, →, ↘, ↓, ⇊)
  - Size: 36px - larger for better visibility
  
- **Delta Widget**: Shows change from previous reading
  - Position: Right half
  - Content: Change value (e.g., "+2", "-5")
  - Size: 36px
  - Shows positive/negative change

### 5. Last Update Timestamp
- **Type**: TEXT widget
- **Content**: "Last: 5 min ago"
- **Styling**: Gray text (0x888888), 20px
- **Dynamic**: Updates based on data freshness

### 6. Fetch Data Button
- **Type**: BUTTON widget
- **Position**: Center area
- **Size**: 160px wide × 50px tall
- **Content**: "Fetch Data" text
- **Styling**:
  - Blue background (0x0000ff)
  - Darker on press (0x000088)
  - Rounded corners (radius: 25)
- **Action**: Triggers API data fetch and updates all displays

### 7. Navigation Hint
- **Type**: TEXT widget
- **Position**: Bottom of screen
- **Content**: "Tap edges to navigate"
- **Styling**: Gray text (0x666666), 16px

### 8. Page Indicators
- **Type**: CIRCLE widgets (3 dots)
- **Position**: Bottom center
- **Appearance**: 
  - Active page: White, larger (radius: 6)
  - Inactive pages: Dark gray, smaller (radius: 4)

## Page 2: Graph Layout

The graph page provides detailed glucose trend visualization with zoom capabilities:

### 1. Title Display
- **Type**: TEXT widget
- **Content**: "Glucose Graph"
- **Styling**: White text, 28px font, center-aligned

### 2. Navigation Arrows
- **Left Arrow**: ← (indicates Main page)
- **Right Arrow**: → (indicates Settings page)
- **Purpose**: Visual navigation cues

### 3. Current BG Summary
- **Type**: TEXT widget
- **Content**: Combined BG value and trend (e.g., "120 →")
- **Size**: 40px
- **Position**: Top area
- **Color**: Green (0x00ff00)

### 4. Glucose Graph Canvas
- **Type**: CANVAS widget
- **Size**: 440px wide × 200px tall (larger than Page 1)
- **Features**:
  - Draws line graph of glucose readings (up to 200 points)
  - Auto-scales based on visible data range
  - Supports zoom functionality
  - Shows trend over time
  - Fallback: "No data" text when empty

**Graph Drawing Logic**:
```javascript
- Connect data points with lines
- Scale Y-axis based on min/max values of visible data
- X-axis represents time (oldest to newest)
- Green line color (0x00ff00)
- Border rectangle for frame
- Zoom affects number of visible points
```

### 5. Zoom Controls
- **Zoom Label**: Displays current zoom level (e.g., "Zoom: 1.0x")
- **Zoom + Button**: 
  - Increases zoom up to 3.0x
  - Shows fewer data points with more detail
- **Zoom - Button**: 
  - Decreases zoom down to 0.5x
  - Shows more data points for wider view
- **Button Styling**: Dark gray (0x444444), rounded corners

### 6. Navigation Hint & Page Indicators
- Same as Page 1

## Page 3: Settings/History Layout

The settings page provides configuration and history information:

### 1. Title Display
- **Type**: TEXT widget
- **Content**: "Settings"
- **Styling**: White text, 28px font, center-aligned

### 2. Navigation Arrows
- **Left Arrow**: ← (indicates Graph page)
- **Right Arrow**: Empty (last page)

### 3. API URL Section
- **Label**: "API URL:" (gray, 18px)
- **URL Value**: Displays configured URL (green, 16px)
- **Verify Button**: 
  - Validates URL by calling `/api/v1/status` endpoint
  - Shows verification status below

### 4. API Token Section
- **Label**: "API Token (read-only):" (gray, 18px)
- **Token Value**: Shows token or "(not set)" (green, 16px)
- **Validation Icon**: 
  - `?` = Not validated (gray)
  - `⌛` = Validating (gray)
  - `✅` = Read-only access (green) - Safe
  - `❗` = Admin access (red) - Dangerous
  - `✗` = Invalid token (red)
- **Validation Status**: Text explanation below icon

### 5. History Section
- **Label**: "History:" (gray, 18px)
- **Data Points Count**: Shows number of cached glucose readings

### 6. Navigation Hint & Page Indicators
- Same as other pages

## Color Scheme

- **Primary Text**: White (0xffffff)
- **Secondary Text**: Gray (0x888888, 0xaaaaaa)
- **Accent/Data**: Green (0x00ff00)
- **Buttons**: Blue (0x0000ff) for primary actions, Dark gray (0x444444) for secondary
- **Graph Elements**: Green (0x00ff00)
- **Navigation Elements**: Gray (0x888888, 0x666666, 0x444444)
- **Background**: Black/Dark (default Zepp OS)

## Layout Specifications

- **Screen**: 480×480 pixels (adjustable for different devices)
- **Margins**: 20px on all sides
- **Widget Spacing**: ~10-50px between sections
- **Navigation Areas**: 80px wide touch zones on left and right edges
- **Responsive**: Can be adapted for different screen sizes

## State Management

The page maintains state for:
```javascript
{
  apiUrl: 'https://your-nightscout.herokuapp.com',
  apiToken: '',
  currentBG: '--',              // Current glucose value
  trend: '--',                  // Trend arrow
  delta: '--',                  // Change from previous
  lastUpdate: '--',             // Time since update
  dataPoints: [],               // Array for graph (up to 200 points)
  verificationStatus: '',       // URL verification status
  tokenValidationStatus: 'unvalidated',  // Token validation state
  currentPage: 0,               // 0=Main, 1=Graph, 2=Settings
  graphZoom: 1.0,               // Zoom level for graph (0.5x to 3.0x)
  graphOffset: 0                // Pan offset for graph (future feature)
}
```

## Widget Interactions

### Page Navigation
1. **Tap Left Edge**: 
   - Navigates to previous page (if available)
   - Updates page state and refreshes UI
   - Updates page indicators

2. **Tap Right Edge**: 
   - Navigates to next page (if available)
   - Updates page state and refreshes UI
   - Updates page indicators

### Page 1 (Main Metrics)
1. **Fetch Data Button Click**: 
   - Triggers `fetchData()` method
   - Updates BG value to "Loading..."
   - Sends message to app-side service
   - Updates all widgets on response

### Page 2 (Graph)
1. **Zoom + Button Click**:
   - Increases zoom level (up to 3.0x)
   - Redraws graph with fewer visible points
   - Updates zoom label

2. **Zoom - Button Click**:
   - Decreases zoom level (down to 0.5x)
   - Redraws graph with more visible points
   - Updates zoom label

### Page 3 (Settings)
1. **Verify Button Click**:
   - Validates URL format (must be HTTPS)
   - Sends verification request to app-side
   - Calls `/api/v1/status` endpoint
   - Shows verification result

2. **Token Validation Icon Click (?)**: 
   - Validates token permissions
   - Tests read access to status endpoint
   - Tests admin access to verify read-only status
   - Shows validation result with color-coded icon

## Data Flow

```
User clicks "Fetch Data" (Page 1)
    ↓
Device page sends message to app-side
    ↓
App-side fetches from Nightscout API (200 entries)
    ↓
App-side parses and processes data
    ↓
App-side sends response to device
    ↓
Device page updates state (all pages share state)
    ↓
Current page widgets are updated
    ↓
Graph is redrawn if on Page 2
```

## Navigation Flow

```
Page 1 (Main)          Page 2 (Graph)         Page 3 (Settings)
Current BG, Trend  →   Glucose Graph     →    API Configuration
     ↑                       ↑                       ↑
     └───────────────────────┴───────────────────────┘
              Tap left edge to go back
```

## Future Enhancements

Potential UI improvements:
- ✅ Three-page navigation system (IMPLEMENTED)
- ✅ Graph zoom controls (IMPLEMENTED)
- Color-coded BG values (red for high/low, green for in-range)
- Swipe gestures in addition to tap navigation
- Graph pan/scroll functionality
- Animations for page transitions
- Notifications/alerts for out-of-range values
- Multiple graph time ranges (1h, 3h, 6h, 24h)
- Customizable page layout

## API Integration

The UI displays data from Nightscout API:
- **Endpoint**: `/api/v1/entries.json?count=200&token={token}`
- **Response**: Array of glucose entries (up to 200)
- **Fields Used**: sgv, direction, dateString, date
- **Update Frequency**: On-demand (Fetch Data button)

## Accessibility

- Large text for primary BG value (96px) - increased for better visibility
- High contrast colors
- Clear visual hierarchy
- Simple, focused interface per page
- Minimal cognitive load
- Visual navigation cues (arrows and page indicators)
- Tap-friendly navigation zones (80px wide)

## Summary

The app provides a complete, functional three-page UI for displaying CGM data from Nightscout:

### Page 1: Main Metrics
- ✅ Large BG display (96px) for quick glance
- ✅ Trend arrow and delta change indicators
- ✅ Last update timestamp
- ✅ Fetch Data button for manual refresh
- ✅ Clean, focused design prioritizing critical information

### Page 2: Graph View
- ✅ Larger graph canvas (200px tall) for detailed visualization
- ✅ Zoom controls (0.5x to 3.0x) for time range adjustment
- ✅ Displays up to 200 glucose readings
- ✅ Auto-scales based on visible data range
- ✅ Canvas-based line chart with smooth rendering

### Page 3: Settings/Configuration
- ✅ API URL display and verification
- ✅ Token validation with security indicators
- ✅ History information (data point count)
- ✅ Configuration status messages

### Navigation System
- ✅ Tap-based navigation on left/right edges
- ✅ Visual page indicators (3 dots)
- ✅ Navigation arrows showing available directions
- ✅ State persistence across pages
- ✅ Internet connectivity (via app-side service)
- ✅ All standard Zepp OS widgets properly configured
