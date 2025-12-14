/**
 * Nightscout Zepp OS App - Second Test Page
 * Displays second page with back navigation and secret token fetching
 */

import { messageBuilder, MESSAGE_TYPES } from '../shared/message';

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

    // Swipe instructions (now in one row as per requirement)
    widgets.swipeText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 200,
      w: screenWidth,
      h: 40,
      text: 'Swipe right...',
      text_size: 18,
      color: 0x888888,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });

    // Get secret button
    widgets.secretButton = hmUI.createWidget(hmUI.widget.BUTTON, {
      x: (screenWidth - 140) / 2,
      y: 250,
      w: 140,
      h: 50,
      radius: 25,
      normal_color: 0x0066cc,
      press_color: 0x0099ff,
      text: 'get secret',
      text_size: 20,
      color: 0xffffff,
      click_func: () => {
        console.log('Get secret button clicked');
        widgets.resultText.setProperty(hmUI.prop.TEXT, 'Loading...');
        widgets.resultText.setProperty(hmUI.prop.COLOR, 0xffff00);
        
        // Send message to app-side to fetch token
        const message = messageBuilder.request({
          type: MESSAGE_TYPES.GET_SECRET
        });
        messaging.peerSocket.send(message);
      }
    });

    // Result text (displayed below button)
    widgets.resultText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: 20,
      y: 320,
      w: screenWidth - 40,
      h: 120,
      text: '',
      text_size: 16,
      color: 0xffffff,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.TOP,
      text_style: hmUI.text_style.WRAP
    });

    // Setup message listener for app-side responses
    messaging.peerSocket.addListener('message', (data) => {
      console.log('Received message from app-side:', data);
      
      // Check if this is a secret response
      if (data.type !== 'response' || !data.data || !data.data.secret) {
        return; // Not a secret response, ignore
      }
      
      // Handle secret token response
      if (data.data.success && data.data.token) {
        widgets.resultText.setProperty(hmUI.prop.TEXT, 'Token:\n' + data.data.token);
        widgets.resultText.setProperty(hmUI.prop.COLOR, 0x00ff00);
      } else {
        const errorMsg = data.data.error || 'Unknown error';
        widgets.resultText.setProperty(hmUI.prop.TEXT, 'Error:\n' + errorMsg);
        widgets.resultText.setProperty(hmUI.prop.COLOR, 0xff0000);
      }
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
