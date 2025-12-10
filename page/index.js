/**
 * Nightscout Zepp OS App - Minimal Starting Screen
 * Simple test to verify the framework is working
 */

Page({
  onInit() {
    console.log('App starting - minimal version');
    
    // This is the absolute first action that creates a visual element.
    // If this runs, the framework is working.
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: 0,
      y: 100,
      w: 480,
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
      w: 480,
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
      w: 480,
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
      w: 480,
      h: 50,
      text: 'Tap anywhere to close',
      text_size: 18,
      color: 0x888888,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V
    });

    // Create an invisible full-screen widget to capture tap events
    const tapHandler = hmUI.createWidget(hmUI.widget.IMG, {
      x: 0,
      y: 0,
      w: 480,
      h: 480,
      src: ''  // No image, making it invisible
    });

    // Add tap event listener to close the app
    tapHandler.addEventListener(hmUI.event.CLICK_UP, (info) => {
      console.log('Screen tapped at', info.x, info.y, '- closing app');
      hmApp.exit();
    });
  },

  onDestroy() {
    console.log('App shutting down');
  }
});
