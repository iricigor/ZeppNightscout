/**
 * Nightscout Zepp OS App - Second Test Page
 * Displays second page with back navigation
 */

Page({
  onInit() {
    console.log('Second page starting');
    
    // Get device screen dimensions for proper layout
    const deviceInfo = hmSetting.getDeviceInfo();
    const screenWidth = deviceInfo.width;
    const screenHeight = deviceInfo.height;
    
    // Store widget references
    const widgets = {};
    
    // Title
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 80,
      w: screenWidth,
      h: 60,
      text: 'Second Page',
      text_size: 32,
      color: 0xffffff,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });

    // Success message
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 140,
      w: screenWidth,
      h: 40,
      text: 'You made it!',
      text_size: 20,
      color: 0x00ff00,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });

    // Swipe instructions
    widgets.swipeText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 200,
      w: screenWidth,
      h: 40,
      text: 'Swipe right to go back',
      text_size: 18,
      color: 0x888888,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });

    // Gesture event listener for swipe detection
    hmApp.registerGestureEvent(function(event) {
      console.log('Gesture event received on page 2:', event);
      
      // Check for right swipe to go back
      if (event === hmApp.gesture.RIGHT) {
        console.log('Swipe right detected - going back to first page');
        // Show feedback before navigating
        widgets.swipeText.setProperty(hmUI.prop.TEXT, 'Going back...');
        widgets.swipeText.setProperty(hmUI.prop.COLOR, 0xff8800);
        
        // Navigate back after brief delay
        setTimeout(() => {
          hmApp.gotoPage({ url: 'page/index' });
        }, 300);
      }
      
      return true;
    });
  },

  onDestroy() {
    console.log('Second page shutting down');
  }
});
