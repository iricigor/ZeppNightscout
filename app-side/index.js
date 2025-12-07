/**
 * Nightscout Zepp OS App - App-Side Service
 * Handles API calls to Nightscout server
 */

import { messageBuilder, MESSAGE_TYPES } from '../shared/message';

// App-side service
AppSideService({
  onInit() {
    console.log('App-side service initialized');
    this.setupMessageHandlers();
  },

  onRun() {
    console.log('App-side service running');
  },

  onDestroy() {
    console.log('App-side service destroyed');
  },

  /**
   * Setup message handlers for communication with device
   */
  setupMessageHandlers() {
    // Listen for messages from device
    messaging.peerSocket.addListener('message', (data) => {
      console.log('Received message:', data);
      
      if (data.type === MESSAGE_TYPES.FETCH_DATA) {
        this.fetchNightscoutData(data.apiUrl);
      } else if (data.type === MESSAGE_TYPES.UPDATE_SETTINGS) {
        this.updateSettings(data.settings);
      } else if (data.type === MESSAGE_TYPES.VERIFY_URL) {
        this.verifyNightscoutUrl(data.apiUrl);
      }
    });
  },

  /**
   * Fetch data from Nightscout API
   * @param {string} apiUrl - The Nightscout API URL
   */
  fetchNightscoutData(apiUrl) {
    console.log('Fetching from Nightscout:', apiUrl);

    const url = apiUrl || 'https://your-nightscout.herokuapp.com';
    // Request 200 entries for pixel-per-value display (~200px screen width)
    const endpoint = `${url}/api/v1/entries.json?count=200`;

    // Use Zepp OS fetch API
    this.request({
      method: 'GET',
      url: endpoint,
      headers: {
        'Content-Type': 'application/json'
      }
    })
    .then(response => {
      console.log('API response received');
      const data = response.body;
      
      if (Array.isArray(data) && data.length > 0) {
        const parsedData = this.parseNightscoutData(data);
        this.sendDataToDevice(parsedData);
      } else {
        this.sendErrorToDevice('No data received');
      }
    })
    .catch(error => {
      console.error('Fetch error:', error);
      this.sendErrorToDevice(error.message);
    });
  },

  /**
   * Verify Nightscout URL by checking the status endpoint
   * @param {string} apiUrl - The Nightscout API URL
   */
  verifyNightscoutUrl(apiUrl) {
    console.log('Verifying Nightscout URL:', apiUrl);

    const url = apiUrl || 'https://your-nightscout.herokuapp.com';
    // Use /api/v1/status endpoint for verification (doesn't transfer CGM data)
    const endpoint = `${url}/api/v1/status`;

    this.request({
      method: 'GET',
      url: endpoint,
      headers: {
        'Content-Type': 'application/json'
      }
    })
    .then(response => {
      console.log('Verification response received');
      const data = response.body;
      
      // Check if the response contains expected Nightscout status fields
      if (data && (data.status || data.name || data.version)) {
        this.sendVerificationResultToDevice({
          success: true,
          message: '✓ URL verified',
          serverInfo: {
            name: data.name || 'Nightscout',
            version: data.version || 'unknown'
          }
        });
      } else {
        this.sendVerificationResultToDevice({
          success: false,
          message: '✗ Invalid response'
        });
      }
    })
    .catch(error => {
      console.error('Verification error:', error);
      this.sendVerificationResultToDevice({
        success: false,
        message: '✗ Connection failed'
      });
    });
  },

  /**
   * Parse Nightscout API response
   * @param {Array} entries - Array of glucose entries
   * @returns {Object} Parsed data
   */
  parseNightscoutData(entries) {
    if (!entries || entries.length === 0) {
      return null;
    }

    // Get the most recent entry
    const latest = entries[0];
    const previous = entries[1];

    // Calculate delta
    let delta = 0;
    let deltaDisplay = '--';
    if (previous && latest.sgv && previous.sgv) {
      delta = latest.sgv - previous.sgv;
      deltaDisplay = (delta >= 0 ? '+' : '') + delta;
    }

    // Determine trend arrow
    const trendMap = {
      'DoubleUp': '⇈',
      'SingleUp': '↑',
      'FortyFiveUp': '↗',
      'Flat': '→',
      'FortyFiveDown': '↘',
      'SingleDown': '↓',
      'DoubleDown': '⇊',
      'NOT COMPUTABLE': '-',
      'RATE OUT OF RANGE': '⇕'
    };
    const trend = trendMap[latest.direction] || '?';

    // Get data points for graph
    const dataPoints = entries.map(entry => entry.sgv || 0);

    // Calculate time since last update
    const lastUpdate = this.formatTimeSince(latest.dateString || latest.date);

    return {
      currentBG: latest.sgv ? latest.sgv.toString() : '--',
      trend: trend,
      delta: deltaDisplay,
      lastUpdate: lastUpdate,
      dataPoints: dataPoints.reverse(), // Reverse to show oldest to newest
      rawData: latest
    };
  },

  /**
   * Format time since last update
   * @param {string|number} timestamp - Timestamp string or unix time
   * @returns {string} Formatted time string
   */
  formatTimeSince(timestamp) {
    try {
      const date = new Date(timestamp);
      const now = new Date();
      const diffMs = now - date;
      const diffMin = Math.floor(diffMs / 60000);

      if (diffMin < 1) return 'Just now';
      if (diffMin === 1) return '1 min ago';
      if (diffMin < 60) return `${diffMin} min ago`;
      
      const diffHour = Math.floor(diffMin / 60);
      if (diffHour === 1) return '1 hour ago';
      return `${diffHour} hours ago`;
    } catch (error) {
      console.error('Error formatting time:', error);
      return 'Unknown';
    }
  },

  /**
   * Send parsed data to device
   * @param {Object} data - Parsed glucose data
   */
  sendDataToDevice(data) {
    const message = messageBuilder.response(data);
    messaging.peerSocket.send(message);
  },

  /**
   * Send verification result to device
   * @param {Object} result - Verification result
   */
  sendVerificationResultToDevice(result) {
    const message = messageBuilder.response({
      verification: true,
      ...result
    });
    messaging.peerSocket.send(message);
  },

  /**
   * Send error message to device
   * @param {string} errorMessage - Error message
   */
  sendErrorToDevice(errorMessage) {
    const message = messageBuilder.response({
      error: true,
      message: errorMessage
    });
    messaging.peerSocket.send(message);
  },

  /**
   * Update settings
   * @param {Object} settings - New settings
   */
  updateSettings(settings) {
    console.log('Updating settings:', settings);
    // Store settings (would use Zepp OS storage API in production)
    this.settings = settings;
  },

  /**
   * HTTP request wrapper
   * @param {Object} options - Request options
   * @returns {Promise} Promise that resolves with response
   */
  request(options) {
    return new Promise((resolve, reject) => {
      // Simulated fetch for now - in real implementation, use Zepp OS fetch API
      // Example: const response = hmFetch.httpRequest(options);
      
      // For demonstration, return dummy data
      setTimeout(() => {
        // Check if this is a status endpoint verification
        if (options.url.includes('/api/v1/status')) {
          resolve({
            body: {
              status: 'ok',
              name: 'Nightscout',
              version: '14.2.6',
              serverTime: new Date().toISOString(),
              apiEnabled: true
            }
          });
        } else {
          // Generate 200 dummy glucose entries for data fetch
          const entries = [];
          let timestamp = Date.now();
          let value = 120;
          
          for (let i = 0; i < 200; i++) {
            // Vary the glucose value slightly
            value += (Math.random() - 0.5) * 10;
            value = Math.max(70, Math.min(200, value));
            
            entries.push({
              sgv: Math.round(value),
              direction: 'Flat',
              dateString: new Date(timestamp).toISOString(),
              date: timestamp
            });
            
            // Go back 5 minutes per entry
            timestamp -= 300000;
          }
          
          resolve({
            body: entries
          });
        }
      }, 500);
    });
  }
});
