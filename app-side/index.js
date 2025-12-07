/**
 * Nightscout Zepp OS App - App-Side Service
 * Handles API calls to Nightscout server
 */

import { messageBuilder, MESSAGE_TYPES } from '../shared/message';

// API configuration
const DATA_POINTS_COUNT = 200; // Number of glucose readings to fetch
const STATUS_ENDPOINT = '/api/v1/status';
const ENTRIES_ENDPOINT = '/api/v1/entries.json';
const ADMIN_ENDPOINT = '/api/v1/treatments.json'; // Admin endpoint for testing write access

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
        this.fetchNightscoutData(data.apiUrl, data.apiToken);
      } else if (data.type === MESSAGE_TYPES.UPDATE_SETTINGS) {
        this.updateSettings(data.settings);
      } else if (data.type === MESSAGE_TYPES.VERIFY_URL) {
        this.verifyNightscoutUrl(data.apiUrl, data.apiToken);
      } else if (data.type === MESSAGE_TYPES.VALIDATE_TOKEN) {
        this.validateToken(data.apiUrl, data.apiToken);
      }
    });
  },

  /**
   * Fetch data from Nightscout API
   * @param {string} apiUrl - The Nightscout API URL
   * @param {string} apiToken - The Nightscout API token (optional)
   */
  fetchNightscoutData(apiUrl, apiToken) {
    console.log('Fetching from Nightscout:', apiUrl);

    const url = apiUrl || 'https://your-nightscout.herokuapp.com';
    // Request DATA_POINTS_COUNT entries for pixel-per-value display (~200px screen width)
    let endpoint = `${url}${ENTRIES_ENDPOINT}?count=${DATA_POINTS_COUNT}`;
    
    // Add token if provided
    if (apiToken) {
      endpoint += `&token=${apiToken}`;
    }

    // Use Zepp OS fetch API
    this.request({
      method: 'GET',
      url: endpoint,
      headers: {
        'Content-Type': 'application/json'
      },
      endpointType: 'entries'
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
   * @param {string} apiToken - The Nightscout API token (optional)
   */
  verifyNightscoutUrl(apiUrl, apiToken) {
    console.log('Verifying Nightscout URL:', apiUrl);

    const url = apiUrl || 'https://your-nightscout.herokuapp.com';
    // Use STATUS_ENDPOINT for verification (doesn't transfer CGM data)
    let endpoint = `${url}${STATUS_ENDPOINT}`;
    
    // Add token if provided
    if (apiToken) {
      endpoint += `?token=${apiToken}`;
    }

    this.request({
      method: 'GET',
      url: endpoint,
      headers: {
        'Content-Type': 'application/json'
      },
      endpointType: 'status'
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
   * Validate API token by testing read and write access
   * @param {string} apiUrl - The Nightscout API URL
   * @param {string} apiToken - The Nightscout API token
   */
  validateToken(apiUrl, apiToken) {
    console.log('Validating API token');

    const url = apiUrl || 'https://your-nightscout.herokuapp.com';
    
    // First, test read access with status endpoint
    const statusEndpoint = `${url}${STATUS_ENDPOINT}?token=${apiToken}`;

    this.request({
      method: 'GET',
      url: statusEndpoint,
      headers: {
        'Content-Type': 'application/json'
      },
      endpointType: 'status'
    })
    .then(statusResponse => {
      console.log('Token status check passed - token has read access');
      
      // Now test write access by trying to query treatments (admin endpoint)
      // We're just checking if we have access, not actually writing data
      const adminEndpoint = `${url}${ADMIN_ENDPOINT}?count=1&token=${apiToken}`;
      
      return this.request({
        method: 'GET',
        url: adminEndpoint,
        headers: {
          'Content-Type': 'application/json'
        },
        endpointType: 'admin'
      })
      .then(adminResponse => {
        // If we can access admin endpoint, token has write access (not ideal)
        console.log('Token has admin access - this is not recommended!');
        this.sendTokenValidationResultToDevice({
          statusSuccess: true,
          adminSuccess: true
        });
      })
      .catch(adminError => {
        // Admin access failed - this is the expected behavior for read-only token
        console.log('Token is read-only - this is the expected safe state');
        this.sendTokenValidationResultToDevice({
          statusSuccess: true,
          adminSuccess: false
        });
      });
    })
    .catch(statusError => {
      // Status check failed - token is invalid
      console.error('Token validation failed:', statusError);
      this.sendTokenValidationResultToDevice({
        statusSuccess: false,
        statusError: '✗ Invalid token or unauthorized'
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
      dataPoints: dataPoints.slice().reverse(), // Reverse to show oldest to newest (slice to avoid mutation)
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
   * Send token validation result to device
   * @param {Object} result - Token validation result
   */
  sendTokenValidationResultToDevice(result) {
    const message = messageBuilder.response({
      tokenValidation: true,
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
        // Check endpoint type using the explicit parameter instead of string matching
        if (options.endpointType === 'status') {
          resolve({
            body: {
              status: 'ok',
              name: 'Nightscout',
              version: '14.2.6',
              serverTime: new Date().toISOString(),
              apiEnabled: true
            }
          });
        } else if (options.endpointType === 'entries') {
          // Generate DATA_POINTS_COUNT dummy glucose entries for data fetch
          const entries = [];
          let timestamp = Date.now();
          let value = 120;
          
          for (let i = 0; i < DATA_POINTS_COUNT; i++) {
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
        } else if (options.endpointType === 'admin') {
          // Simulate admin endpoint access check
          // By default, reject to simulate read-only token (expected behavior)
          // In real implementation, this would be determined by actual API response
          reject(new Error('Unauthorized - read-only token'));
        } else {
          reject(new Error('Unknown endpoint type'));
        }
      }, 500);
    });
  }
});
