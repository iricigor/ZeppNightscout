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
    
    // This is the absolute first action that creates a visual element.
    // If this runs, the framework is working.
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 100,
      w: screenWidth,
      h: 100,
      text: 'START OK!',
      text_size: 48,
      color: 0xffffff,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });

    // Add version info
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 200,
      w: screenWidth,
      h: 50,
      text: 'Version 0.3.0',
      text_size: 24,
      color: 0x00ff00,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });

    // Add simple instruction
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 280,
      w: screenWidth,
      h: 100,
      text: 'App is running successfully.\nMinimal test mode.',
      text_size: 20,
      color: 0xaaaaaa,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });

    // Add tap-to-close instruction
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 380,
      w: screenWidth,
      h: 50,
      text: 'Tap anywhere to close',
      text_size: 18,
      color: 0x888888,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });

    // Create an invisible full-screen button to capture tap events
    // Using BUTTON widget with transparent colors for better cross-version compatibility
    const tapHandler = hmUI.createWidget(hmUI.widget.BUTTON, {
      x: 0,
      y: 0,
      w: screenWidth,
      h: screenHeight,
      text: '',
      normal_color: 0x000000,
      press_color: 0x000000,
      radius: 0,
      click_func: () => {
        console.log('Screen tapped - closing app');
        hmApp.exit();
      }
    });
    
    // Set to fully transparent to make button invisible
    // This ensures it doesn't interfere with the text display
    tapHandler.setProperty(hmUI.prop.MORE, {
      alpha: 0  // Fully transparent - button is invisible but still captures clicks
    });
  },

  onDestroy() {
    console.log('App shutting down');
  }
});
