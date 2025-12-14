/**
 * Nightscout Zepp OS App - Second Test Page
 * Displays second page with back navigation via swipe gesture
 */

import * as messaging from '@zos/ble';
import { messageBuilder, MESSAGE_TYPES } from '../shared/message';

Page({
  onInit() {
    console.log('Second page starting');
    console.log('Page Navigation: page/page2 - init');
    
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

    // Button to trigger app-side action (demonstrates device-to-app-side communication)
    widgets.getSecretButton = hmUI.createWidget(hmUI.widget.BUTTON, {
      x: (screenWidth - 140) / 2,
      y: 190,
      w: 140,
      h: 50,
      radius: 25,
      normal_color: 0x0066cc,
      press_color: 0x0099ff,
      text: 'get secret',
      text_size: 20,
      color: 0xffffff,
      click_func: () => {
        console.log('Get secret button clicked - sending message to app-side');
        
        // Update button to show loading state
        widgets.getSecretButton.setProperty(hmUI.prop.TEXT, 'Loading...');
        widgets.getSecretButton.setProperty(hmUI.prop.COLOR, 0xffff00);
        
        // Send message to app-side to fetch secret
        try {
          const message = messageBuilder.request({
            type: MESSAGE_TYPES.GET_SECRET
          });
          console.log('Sending GET_SECRET message to app-side:', JSON.stringify(message));
          
          if (typeof messaging === 'undefined') {
            console.error('Messaging is undefined');
            widgets.resultText.setProperty(hmUI.prop.TEXT, 'Error: messaging unavailable');
            widgets.resultText.setProperty(hmUI.prop.COLOR, 0xff0000);
            widgets.getSecretButton.setProperty(hmUI.prop.TEXT, 'get secret');
            widgets.getSecretButton.setProperty(hmUI.prop.COLOR, 0xffffff);
            return;
          }
          
          messaging.peerSocket.send(message);
          console.log('Message sent successfully to app-side');
        } catch (error) {
          console.error('Error sending message to app-side:', error);
          widgets.resultText.setProperty(hmUI.prop.TEXT, 'Error: ' + error.message);
          widgets.resultText.setProperty(hmUI.prop.COLOR, 0xff0000);
          widgets.getSecretButton.setProperty(hmUI.prop.TEXT, 'get secret');
          widgets.getSecretButton.setProperty(hmUI.prop.COLOR, 0xffffff);
        }
      }
    });

    // Result text to display the response from app-side
    widgets.resultText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 250,
      w: screenWidth,
      h: 100,
      text: 'Tap button to fetch token\nfrom app-side',
      text_size: 18,
      color: 0x888888,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });

    // Setup messaging listener to receive responses from app-side
    messaging.peerSocket.addListener('message', (data) => {
      console.log('Received message from app-side:', JSON.stringify(data));
      
      // Handle secret response
      if (data && data.data && data.data.secret) {
        console.log('Processing secret response from app-side');
        
        // Reset button state
        widgets.getSecretButton.setProperty(hmUI.prop.TEXT, 'get secret');
        widgets.getSecretButton.setProperty(hmUI.prop.COLOR, 0xffffff);
        
        if (data.data.success && data.data.token) {
          // Success - display token (safely handle token display)
          console.log('Token received successfully from app-side');
          const token = String(data.data.token);
          const displayToken = token.length > 20 ? token.substring(0, 20) + '...' : token;
          widgets.resultText.setProperty(hmUI.prop.TEXT, 'Token: ' + displayToken);
          widgets.resultText.setProperty(hmUI.prop.COLOR, 0x00ff00);
        } else {
          // Error - display error message
          console.log('Error response from app-side:', data.data.error);
          widgets.resultText.setProperty(hmUI.prop.TEXT, 'Error: ' + (data.data.error || 'Unknown error'));
          widgets.resultText.setProperty(hmUI.prop.COLOR, 0xff0000);
        }
      }
    });

    // Swipe instructions for navigation back to first page
    widgets.swipeText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 360,
      w: screenWidth,
      h: 40,
      text: 'Swipe right...',
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
    console.log('Page Navigation: page/page2 - destroy');
  }
});
