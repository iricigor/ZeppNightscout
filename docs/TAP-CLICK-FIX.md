# Tap/Click Functionality Fix

## Issue
Tap and click actions were not working in the app, particularly for the checkbox and other interactive elements.

## Root Cause
The code was using `FILL_RECT` widgets with the `click_func` parameter for handling click events:

```javascript
// INCORRECT - FILL_RECT doesn't support click_func
hmUI.createWidget(hmUI.widget.FILL_RECT, {
  x: 0,
  y: 100,
  w: screenWidth,
  h: 100,
  alpha: 0, // Invisible
  click_func: handler // ❌ This doesn't work!
});
```

**According to Zepp OS v1 API documentation**, `FILL_RECT` widgets do NOT support the `click_func` parameter. Only `BUTTON` widgets support `click_func`.

## Solution
Replace all invisible `FILL_RECT` click handlers with transparent `BUTTON` widgets:

```javascript
// CORRECT - BUTTON supports click_func
hmUI.createWidget(hmUI.widget.BUTTON, {
  x: 0,
  y: 100,
  w: screenWidth,
  h: 100,
  normal_color: 0x000000,  // Black (transparent on black background)
  press_color: 0x333333,   // Slightly lighter when pressed
  text: '',                // No text, just a clickable area
  radius: 0,               // Sharp corners
  click_func: handler      // ✅ This works!
});
```

## Changes Made
Updated 5 click-sensitive areas in `page/index.js`:
1. Start text tap area (line 64)
2. Version text tap area (line 92)
3. Instruction text tap area (line 120)
4. Tap instruction text tap area (line 148)
5. Checkbox click area (line 247)

## Alternative Approach (Not Used)
Another valid approach would be to use `addEventListener` on `FILL_RECT`:

```javascript
// Alternative approach using event listener
const fillRect = hmUI.createWidget(hmUI.widget.FILL_RECT, {
  x: 0,
  y: 100,
  w: screenWidth,
  h: 100,
  alpha: 0
});

fillRect.addEventListener(hmUI.event.CLICK_DOWN, (info) => {
  handler();
});
```

However, using `BUTTON` widgets with `click_func` is simpler and more straightforward.

## Visual Elements
Note that `FILL_RECT` widgets are still used for visual elements (like the checkbox border and inner background) where no click handling is needed. This is perfectly fine.

## Testing
- All existing tests pass (77 assertions)
- Syntax validation passes
- Ready for device testing

## References
- [Zepp OS v1 BUTTON Widget Documentation](https://docs.zepp.com/docs/1.0/watchface/api/hmUI/widget/BUTTON/)
- [Zepp OS v1 FILL_RECT Widget Documentation](https://docs.zepp.com/docs/1.0/watchface/api/hmUI/widget/FILL_RECT/)

## Date
December 10, 2025
