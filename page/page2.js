/**
 * Nightscout Zepp OS App - Second Test Page
 * Displays second page with back navigation via swipe gesture
 */

Page({
  onInit() {
    console.log('=== PAGE2 INIT START ===');
    console.log('Second page starting');
    console.log('Page Navigation: page/page2 - init');
    
    // Verify getApp() exists
    console.log('Checking getApp():', typeof getApp !== 'undefined' ? 'EXISTS' : 'UNDEFINED');
    if (typeof getApp === 'undefined') {
      console.error('CRITICAL: getApp is undefined');
      return;
    }
    
    // Get app instance
    const app = getApp();
    console.log('app instance:', app ? 'EXISTS' : 'NULL');
    console.log('app.globalData:', app && app.globalData ? 'EXISTS' : 'UNDEFINED');
    
    // Log globalData contents and get messageBuilder/MESSAGE_TYPES
    if (!app || !app.globalData) {
      console.error('CRITICAL: app.globalData is not available');
      return;
    }
    
    console.log('globalData keys:', Object.keys(app.globalData).join(', '));
    console.log('messageBuilder:', typeof app.globalData.messageBuilder);
    console.log('MESSAGE_TYPES:', typeof app.globalData.MESSAGE_TYPES);
    
    const { messageBuilder, MESSAGE_TYPES } = app.globalData;
    
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
          
          // Extensive BLE logging
          console.log('=== BLE SEND START ===');
          console.log('typeof hmBle:', typeof hmBle);
          
          if (typeof hmBle === 'undefined') {
            console.error('CRITICAL: hmBle is undefined or not available');
            widgets.resultText.setProperty(hmUI.prop.TEXT, 'Error: BLE unavailable');
            widgets.resultText.setProperty(hmUI.prop.COLOR, 0xff0000);
            widgets.getSecretButton.setProperty(hmUI.prop.TEXT, 'get secret');
            widgets.getSecretButton.setProperty(hmUI.prop.COLOR, 0xffffff);
            return;
          }
          
          // Log hmBle methods
          console.log('hmBle.send:', typeof hmBle.send);
          console.log('hmBle.str2buf:', typeof hmBle.str2buf);
          console.log('hmBle.buf2str:', typeof hmBle.buf2str);
          console.log('hmBle.createConnect:', typeof hmBle.createConnect);
          console.log('hmBle.disConnect:', typeof hmBle.disConnect);
          
          try {
            // Convert message to buffer for hmBle.send
            const messageStr = JSON.stringify(message);
            console.log('Message string:', messageStr);
            console.log('Message string length:', messageStr.length);
            
            if (typeof hmBle.str2buf !== 'function') {
              throw new Error('hmBle.str2buf is not a function');
            }
            
            const messageBuffer = hmBle.str2buf(messageStr);
            console.log('Buffer created:', messageBuffer ? 'YES' : 'NO');
            console.log('Buffer byteLength:', messageBuffer ? messageBuffer.byteLength : 'N/A');
            
            if (!messageBuffer || messageBuffer.byteLength === 0) {
              throw new Error('Failed to convert message to buffer');
            }
            
            if (typeof hmBle.send !== 'function') {
              throw new Error('hmBle.send is not a function');
            }
            
            const sendResult = hmBle.send(messageBuffer, messageBuffer.byteLength);
            console.log('hmBle.send() result:', sendResult);
            console.log('Message sent successfully to app-side');
            console.log('=== BLE SEND END ===');
          } catch (sendError) {
            console.error('=== BLE SEND ERROR ===');
            console.error('Error name:', sendError.name);
            console.error('Error message:', sendError.message);
            console.error('Error stack:', sendError.stack);
            widgets.resultText.setProperty(hmUI.prop.TEXT, 'Error: ' + sendError.message);
            widgets.resultText.setProperty(hmUI.prop.COLOR, 0xff0000);
            widgets.getSecretButton.setProperty(hmUI.prop.TEXT, 'get secret');
            widgets.getSecretButton.setProperty(hmUI.prop.COLOR, 0xffffff);
          }
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

    // Setup BLE connection to receive responses from app-side
    console.log('=== BLE RECEIVE SETUP START ===');
    console.log('Setting up BLE listener for responses from app-side');
    console.log('typeof hmBle:', typeof hmBle);
    console.log('typeof hmBle.createConnect:', typeof hmBle.createConnect);
    
    if (typeof hmBle === 'undefined') {
      console.error('CRITICAL: hmBle undefined, cannot setup listener');
      return;
    }
    
    if (typeof hmBle.createConnect !== 'function') {
      console.error('CRITICAL: hmBle.createConnect is not a function');
      console.error('Available hmBle methods:', Object.keys(hmBle).join(', '));
      return;
    }
    
    try {
      const connectResult = hmBle.createConnect(function(index, data, size) {
        console.log('=== BLE MESSAGE RECEIVED ===');
        console.log('Callback invoked with index:', index, 'size:', size);
        console.log('data type:', typeof data);
        console.log('data value:', data);
        
        try {
          // Verify buf2str exists
          if (typeof hmBle.buf2str !== 'function') {
            console.error('CRITICAL: hmBle.buf2str is not a function');
            return;
          }
          
          // Convert buffer to string
          console.log('Converting buffer to string...');
          const dataStr = hmBle.buf2str(data, size);
          console.log('Buffer converted, string length:', dataStr ? dataStr.length : 'NULL');
          console.log('Data string:', dataStr);
          
          // Parse JSON
          console.log('Parsing JSON...');
          const parsedData = JSON.parse(dataStr);
          console.log('JSON parsed successfully');
          console.log('Parsed data type:', typeof parsedData);
          console.log('Parsed data:', JSON.stringify(parsedData));
          
          // Check for secret response
          console.log('Checking for secret response...');
          console.log('parsedData.data exists:', parsedData && parsedData.data ? 'YES' : 'NO');
          console.log('parsedData.data.secret exists:', parsedData && parsedData.data && parsedData.data.secret ? 'YES' : 'NO');
          
          // Handle secret response
          if (parsedData && parsedData.data && parsedData.data.secret) {
            console.log('Processing secret response from app-side');
            console.log('success:', parsedData.data.success);
            console.log('token exists:', parsedData.data.token ? 'YES' : 'NO');
            console.log('error:', parsedData.data.error);
            
            // Reset button state
            widgets.getSecretButton.setProperty(hmUI.prop.TEXT, 'get secret');
            widgets.getSecretButton.setProperty(hmUI.prop.COLOR, 0xffffff);
            
            if (parsedData.data.success && parsedData.data.token) {
              // Success - display token (safely handle token display)
              console.log('Token received successfully from app-side');
              const token = String(parsedData.data.token);
              const displayToken = token.length > 20 ? token.substring(0, 20) + '...' : token;
              console.log('Display token:', displayToken);
              widgets.resultText.setProperty(hmUI.prop.TEXT, 'Token: ' + displayToken);
              widgets.resultText.setProperty(hmUI.prop.COLOR, 0x00ff00);
            } else {
              // Error - display error message
              console.log('Error response from app-side:', parsedData.data.error);
              widgets.resultText.setProperty(hmUI.prop.TEXT, 'Error: ' + (parsedData.data.error || 'Unknown error'));
              widgets.resultText.setProperty(hmUI.prop.COLOR, 0xff0000);
            }
          } else {
            console.log('Message received but not a secret response');
          }
        } catch (error) {
          console.error('=== BLE MESSAGE PARSE ERROR ===');
          console.error('Error name:', error.name);
          console.error('Error message:', error.message);
          console.error('Error stack:', error.stack);
        }
        
        console.log('=== BLE MESSAGE RECEIVED END ===');
      });
      
      console.log('createConnect result:', connectResult);
      console.log('BLE listener setup complete');
      console.log('=== BLE RECEIVE SETUP END ===');
    } catch (setupError) {
      console.error('=== BLE SETUP ERROR ===');
      console.error('Error name:', setupError.name);
      console.error('Error message:', setupError.message);
      console.error('Error stack:', setupError.stack);
    }

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
    
    console.log('=== PAGE2 INIT COMPLETE ===');
  },

  onDestroy() {
    console.log('=== PAGE2 DESTROY START ===');
    console.log('Second page shutting down');
    console.log('Page Navigation: page/page2 - destroy');
    
    // Disconnect BLE connection
    console.log('typeof hmBle:', typeof hmBle);
    console.log('typeof hmBle.disConnect:', typeof hmBle.disConnect);
    
    if (typeof hmBle !== 'undefined' && typeof hmBle.disConnect === 'function') {
      try {
        const disconnectResult = hmBle.disConnect();
        console.log('hmBle.disConnect() result:', disconnectResult);
        console.log('BLE disconnected successfully');
      } catch (error) {
        console.error('Error disconnecting BLE:', error.name, error.message);
      }
    } else {
      console.log('hmBle.disConnect not available, skipping cleanup');
    }
    
    console.log('=== PAGE2 DESTROY END ===');
  }
});
