/**
 * Nightscout Zepp OS App - Clean Start Page
 * Simplified interface with button and swipe detection
 */

Page({
  onInit() {
    console.log('App starting');
    console.log('Page Navigation: page/index - init');
    
    // Get device screen dimensions for proper layout
    const deviceInfo = hmSetting.getDeviceInfo();
    const screenWidth = deviceInfo.width;
    const screenHeight = deviceInfo.height;
    
    // Store widget references
    const widgets = {};
    
    // Swipe instruction text constant to avoid duplication
    const SWIPE_INSTRUCTIONS = 'Swipe for debug pages:\nLeft = GET_SECRET test\nUp = BLE Inspector\nDown = Alt BLE test';
    
    // Title
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 80,
      w: screenWidth,
      h: 60,
      text: 'ZeppNightscout',
      text_size: 32,
      color: 0xffffff,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });

    // Simple subtitle
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 140,
      w: screenWidth,
      h: 40,
      text: 'Test Page',
      text_size: 20,
      color: 0xaaaaaa,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });

    // Simple button that changes from "click" to "clicked"
    widgets.button = hmUI.createWidget(hmUI.widget.BUTTON, {
      x: (screenWidth - 120) / 2,
      y: 200,
      w: 120,
      h: 50,
      radius: 25,
      normal_color: 0x0066cc,
      press_color: 0x0099ff,
      text: 'click',
      text_size: 24,
      color: 0xffffff,
      click_func: () => {
        console.log('Button clicked');
        widgets.button.setProperty(hmUI.prop.TEXT, 'clicked');
        // Navigate to second page
        setTimeout(() => {
          hmApp.gotoPage({ url: 'page/page2' });
        }, 300);
      }
    });

    // Swipe instructions
    widgets.swipeText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 280,
      w: screenWidth,
      h: 100,
      text: SWIPE_INSTRUCTIONS,
      text_size: 16,
      color: 0x888888,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });

    // Gesture event listener for swipe detection
    hmApp.registerGestureEvent(function(event) {
      console.log('Gesture event received:', event);
      
      let feedbackText = '';
      let feedbackColor = 0xffffff;
      
      // Check gesture type and provide feedback
      if (event === hmApp.gesture.UP) {
        console.log('Swipe up detected - navigating to BLE Inspector');
        feedbackText = 'Opening BLE Inspector...';
        feedbackColor = 0x00ff00;
        // Navigate to BLE Inspector page
        setTimeout(() => {
          hmApp.gotoPage({ url: 'page/ble-inspector' });
        }, 300);
      } else if (event === hmApp.gesture.DOWN) {
        console.log('Swipe down detected - navigating to Alternative BLE');
        feedbackText = 'Opening Alternative BLE...';
        feedbackColor = 0x00ffff;
        // Navigate to Alternative BLE page
        setTimeout(() => {
          hmApp.gotoPage({ url: 'page/page2-alternative' });
        }, 300);
      } else if (event === hmApp.gesture.LEFT) {
        console.log('Swipe left detected');
        feedbackText = 'Opening GET_SECRET test...';
        feedbackColor = 0xffff00;
        // Navigate to second page
        setTimeout(() => {
          hmApp.gotoPage({ url: 'page/page2' });
        }, 300);
      } else if (event === hmApp.gesture.RIGHT) {
        console.log('Swipe right detected');
        feedbackText = 'Swipe right detected!';
        feedbackColor = 0xff8800;
      }
      
      // Show feedback and reset after 2 seconds
      if (feedbackText) {
        widgets.swipeText.setProperty(hmUI.prop.TEXT, feedbackText);
        widgets.swipeText.setProperty(hmUI.prop.COLOR, feedbackColor);
        setTimeout(() => {
          widgets.swipeText.setProperty(hmUI.prop.TEXT, SWIPE_INSTRUCTIONS);
          widgets.swipeText.setProperty(hmUI.prop.COLOR, 0x888888);
        }, 2000);
      }
      
      return true;
    });
  },

  onDestroy() {
    console.log('App shutting down');
    console.log('Page Navigation: page/index - destroy');
  }
});
