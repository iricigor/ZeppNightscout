/**
 * Nightscout Zepp OS App - Device Page
 * Displays CGM data with settings, graph, and calculated values
 */

import { messageBuilder, MESSAGE_TYPES } from '../shared/message';

// Screen dimensions (adjust for different devices)
const SCREEN_WIDTH = 480;
const SCREEN_HEIGHT = 480;
const MARGIN = 20;

// Data configuration
const DATA_POINTS_COUNT = 200; // Number of glucose readings to fetch and display

Page({
  state: {
    apiUrl: 'https://your-nightscout.herokuapp.com',
    currentBG: '--',
    trend: '--',
    delta: '--',
    lastUpdate: '--',
    dataPoints: [],
    verificationStatus: ''
  },

  onInit() {
    console.log('Nightscout app initialized');
    this.setupMessageHandlers();
    this.buildUI();
  },

  /**
   * Setup message handlers for receiving data from app-side
   */
  setupMessageHandlers() {
    // Listen for messages from app-side
    messaging.peerSocket.addListener('message', (data) => {
      console.log('Received message from app-side:', data);
      
      if (data.type === 'response') {
        if (data.data.verification) {
          // Handle verification result
          this.handleVerificationResult(data.data);
        } else if (data.data.error) {
          // Handle error
          this.handleError(data.data);
        } else {
          // Handle data update
          this.handleDataUpdate(data.data);
        }
      }
    });
  },

  /**
   * Handle verification result from app-side
   * @param {Object} result - Verification result
   */
  handleVerificationResult(result) {
    this.state.verificationStatus = result.message;
    this.widgets.verificationStatus.setProperty(hmUI.prop.TEXT, result.message);
    
    if (result.success) {
      this.widgets.verificationStatus.setProperty(hmUI.prop.COLOR, 0x00ff00);
    } else {
      this.widgets.verificationStatus.setProperty(hmUI.prop.COLOR, 0xff0000);
    }
  },

  /**
   * Handle data update from app-side
   * @param {Object} data - Glucose data
   */
  handleDataUpdate(data) {
    this.state.currentBG = data.currentBG || '--';
    this.state.trend = data.trend || '--';
    this.state.delta = data.delta || '--';
    this.state.lastUpdate = data.lastUpdate || '--';
    this.state.dataPoints = data.dataPoints || [];

    // Update UI
    this.widgets.bgValue.setProperty(hmUI.prop.TEXT, this.state.currentBG);
    this.widgets.bgValue.setProperty(hmUI.prop.COLOR, 0x00ff00);
    this.widgets.trendText.setProperty(hmUI.prop.TEXT, `Trend: ${this.state.trend}`);
    this.widgets.deltaText.setProperty(hmUI.prop.TEXT, `Δ: ${this.state.delta}`);
    this.widgets.lastUpdateText.setProperty(hmUI.prop.TEXT, `Last: ${this.state.lastUpdate}`);

    // Redraw graph
    this.drawGraph();
  },

  /**
   * Handle error from app-side
   * @param {Object} error - Error data
   */
  handleError(error) {
    console.error('Error from app-side:', error.message);
    this.widgets.bgValue.setProperty(hmUI.prop.TEXT, 'Error');
    this.widgets.bgValue.setProperty(hmUI.prop.COLOR, 0xff0000);
  },

  /**
   * Build the user interface
   */
  buildUI() {
    // Title
    const title = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: MARGIN,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 50,
      color: 0xffffff,
      text_size: 32,
      align_h: hmUI.align.CENTER_H,
      text: 'Nightscout'
    });

    // Settings input field (simulated with text display + button)
    const settingsLabel = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: 80,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 30,
      color: 0xaaaaaa,
      text_size: 20,
      text: 'API URL:'
    });

    const settingsValue = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: 110,
      w: SCREEN_WIDTH - (MARGIN * 2) - 100,
      h: 40,
      color: 0x00ff00,
      text_size: 16,
      text: this.state.apiUrl
    });

    this.widgets = { settingsValue };

    // Verify URL button
    const verifyButton = hmUI.createWidget(hmUI.widget.BUTTON, {
      x: SCREEN_WIDTH - MARGIN - 90,
      y: 105,
      w: 90,
      h: 30,
      text: 'Verify',
      normal_color: 0x666666,
      press_color: 0x444444,
      radius: 15,
      text_size: 16,
      click_func: () => {
        this.verifyUrl();
      }
    });

    // Verification status text
    const verificationStatus = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: 150,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 25,
      color: 0x888888,
      text_size: 14,
      text: this.state.verificationStatus
    });

    this.widgets.verificationStatus = verificationStatus;

    // Current BG value (large display)
    const bgValue = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: 190,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 80,
      color: 0x00ff00,
      text_size: 72,
      align_h: hmUI.align.CENTER_H,
      text: this.state.currentBG
    });

    this.widgets.bgValue = bgValue;

    // Trend and Delta
    const trendText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: 280,
      w: (SCREEN_WIDTH - (MARGIN * 2)) / 2,
      h: 30,
      color: 0xffffff,
      text_size: 24,
      align_h: hmUI.align.CENTER_H,
      text: `Trend: ${this.state.trend}`
    });

    const deltaText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: SCREEN_WIDTH / 2,
      y: 280,
      w: (SCREEN_WIDTH - (MARGIN * 2)) / 2,
      h: 30,
      color: 0xffffff,
      text_size: 24,
      align_h: hmUI.align.CENTER_H,
      text: `Δ: ${this.state.delta}`
    });

    this.widgets.trendText = trendText;
    this.widgets.deltaText = deltaText;

    // Last update time
    const lastUpdateText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: 320,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 25,
      color: 0x888888,
      text_size: 18,
      align_h: hmUI.align.CENTER_H,
      text: `Last: ${this.state.lastUpdate}`
    });

    this.widgets.lastUpdateText = lastUpdateText;

    // Graph canvas
    const canvas = hmUI.createWidget(hmUI.widget.CANVAS, {
      x: MARGIN,
      y: 360,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 80
    });

    this.widgets.canvas = canvas;
    this.drawGraph();

    // Fetch data button
    const fetchButton = hmUI.createWidget(hmUI.widget.BUTTON, {
      x: SCREEN_WIDTH / 2 - 60,
      y: 450,
      w: 120,
      h: 40,
      text: 'Fetch Data',
      normal_color: 0x0000ff,
      press_color: 0x000088,
      radius: 20,
      click_func: () => {
        this.fetchData();
      }
    });
  },

  /**
   * Draw the glucose graph
   */
  drawGraph() {
    if (!this.widgets.canvas) return;

    const canvas = this.widgets.canvas;
    const width = SCREEN_WIDTH - (MARGIN * 2);
    const height = 80;

    // Clear canvas
    canvas.clear();

    // Draw background
    canvas.setStrokeStyle(0x333333);
    canvas.setLineWidth(1);
    canvas.strokeRect(0, 0, width, height);

    // Draw sample data (will be replaced with actual data)
    if (this.state.dataPoints.length > 0) {
      canvas.setStrokeStyle(0x00ff00);
      canvas.setLineWidth(2);

      const pointCount = this.state.dataPoints.length;
      const xStep = width / (pointCount - 1);

      // Scale data to fit in canvas
      const maxBG = Math.max(...this.state.dataPoints);
      const minBG = Math.min(...this.state.dataPoints);
      const range = maxBG - minBG || 100;

      for (let i = 0; i < pointCount - 1; i++) {
        const x1 = i * xStep;
        const y1 = height - ((this.state.dataPoints[i] - minBG) / range) * height;
        const x2 = (i + 1) * xStep;
        const y2 = height - ((this.state.dataPoints[i + 1] - minBG) / range) * height;

        canvas.beginPath();
        canvas.moveTo(x1, y1);
        canvas.lineTo(x2, y2);
        canvas.stroke();
      }
    } else {
      // Draw placeholder text
      canvas.setFillStyle(0x888888);
      canvas.fillText('No data', width / 2 - 30, height / 2);
    }
  },

  /**
   * Fetch data from Nightscout API
   */
  fetchData() {
    console.log('Fetching data from Nightscout...');
    
    // Show loading state
    this.widgets.bgValue.setProperty(hmUI.prop.TEXT, 'Loading...');
    
    // Send message to app-side to fetch data
    try {
      const message = messageBuilder.request({
        type: MESSAGE_TYPES.FETCH_DATA,
        apiUrl: this.state.apiUrl
      });
      messaging.peerSocket.send(message);
    } catch (error) {
      console.error('Error sending fetch request:', error);
      this.widgets.bgValue.setProperty(hmUI.prop.TEXT, 'Error');
    }
  },

  /**
   * Verify Nightscout URL
   */
  verifyUrl() {
    console.log('Verifying Nightscout URL...');
    
    // Show verification in progress
    this.state.verificationStatus = 'Verifying...';
    this.widgets.verificationStatus.setProperty(hmUI.prop.TEXT, this.state.verificationStatus);
    this.widgets.verificationStatus.setProperty(hmUI.prop.COLOR, 0x888888);
    
    // Send message to app-side to verify URL
    try {
      const message = messageBuilder.request({
        type: MESSAGE_TYPES.VERIFY_URL,
        apiUrl: this.state.apiUrl
      });
      messaging.peerSocket.send(message);
    } catch (error) {
      console.error('Error sending verification request:', error);
      this.state.verificationStatus = '✗ Verification failed';
      this.widgets.verificationStatus.setProperty(hmUI.prop.TEXT, this.state.verificationStatus);
      this.widgets.verificationStatus.setProperty(hmUI.prop.COLOR, 0xff0000);
    }
  },
});
