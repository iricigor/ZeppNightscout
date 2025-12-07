# UI Components Overview

This document describes all the UI components implemented in the Nightscout Zepp OS app.

## Device Page Layout (page/index.js)

The app implements a complete UI with the following widgets:

### 1. Title Display
- **Type**: TEXT widget
- **Position**: Top of screen (y: 20)
- **Content**: "Nightscout" app name
- **Styling**: White text, 32px font, center-aligned

### 2. Settings Section
- **Label Widget**: Displays "API URL:" text
  - Position: y: 80
  - Color: Gray (0xaaaaaa)
  - Size: 20px
  
- **Value Widget**: Shows configured Nightscout URL
  - Position: y: 110
  - Color: Green (0x00ff00)
  - Size: 16px
  - Dynamic content from state.apiUrl

### 3. Current Blood Glucose Display
- **Type**: TEXT widget (Large display)
- **Position**: Center area (y: 170)
- **Content**: Current BG value (e.g., "120")
- **Styling**: 
  - Very large font (72px)
  - Green color (0x00ff00) - can be dynamic based on range
  - Center-aligned
  - Main focus of the app

### 4. Trend and Delta Indicators
- **Trend Widget**: Shows direction arrow
  - Position: Left half (y: 260)
  - Content: "Trend: →" (or ↑, ↓, etc.)
  - Size: 24px
  - Arrows: ⇈, ↑, ↗, →, ↘, ↓, ⇊

- **Delta Widget**: Shows change from previous reading
  - Position: Right half (y: 260)
  - Content: "Δ: +2" (change value)
  - Size: 24px
  - Shows positive/negative change

### 5. Last Update Timestamp
- **Type**: TEXT widget
- **Position**: Below trend/delta (y: 300)
- **Content**: "Last: 5 min ago"
- **Styling**: Gray text (0x888888), 18px
- **Dynamic**: Updates based on data freshness

### 6. Glucose Graph
- **Type**: CANVAS widget
- **Position**: Lower section (y: 340)
- **Size**: 440px wide × 100px tall
- **Features**:
  - Draws line graph of recent glucose readings
  - Auto-scales based on data range
  - Displays up to 10 recent readings
  - Shows trend over time
  - Fallback: "No data" text when empty

**Graph Drawing Logic**:
```javascript
- Connect data points with lines
- Scale Y-axis based on min/max values
- X-axis represents time (oldest to newest)
- Green line color (0x00ff00)
- Border rectangle for frame
```

### 7. Fetch Data Button
- **Type**: BUTTON widget
- **Position**: Bottom of screen (y: 450)
- **Size**: 120px wide × 40px tall
- **Content**: "Fetch Data" text
- **Styling**:
  - Blue background (0x0000ff)
  - Darker on press (0x000088)
  - Rounded corners (radius: 20)
- **Action**: Triggers API data fetch

## Color Scheme

- **Primary Text**: White (0xffffff)
- **Secondary Text**: Gray (0x888888, 0xaaaaaa)
- **Accent/Data**: Green (0x00ff00)
- **Button**: Blue (0x0000ff)
- **Graph Elements**: Green (0x00ff00)
- **Background**: Black/Dark (default Zepp OS)

## Layout Specifications

- **Screen**: 480×480 pixels (adjustable for different devices)
- **Margins**: 20px on all sides
- **Widget Spacing**: ~10-30px between sections
- **Responsive**: Can be adapted for different screen sizes

## State Management

The page maintains state for:
```javascript
{
  apiUrl: 'https://your-nightscout.herokuapp.com',
  currentBG: '--',          // Current glucose value
  trend: '--',              // Trend arrow
  delta: '--',              // Change from previous
  lastUpdate: '--',         // Time since update
  dataPoints: []            // Array for graph
}
```

## Widget Interactions

1. **Fetch Button Click**: 
   - Triggers `fetchData()` method
   - Updates BG value to "Loading..."
   - Sends message to app-side service
   - Updates all widgets on response

2. **Canvas Redraw**:
   - Called when new data arrives
   - Clears previous graph
   - Redraws with new data points
   - Auto-scales to fit data

## Data Flow

```
User clicks "Fetch Data"
    ↓
Device page sends message to app-side
    ↓
App-side fetches from Nightscout API
    ↓
App-side parses and processes data
    ↓
App-side sends response to device
    ↓
Device page updates all widgets
    ↓
Graph is redrawn with new data
```

## Future Enhancements

Potential UI improvements:
- Color-coded BG values (red for high/low, green for in-range)
- Touch/swipe gestures for history
- Additional pages for settings, history, statistics
- Animations for value changes
- Notifications/alerts for out-of-range values
- Multiple graph time ranges (1h, 3h, 6h, 24h)

## API Integration

The UI displays data from Nightscout API:
- **Endpoint**: `/api/v1/entries.json?count=10`
- **Response**: Array of glucose entries
- **Fields Used**: sgv, direction, dateString, date
- **Update Frequency**: On-demand (button press) or periodic

## Accessibility

- Large text for primary BG value (72px)
- High contrast colors
- Clear visual hierarchy
- Simple, focused interface
- Minimal cognitive load

## Summary

The app provides a complete, functional UI for displaying CGM data from Nightscout:
- ✅ Settings text field (API URL display)
- ✅ Graph widget (Canvas-based line chart)
- ✅ Calculated value fields (BG, trend, delta, timestamp)
- ✅ Internet connectivity (via app-side service)
- ✅ Clean, focused design
- ✅ All standard Zepp OS widgets properly configured
