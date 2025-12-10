/**
 * Nightscout Zepp OS App - Minimal Starting Screen
 * Simple test to verify the framework is working
 */

Page({
  onInit() {
    console.log('App starting - minimal version');
    
    // Get device screen dimensions for proper layout
    const deviceInfo = hmSetting.getDeviceInfo();
    const screenWidth = deviceInfo.width;
    const screenHeight = deviceInfo.height;
    
    // Store widget references for tap feedback
    const widgets = {};
    
    // Helper function to create tap feedback handler
    const createTapFeedback = (widgetId, logMessage, maxExclamations = 3) => {
      return () => {
        console.log(logMessage);
        const widget = widgets[widgetId];
        if (widget) {
          const currentText = widget.getProperty(hmUI.prop.TEXT);
          // Count existing exclamation marks at the end
          const match = currentText.match(/!+$/);
          const exclamationCount = match ? match[0].length : 0;
          if (exclamationCount < maxExclamations) {
            widget.setProperty(hmUI.prop.TEXT, currentText + '!');
          } else {
            // After 4th tap (when 3 exclamation marks are showing), close the app
            console.log('Max taps reached - closing app');
            hmApp.exit();
          }
        }
      };
    };
    
    // Reusable click handler for closing the app
    const closeApp = () => {
      console.log('Screen tapped - closing app');
      hmApp.exit();
    };
    
    // This is the absolute first action that creates a visual element.
    // If this runs, the framework is working.
    widgets.start = hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 100,
      w: screenWidth,
      h: 100,
      text: 'START OK!',
      text_size: 48,
      color: 0xffffff,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V,
      click_func: createTapFeedback('start', 'START OK! tapped')
    });

    // Add version info
    widgets.version = hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 200,
      w: screenWidth,
      h: 50,
      text: 'Version 0.3.0',
      text_size: 24,
      color: 0x00ff00,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V,
      click_func: createTapFeedback('version', 'Version tapped')
    });

    // Add simple instruction
    widgets.instruction = hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 280,
      w: screenWidth,
      h: 100,
      text: 'App is running successfully.\nMinimal test mode.',
      text_size: 20,
      color: 0xaaaaaa,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V,
      click_func: createTapFeedback('instruction', 'Instruction tapped')
    });

    // Add tap-to-close instruction with click handler
    widgets.tap = hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 380,
      w: screenWidth,
      h: 50,
      text: 'tap anywhere to close',
      text_size: 18,
      color: 0x888888,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V,
      click_func: createTapFeedback('tap', 'Tap instruction tapped')
    });
  },

  onDestroy() {
    console.log('App shutting down');
  }
});
