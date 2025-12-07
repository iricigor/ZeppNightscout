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
    tokenValidationStatus: 'unvalidated', // unvalidated, validating, valid-readonly, valid-admin, invalid
    currentPage: 0, // 0 = Main (BG/trend/delta), 1 = Graph, 2 = Settings
    graphZoom: 1.0, // Zoom level for graph page
    graphOffset: 0 // Pan offset for graph page
  },

  onInit() {
    console.log('Nightscout app initialized');
    this.setupMessageHandlers();
    this.setupGestureHandlers();
    this.buildUI();
  },

  /**
   * Setup gesture handlers for page navigation
   */
  setupGestureHandlers() {
    // Create page navigation touch areas using BUTTON widgets
    // Left side - swipe right / previous page
    const leftNavArea = hmUI.createWidget(hmUI.widget.BUTTON, {
      x: 0,
      y: 60,
      w: 80,
      h: SCREEN_HEIGHT - 120,
      text: '',
      normal_color: 0x000000,
      press_color: 0x111111,
      radius: 0,
      text_size: 1,
      color: 0x000000,
      click_func: () => {
        this.navigatePage(-1);
      }
    });

    // Right side - swipe left / next page
    const rightNavArea = hmUI.createWidget(hmUI.widget.BUTTON, {
      x: SCREEN_WIDTH - 80,
      y: 60,
      w: 80,
      h: SCREEN_HEIGHT - 120,
      text: '',
      normal_color: 0x000000,
      press_color: 0x111111,
      radius: 0,
      text_size: 1,
      color: 0x000000,
      click_func: () => {
        this.navigatePage(1);
      }
    });
  },

  /**
   * Navigate to a different page
   * @param {number} direction - -1 for previous, 1 for next
   */
  navigatePage(direction) {
    const newPage = this.state.currentPage + direction;
    if (newPage >= 0 && newPage <= 2) {
      this.state.currentPage = newPage;
      this.refreshUI();
    }
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

    // Update UI widgets if they exist
    if (this.widgets.bgValue) {
      this.widgets.bgValue.setProperty(hmUI.prop.TEXT, this.state.currentBG);
      this.widgets.bgValue.setProperty(hmUI.prop.COLOR, 0x00ff00);
    }
    if (this.widgets.trendText) {
      this.widgets.trendText.setProperty(hmUI.prop.TEXT, this.state.trend);
    }
    if (this.widgets.deltaText) {
      this.widgets.deltaText.setProperty(hmUI.prop.TEXT, this.state.delta);
    }
    if (this.widgets.lastUpdateText) {
      this.widgets.lastUpdateText.setProperty(hmUI.prop.TEXT, `Last: ${this.state.lastUpdate}`);
    }

    // Redraw graph if canvas exists
    if (this.widgets.canvas) {
      this.drawGraph();
    }
  },

  /**
   * Handle error from app-side
   * @param {Object} error - Error data
   */
  handleError(error) {
    console.error('Error from app-side:', error.message);
    if (this.widgets.bgValue) {
      this.widgets.bgValue.setProperty(hmUI.prop.TEXT, 'Error');
      this.widgets.bgValue.setProperty(hmUI.prop.COLOR, 0xff0000);
    }
  },

  /**
   * Build the user interface
   */
  buildUI() {
    this.widgets = {};
    this.refreshUI();
  },

  /**
   * Refresh the UI to show the current page
   */
  refreshUI() {
    // Clear all existing widgets except the base layer
    hmUI.deleteWidget(hmUI.widget.GROUP);
    
    // Render current page
    switch (this.state.currentPage) {
      case 0:
        this.buildPage1_MainMetrics();
        break;
      case 1:
        this.buildPage2_Graph();
        break;
      case 2:
        this.buildPage3_Settings();
        break;
    }

    // Add page indicator at the bottom
    this.buildPageIndicator();
  },

  /**
   * Build Page 1: Main Metrics (BG, Trend, Delta)
   */
  buildPage1_MainMetrics() {
    let yPos = MARGIN;

    // Title
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 50,
      color: 0xffffff,
      text_size: 32,
      align_h: hmUI.align.CENTER_H,
      text: 'Nightscout'
    });
    yPos += 80;

    // Page navigation arrows
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: 50,
      h: 30,
      color: 0x444444,
      text_size: 24,
      text: ''
    });

    hmUI.createWidget(hmUI.widget.TEXT, {
      x: SCREEN_WIDTH - MARGIN - 50,
      y: yPos,
      w: 50,
      h: 30,
      color: 0x888888,
      text_size: 24,
      text: '→'
    });
    yPos += 10;

    // Current BG value (large display)
    const bgValue = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 120,
      color: 0x00ff00,
      text_size: 96,
      align_h: hmUI.align.CENTER_H,
      align_v: hmUI.align.CENTER_V,
      text: this.state.currentBG
    });
    this.widgets.bgValue = bgValue;
    yPos += 140;

    // Trend and Delta side by side
    const trendText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: (SCREEN_WIDTH - (MARGIN * 2)) / 2,
      h: 50,
      color: 0xffffff,
      text_size: 36,
      align_h: hmUI.align.CENTER_H,
      text: this.state.trend
    });
    this.widgets.trendText = trendText;

    const deltaText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: SCREEN_WIDTH / 2,
      y: yPos,
      w: (SCREEN_WIDTH - (MARGIN * 2)) / 2,
      h: 50,
      color: 0xffffff,
      text_size: 36,
      align_h: hmUI.align.CENTER_H,
      text: this.state.delta
    });
    this.widgets.deltaText = deltaText;
    yPos += 70;

    // Last update time
    const lastUpdateText = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 30,
      color: 0x888888,
      text_size: 20,
      align_h: hmUI.align.CENTER_H,
      text: `Last: ${this.state.lastUpdate}`
    });
    this.widgets.lastUpdateText = lastUpdateText;
    yPos += 50;

    // Fetch data button
    hmUI.createWidget(hmUI.widget.BUTTON, {
      x: SCREEN_WIDTH / 2 - 80,
      y: yPos,
      w: 160,
      h: 50,
      text: 'Fetch Data',
      normal_color: 0x0000ff,
      press_color: 0x000088,
      radius: 25,
      click_func: () => {
        this.fetchData();
      }
    });

    // Swipe instruction
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: SCREEN_HEIGHT - 60,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 30,
      color: 0x666666,
      text_size: 16,
      align_h: hmUI.align.CENTER_H,
      text: 'Tap edges to navigate'
    });
  },

  /**
   * Build Page 2: Graph (Scrollable to zoom/pan)
   */
  buildPage2_Graph() {
    let yPos = MARGIN;

    // Title
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 40,
      color: 0xffffff,
      text_size: 28,
      align_h: hmUI.align.CENTER_H,
      text: 'Glucose Graph'
    });
    yPos += 50;

    // Page navigation arrows
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: 50,
      h: 30,
      color: 0x888888,
      text_size: 24,
      text: '←'
    });

    hmUI.createWidget(hmUI.widget.TEXT, {
      x: SCREEN_WIDTH - MARGIN - 50,
      y: yPos,
      w: 50,
      h: 30,
      color: 0x888888,
      text_size: 24,
      text: '→'
    });
    yPos += 10;

    // Current BG (smaller display)
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 50,
      color: 0x00ff00,
      text_size: 40,
      align_h: hmUI.align.CENTER_H,
      text: `${this.state.currentBG} ${this.state.trend}`
    });
    yPos += 60;

    // Graph canvas - larger for this page
    const canvas = hmUI.createWidget(hmUI.widget.CANVAS, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 200
    });
    this.widgets.canvas = canvas;
    this.drawGraph();
    yPos += 220;

    // Zoom controls
    const zoomLabel = hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: 100,
      h: 30,
      color: 0xaaaaaa,
      text_size: 18,
      text: `Zoom: ${this.state.graphZoom.toFixed(1)}x`
    });
    this.widgets.zoomLabel = zoomLabel;

    // Zoom In button
    hmUI.createWidget(hmUI.widget.BUTTON, {
      x: SCREEN_WIDTH - MARGIN - 180,
      y: yPos - 5,
      w: 80,
      h: 40,
      text: 'Zoom +',
      normal_color: 0x444444,
      press_color: 0x222222,
      radius: 20,
      text_size: 16,
      click_func: () => {
        this.state.graphZoom = Math.min(3.0, this.state.graphZoom + 0.5);
        this.widgets.zoomLabel.setProperty(hmUI.prop.TEXT, `Zoom: ${this.state.graphZoom.toFixed(1)}x`);
        this.drawGraph();
      }
    });

    // Zoom Out button
    hmUI.createWidget(hmUI.widget.BUTTON, {
      x: SCREEN_WIDTH - MARGIN - 90,
      y: yPos - 5,
      w: 80,
      h: 40,
      text: 'Zoom -',
      normal_color: 0x444444,
      press_color: 0x222222,
      radius: 20,
      text_size: 16,
      click_func: () => {
        this.state.graphZoom = Math.max(0.5, this.state.graphZoom - 0.5);
        this.widgets.zoomLabel.setProperty(hmUI.prop.TEXT, `Zoom: ${this.state.graphZoom.toFixed(1)}x`);
        this.drawGraph();
      }
    });

    // Swipe instruction
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: SCREEN_HEIGHT - 60,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 30,
      color: 0x666666,
      text_size: 16,
      align_h: hmUI.align.CENTER_H,
      text: 'Tap edges to navigate'
    });
  },

  /**
   * Build Page 3: Settings/History
   */
  buildPage3_Settings() {
    let yPos = MARGIN;

    // Title
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 40,
      color: 0xffffff,
      text_size: 28,
      align_h: hmUI.align.CENTER_H,
      text: 'Settings'
    });
    yPos += 50;

    // Page navigation arrows
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: 50,
      h: 30,
      color: 0x888888,
      text_size: 24,
      text: '←'
    });

    hmUI.createWidget(hmUI.widget.TEXT, {
      x: SCREEN_WIDTH - MARGIN - 50,
      y: yPos,
      w: 50,
      h: 30,
      color: 0x444444,
      text_size: 24,
      text: ''
    });
    yPos += 10;

    // URL section
    hmUI.createWidget(hmUI.widget.TEXT, {
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
    this.widgets.urlValue = urlValue;

    // Verify URL button
    hmUI.createWidget(hmUI.widget.BUTTON, {
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

    // URL Verification status
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

    // Token section
    hmUI.createWidget(hmUI.widget.TEXT, {
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

    // Token validation icon
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

    // Token validate button (invisible overlay)
    hmUI.createWidget(hmUI.widget.BUTTON, {
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

    // Token validation status
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

    // History section
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 25,
      color: 0xaaaaaa,
      text_size: 18,
      text: 'History:'
    });
    yPos += 30;

    // Show data point count
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: yPos,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 25,
      color: 0xffffff,
      text_size: 16,
      text: `Data points: ${this.state.dataPoints.length}`
    });

    // Swipe instruction
    hmUI.createWidget(hmUI.widget.TEXT, {
      x: MARGIN,
      y: SCREEN_HEIGHT - 60,
      w: SCREEN_WIDTH - (MARGIN * 2),
      h: 30,
      color: 0x666666,
      text_size: 16,
      align_h: hmUI.align.CENTER_H,
      text: 'Tap edges to navigate'
    });
  },

  /**
   * Build page indicator (dots at bottom)
   */
  buildPageIndicator() {
    const indicatorY = SCREEN_HEIGHT - 30;
    const dotSize = 10;
    const dotSpacing = 25;
    const startX = SCREEN_WIDTH / 2 - dotSpacing;

    for (let i = 0; i < 3; i++) {
      const isActive = i === this.state.currentPage;
      hmUI.createWidget(hmUI.widget.CIRCLE, {
        center_x: startX + i * dotSpacing,
        center_y: indicatorY,
        radius: isActive ? 6 : 4,
        color: isActive ? 0xffffff : 0x444444,
        alpha: isActive ? 255 : 128
      });
    }
  },

  /**
   * Draw the glucose graph
   */
  drawGraph() {
    if (!this.widgets.canvas) return;

    const canvas = this.widgets.canvas;
    // Get canvas dimensions - Page 2 has larger graph (200px) vs Page 1's legacy small graph
    const width = SCREEN_WIDTH - (MARGIN * 2);
    const height = this.state.currentPage === 1 ? 200 : 80;

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

      // Apply zoom - show fewer points when zoomed in
      const zoom = this.state.graphZoom || 1.0;
      const totalPoints = this.state.dataPoints.length;
      const visiblePoints = Math.ceil(totalPoints / zoom);
      const startIdx = Math.max(0, totalPoints - visiblePoints);
      const visibleData = this.state.dataPoints.slice(startIdx);

      const pointCount = visibleData.length;
      const xStep = width / (pointCount - 1);

      // Scale data to fit in canvas
      const maxBG = Math.max(...visibleData);
      const minBG = Math.min(...visibleData);
      const range = maxBG - minBG || 100;

      for (let i = 0; i < pointCount - 1; i++) {
        const x1 = i * xStep;
        const y1 = height - ((visibleData[i] - minBG) / range) * height;
        const x2 = (i + 1) * xStep;
        const y2 = height - ((visibleData[i + 1] - minBG) / range) * height;

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
