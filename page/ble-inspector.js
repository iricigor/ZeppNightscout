/**
 * BLE Inspector Page - Debug tool to inspect available BLE APIs
 */

Page({
  onInit() {
    console.log('=== BLE INSPECTOR START ===');
    
    const deviceInfo = hmSetting.getDeviceInfo();
    const screenWidth = deviceInfo.width;
    const screenHeight = deviceInfo.height;
    
    // Title
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 60,
      w: screenWidth,
      h: 40,
      text: 'BLE Inspector',
      text_size: 28,
      color: 0xffffff,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });
    
    // Results text area
    const resultText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: 10,
      y: 110,
      w: screenWidth - 20,
      h: screenHeight - 170,
      text: 'Inspecting BLE APIs...',
      text_size: 16,
      color: 0x00ff00,
      align_h: hmUI.align.LEFT,
      align_v: hmUI.align.TOP
    });
    
    // Inspect BLE APIs
    let report = 'BLE API Inspection\n\n';
    
    // Check hmBle existence
    report += 'typeof hmBle: ' + typeof hmBle + '\n';
    report += 'hmBle defined: ' + (typeof hmBle !== 'undefined' ? 'YES' : 'NO') + '\n\n';
    
    if (typeof hmBle !== 'undefined') {
      report += 'Available methods:\n';
      
      const methods = [];
      for (let key in hmBle) {
        methods.push(key + ': ' + typeof hmBle[key]);
      }
      
      report += methods.join('\n') + '\n\n';
      
      // Check specific methods we care about
      const keysToCheck = [
        'send', 'createConnect', 'disConnect',
        'str2buf', 'buf2str',
        'mstPrepare', 'mstOnConnect', 'mstOnDisconnect',
        'on', 'off', 'emit',
        'connect', 'disconnect', 'isConnected',
        'onMessage', 'addListener', 'removeListener',
        'createListener'
      ];
      
      report += 'Specific checks:\n';
      for (let key of keysToCheck) {
        const exists = key in hmBle;
        const type = exists ? typeof hmBle[key] : 'N/A';
        report += key + ': ' + (exists ? 'EXISTS (' + type + ')' : 'NOT FOUND') + '\n';
      }
      
      console.log(report);
    } else {
      report += 'hmBle is not available!';
      console.error(report);
    }
    
    // Check app.globalData
    report += '\n\nGlobalData Check:\n';
    const app = getApp();
    if (app && app.globalData) {
      report += 'globalData: EXISTS\n';
      report += 'messageBuilder: ' + typeof app.globalData.messageBuilder + '\n';
      report += 'MESSAGE_TYPES: ' + typeof app.globalData.MESSAGE_TYPES + '\n';
    } else {
      report += 'globalData: NOT AVAILABLE\n';
    }
    
    // Display the report
    resultText.setProperty(hmUI.prop.TEXT, report);
    
    // Store widgets reference
    const widgets = {
      swipeText: null
    };
    
    // Swipe instructions for navigation back to first page
    widgets.swipeText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: screenHeight - 90,
      w: screenWidth,
      h: 30,
      text: 'Swipe right to go back',
      text_size: 16,
      color: 0x888888,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });
    
    // Button to go back
    hmUI.createWidget(hmUI.widget.BUTTON, {
      x: (screenWidth - 100) / 2,
      y: screenHeight - 50,
      w: 100,
      h: 40,
      radius: 20,
      normal_color: 0x0066cc,
      press_color: 0x0099ff,
      text: 'Back',
      text_size: 18,
      color: 0xffffff,
      click_func: () => {
        hmApp.gotoPage({ url: 'page/index' });
      }
    });
    
    // Gesture event listener for swipe detection
    hmApp.registerGestureEvent(function(event) {
      console.log('Gesture event received on BLE inspector:', event);
      
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
    
    console.log('=== BLE INSPECTOR END ===');
  }
});
