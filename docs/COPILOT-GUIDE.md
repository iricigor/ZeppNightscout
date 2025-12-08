# GitHub Copilot Usage Guide

This guide shows how to effectively use GitHub Copilot when developing the Nightscout Zepp OS app.

## Setup in Codespaces

When you open this project in GitHub Codespaces:
1. ✅ GitHub Copilot extension is automatically installed
2. ✅ GitHub Copilot Chat extension is automatically installed
3. ✅ Copilot is configured to work with JavaScript files
4. ✅ Auto-completion is enabled

## Using Copilot for Code Completion

### Example 1: Adding New Functions

Write a comment describing what you want:

```javascript
// Function to calculate average glucose over last 24 hours
```

Copilot will suggest:
```javascript
function calculateAverage24h(dataPoints) {
  const sum = dataPoints.reduce((acc, val) => acc + val, 0);
  return Math.round(sum / dataPoints.length);
}
```

### Example 2: Implementing Error Handling

Start typing and Copilot completes:

```javascript
// Add try-catch error handling
try {
  // Copilot suggests the complete block
  const response = await fetch(apiUrl);
  const data = await response.json();
  return data;
} catch (error) {
  console.error('Fetch error:', error);
  throw error;
}
```

### Example 3: Creating New UI Widgets

```javascript
// Create a settings button at the bottom
const settingsButton = hmUI.createWidget(hmUI.widget.BUTTON, {
  x: 50,
  y: 500,
  w: 100,
  h: 40,
  text: 'Settings',
  // Copilot suggests the rest
  normal_color: 0x333333,
  press_color: 0x1a1a1a,
  radius: 20,
  click_func: () => {
    // Navigate to settings page
  }
});
```

## Using Copilot Chat

### Getting Explanations

Ask Copilot Chat:
```
What does the parseNightscoutData function do?
```

Copilot explains the code in context.

### Getting Implementation Help

Ask Copilot Chat:
```
How do I add authentication token support to the Nightscout API calls?
```

Copilot provides specific implementation steps.

### Debugging Help

Ask Copilot Chat:
```
Why might the canvas graph not be displaying?
```

Copilot analyzes the code and suggests potential issues.

## Common Development Tasks with Copilot

### Task 1: Adding Color-Coded BG Values

**Your Comment:**
```javascript
// Function to get color based on glucose value
// Returns green for 70-180, yellow for 180-250, red for >250 or <70
```

**Copilot Suggests:**
```javascript
function getBGColor(bgValue) {
  const value = parseInt(bgValue);
  if (value < 70 || value > 250) return 0xff0000; // Red
  if (value > 180) return 0xffff00; // Yellow
  return 0x00ff00; // Green
}
```

### Task 2: Adding Time Range Filter

**Your Comment:**
```javascript
// Filter glucose entries by time range (last N hours)
```

**Copilot Suggests:**
```javascript
function filterByTimeRange(entries, hours) {
  const cutoff = Date.now() - (hours * 60 * 60 * 1000);
  return entries.filter(entry => entry.date > cutoff);
}
```

### Task 3: Implementing Data Caching

**Your Comment:**
```javascript
// Cache data locally with expiration time
```

**Copilot Suggests:**
```javascript
const cache = {
  data: null,
  timestamp: null,
  maxAge: 5 * 60 * 1000, // 5 minutes
  
  set(data) {
    this.data = data;
    this.timestamp = Date.now();
  },
  
  get() {
    if (!this.data || !this.timestamp) return null;
    if (Date.now() - this.timestamp > this.maxAge) return null;
    return this.data;
  },
  
  isValid() {
    return this.get() !== null;
  }
};
```

### Task 4: Adding Statistics Calculation

**Your Comment:**
```javascript
// Calculate time in range (70-180 mg/dL) as percentage
```

**Copilot Suggests:**
```javascript
function calculateTimeInRange(dataPoints) {
  const inRange = dataPoints.filter(bg => bg >= 70 && bg <= 180).length;
  const total = dataPoints.length;
  return Math.round((inRange / total) * 100);
}
```

## Copilot Chat Commands

### Analyze Code
```
/explain [select code]
```

### Fix Issues
```
/fix [select code with error]
```

### Generate Tests
```
/tests [select function]
```

### Refactor
```
How can I refactor this to be more efficient?
```

## Best Practices for Copilot

### 1. Write Clear Comments

❌ Bad:
```javascript
// get data
```

✅ Good:
```javascript
// Fetch glucose entries from Nightscout API for the last 6 hours
// Returns array of {sgv, direction, date} objects
```

### 2. Use Descriptive Function Names

❌ Bad:
```javascript
function proc(d) {
```

✅ Good:
```javascript
function parseGlucoseEntries(rawApiResponse) {
```

### 3. Break Down Complex Tasks

Instead of:
```javascript
// Create complete settings page with validation
```

Break it down:
```javascript
// Step 1: Create settings page layout
// Step 2: Add input validation
// Step 3: Add save button handler
```

### 4. Provide Context

```javascript
// In Zepp OS, canvas drawing requires beginPath() before each shape
// Draw a line from previous point to current point
```

### 5. Review Generated Code

Always review Copilot suggestions:
- Check for logic errors
- Verify API compatibility
- Test edge cases
- Ensure code style consistency

## Example Development Session

### Goal: Add High/Low Alerts

**Step 1: Define the feature**
```javascript
// Add alert thresholds for high (>180) and low (<70) glucose
// Show warning icon when out of range
```

**Step 2: Create threshold constants**
```javascript
const THRESHOLDS = {
  // Copilot suggests
  HIGH: 180,
  LOW: 70,
  CRITICAL_HIGH: 250,
  CRITICAL_LOW: 54
};
```

**Step 3: Add alert checking function**
```javascript
// Check if glucose value triggers an alert
function checkAlert(bgValue) {
  // Copilot suggests complete implementation
}
```

**Step 4: Add visual indicator**
```javascript
// Create alert icon widget that shows/hides based on glucose level
const alertIcon = hmUI.createWidget(hmUI.widget.IMG, {
  // Copilot suggests properties
});
```

**Step 5: Test with Copilot Chat**
Ask: "Can you suggest test cases for the alert checking logic?"

## Troubleshooting with Copilot

### Issue: Code not working as expected

**Ask Copilot Chat:**
```
I'm trying to draw a graph on canvas but nothing appears. 
Here's my code: [paste code]
What could be wrong?
```

### Issue: API not returning data

**Ask Copilot Chat:**
```
The Nightscout API fetch is failing. How do I debug this?
What logging should I add?
```

### Issue: Performance problems

**Ask Copilot Chat:**
```
The canvas redraw is slow. How can I optimize this?
```

## Advanced Copilot Features

### Multi-file Context

Copilot can understand code across files:
- References to functions in other files
- Import/export relationships
- Shared constants and types

### Code Patterns

Copilot learns from your codebase:
- Naming conventions
- Code structure
- Error handling patterns
- Comment style

### API Awareness

Copilot knows Zepp OS APIs:
- Widget creation
- Canvas drawing
- Messaging system
- Data storage

## Learning Resources

### Official Docs
- [GitHub Copilot Documentation](https://docs.github.com/copilot)
- [Zepp OS Documentation](https://docs.zepp.com/)
- [JavaScript MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript)

### Tips
1. Use Copilot for boilerplate code
2. Ask Chat for explanations of complex logic
3. Let Copilot generate test cases
4. Use suggestions as starting points, not final code
5. Learn from Copilot's suggestions

## Quick Reference

| Task | How to Use Copilot |
|------|-------------------|
| New function | Write descriptive comment |
| Error handling | Type `try {` and let Copilot complete |
| Widget creation | Type `hmUI.createWidget(` and accept suggestion |
| Data transformation | Comment what you want, accept suggestion |
| Debug help | Ask Copilot Chat with context |
| Refactoring | Select code, ask Chat for improvements |
| Documentation | Ask Chat to explain selected code |
| Best practices | Ask Chat for code review |

## Summary

GitHub Copilot is configured and ready to use in this project:
- ✅ Auto-completion for code
- ✅ Chat for questions and help
- ✅ Context-aware suggestions
- ✅ Zepp OS API knowledge
- ✅ JavaScript best practices
- ✅ Integrated in Codespaces

Start coding and let Copilot assist you! Remember to review all suggestions and test thoroughly.

## Important: Release Pipeline Maintenance

When modifying the release workflow (`.github/workflows/release.yml`):
1. **Always update the PR tracking comment** in the "Get version and build number" step
2. Change `# Last modification done in PR iricigor/ZeppNightscout#XX` to your current PR number
3. This helps track which PR last modified the release pipeline and prevents confusion when debugging pipeline issues
