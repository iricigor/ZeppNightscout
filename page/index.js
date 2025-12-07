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
    apiToken: '',
    currentBG: '--',
    trend: '--',
    delta: '--',
    lastUpdate: '--',
    dataPoints: [],
    verificationStatus: '',
    tokenValidationStatus: 'unvalidated' // unvalidated, validating, valid-readonly, valid-admin, invalid
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
        } else if (data.data.tokenValidation) {
          // Handle token validation result
          this.handleTokenValidationResult(data.data);
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
   * Handle token validation result from app-side
   * @param {Object} result - Token validation result
   */
  handleTokenValidationResult(result) {
    if (result.validating) {
      this.state.tokenValidationStatus = 'validating';
      this.widgets.tokenValidationIcon.setProperty(hmUI.prop.TEXT, '⌛');
      this.widgets.tokenValidationIcon.setProperty(hmUI.prop.COLOR, 0x888888);
      this.widgets.tokenValidationStatus.setProperty(hmUI.prop.TEXT, 'Validating token...');
      this.widgets.tokenValidationStatus.setProperty(hmUI.prop.COLOR, 0x888888);
      return;
    }

    if (!result.statusSuccess) {
      // Token is invalid - cannot read status
      this.state.tokenValidationStatus = 'invalid';
      this.widgets.tokenValidationIcon.setProperty(hmUI.prop.TEXT, '✗');
      this.widgets.tokenValidationIcon.setProperty(hmUI.prop.COLOR, 0xff0000);
      this.widgets.tokenValidationStatus.setProperty(hmUI.prop.TEXT, result.statusError || '✗ Invalid token');
      this.widgets.tokenValidationStatus.setProperty(hmUI.prop.COLOR, 0xff0000);
    } else if (result.adminSuccess) {
      // Token has admin access - this is dangerous!
      this.state.tokenValidationStatus = 'valid-admin';
      this.widgets.tokenValidationIcon.setProperty(hmUI.prop.TEXT, '❗');
      this.widgets.tokenValidationIcon.setProperty(hmUI.prop.COLOR, 0xff0000);
      this.widgets.tokenValidationStatus.setProperty(hmUI.prop.TEXT, '❗ Token has admin access!');
      this.widgets.tokenValidationStatus.setProperty(hmUI.prop.COLOR, 0xff0000);
    } else {
      // Token is read-only - this is the expected safe state
      this.state.tokenValidationStatus = 'valid-readonly';
      this.widgets.tokenValidationIcon.setProperty(hmUI.prop.TEXT, '✅');
      this.widgets.tokenValidationIcon.setProperty(hmUI.prop.COLOR, 0x00ff00);
      this.widgets.tokenValidationStatus.setProperty(hmUI.prop.TEXT, '✅ Token is read-only');
      this.widgets.tokenValidationStatus.setProperty(hmUI.prop.COLOR, 0x00ff00);
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
    let yPos = MARGIN; // Track vertical position
    
    // Title
    const title = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 50,
      color: 0xffffff,
      text_size: 32,
      align_h: hmUI.align.CENTER_H,
      text: 'Nightscout'
    });
    yPos += 60;

    // URL input field (simulated with text display + button)
    const urlLabel = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 25,
      color: 0xaaaaaa,
      text_size: 18,
      text: 'API URL:'
    });
    yPos += 30;

    const urlValue = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2) - 100,
      h: 35,
      color: 0x00ff00,
      text_size: 16,
      text: this.state.apiUrl
    });

    this.widgets = { urlValue };

    // Verify URL button
    const verifyButton = hmUI.createWidget(hmUI.widget.BUTTON, {
      x: SCREEN_WIDTH - MARGIN - 90,
      y: yPos - 5,
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
    yPos += 40;

    // URL Verification status text
    const verificationStatus = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 20,
      color: 0x888888,
      text_size: 14,
      text: this.state.verificationStatus
    });

    this.widgets.verificationStatus = verificationStatus;
    yPos += 30;

    // API Token input field
    const tokenLabel = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 25,
      color: 0xaaaaaa,
      text_size: 18,
      text: 'API Token (read-only):'
    });
    yPos += 30;

    const tokenValue = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2) - 80,
      h: 35,
      color: 0x00ff00,
      text_size: 16,
      text: this.state.apiToken || '(not set)'
    });

    this.widgets.tokenValue = tokenValue;

    // Token validation icon (clickable)
    const tokenValidationIcon = hmUI.createWidget(hmUI.widget.TEXT, {
      x: SCREEN_WIDTH - MARGIN - 70,
      y: yPos,
      w: 35,
      h: 35,
      color: 0x888888,
      text_size: 28,
      align_h: hmUI.align.CENTER_H,
      text: '?'
    });

    this.widgets.tokenValidationIcon = tokenValidationIcon;

    // Make the icon clickable
    const tokenValidateButton = hmUI.createWidget(hmUI.widget.BUTTON, {
      x: SCREEN_WIDTH - MARGIN - 75,
      y: yPos - 5,
      w: 45,
      h: 40,
      text: '',
      normal_color: 0x000000,
      press_color: 0x222222,
      radius: 20,
      text_size: 1,
      click_func: () => {
        this.validateToken();
      }
    });
    yPos += 40;

    // Token validation status text
    const tokenValidationStatus = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 20,
      color: 0x888888,
      text_size: 14,
      text: ''
    });

    this.widgets.tokenValidationStatus = tokenValidationStatus;
    yPos += 30;

    // Current BG value (large display)
    const bgValue = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 80,
      color: 0x00ff00,
      text_size: 72,
      align_h: hmUI.align.CENTER_H,
      text: this.state.currentBG
    });

    this.widgets.bgValue = bgValue;
    yPos += 90;

    // Trend and Delta
    const trendText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: (SCREEN_WIDTH - (MARGIN * 2)) / 2,
      h: 30,
      color: 0xffffff,
      text_size: 24,
      align_h: hmUI.align.CENTER_H,
      text: `Trend: ${this.state.trend}`
    });

    const deltaText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: SCREEN_WIDTH / 2,
      y: yPos,
      w: (SCREEN_WIDTH - (MARGIN * 2)) / 2,
      h: 30,
      color: 0xffffff,
      text_size: 24,
      align_h: hmUI.align.CENTER_H,
      text: `Δ: ${this.state.delta}`
    });

    this.widgets.trendText = trendText;
    this.widgets.deltaText = deltaText;
    yPos += 40;

    // Last update time
    const lastUpdateText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 25,
      color: 0x888888,
      text_size: 18,
      align_h: hmUI.align.CENTER_H,
      text: `Last: ${this.state.lastUpdate}`
    });

    this.widgets.lastUpdateText = lastUpdateText;
    yPos += 30;

    // Graph canvas
    const canvas = hmUI.createWidget(hmUI.widget.CANVAS, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 80
    });

    this.widgets.canvas = canvas;
    this.drawGraph();
    yPos += 90;

    // Fetch data button
    const fetchButton = hmUI.createWidget(hmUI.widget.BUTTON, {
      x: SCREEN_WIDTH / 2 - 60,
      y: yPos,
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
        apiUrl: this.state.apiUrl,
        apiToken: this.state.apiToken
      });
      messaging.peerSocket.send(message);
    } catch (error) {
      console.error('Error sending fetch request:', error);
      this.widgets.bgValue.setProperty(hmUI.prop.TEXT, 'Error');
    }
  },

  /**
   * Verify Nightscout URL format
   */
  verifyUrl() {
    console.log('Verifying Nightscout URL...');
    
    const url = this.state.apiUrl.trim();
    
    // Check if URL is HTTPS
    if (!url.startsWith('https://')) {
      this.state.verificationStatus = '✗ URL must use HTTPS';
      this.widgets.verificationStatus.setProperty(hmUI.prop.TEXT, this.state.verificationStatus);
      this.widgets.verificationStatus.setProperty(hmUI.prop.COLOR, 0xff0000);
      return;
    }
    
    // Show verification in progress
    this.state.verificationStatus = 'Verifying...';
    this.widgets.verificationStatus.setProperty(hmUI.prop.TEXT, this.state.verificationStatus);
    this.widgets.verificationStatus.setProperty(hmUI.prop.COLOR, 0x888888);
    
    // Send message to app-side to verify URL
    try {
      const message = messageBuilder.request({
        type: MESSAGE_TYPES.VERIFY_URL,
        apiUrl: url,
        apiToken: this.state.apiToken
      });
      messaging.peerSocket.send(message);
    } catch (error) {
      console.error('Error sending verification request:', error);
      this.state.verificationStatus = '✗ Verification failed';
      this.widgets.verificationStatus.setProperty(hmUI.prop.TEXT, this.state.verificationStatus);
      this.widgets.verificationStatus.setProperty(hmUI.prop.COLOR, 0xff0000);
    }
  },

  /**
   * Validate API token
   */
  validateToken() {
    console.log('Validating API token...');
    
    const url = this.state.apiUrl.trim();
    const token = this.state.apiToken.trim();
    
    if (!token) {
      this.state.tokenValidationStatus = 'invalid';
      this.widgets.tokenValidationIcon.setProperty(hmUI.prop.TEXT, '✗');
      this.widgets.tokenValidationIcon.setProperty(hmUI.prop.COLOR, 0xff0000);
      this.widgets.tokenValidationStatus.setProperty(hmUI.prop.TEXT, '✗ No token provided');
      this.widgets.tokenValidationStatus.setProperty(hmUI.prop.COLOR, 0xff0000);
      return;
    }
    
    // Show validation in progress
    this.state.tokenValidationStatus = 'validating';
    this.widgets.tokenValidationIcon.setProperty(hmUI.prop.TEXT, '⌛');
    this.widgets.tokenValidationIcon.setProperty(hmUI.prop.COLOR, 0x888888);
    this.widgets.tokenValidationStatus.setProperty(hmUI.prop.TEXT, 'Validating...');
    this.widgets.tokenValidationStatus.setProperty(hmUI.prop.COLOR, 0x888888);
    
    // Send message to app-side to validate token
    try {
      const message = messageBuilder.request({
        type: MESSAGE_TYPES.VALIDATE_TOKEN,
        apiUrl: url,
        apiToken: token
      });
      messaging.peerSocket.send(message);
    } catch (error) {
      console.error('Error sending token validation request:', error);
      this.state.tokenValidationStatus = 'invalid';
      this.widgets.tokenValidationIcon.setProperty(hmUI.prop.TEXT, '✗');
      this.widgets.tokenValidationIcon.setProperty(hmUI.prop.COLOR, 0xff0000);
      this.widgets.tokenValidationStatus.setProperty(hmUI.prop.TEXT, '✗ Validation failed');
      this.widgets.tokenValidationStatus.setProperty(hmUI.prop.COLOR, 0xff0000);
    }
  },
});
