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
    const endpoint = `${url}/api/v1/entries.json?count=10`;

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
        resolve({
          body: [
            {
              sgv: 120,
              direction: 'Flat',
              dateString: new Date().toISOString(),
              date: Date.now()
            },
            {
              sgv: 118,
              direction: 'Flat',
              dateString: new Date(Date.now() - 300000).toISOString(),
              date: Date.now() - 300000
            }
          ]
        });
      }, 500);
    });
  }
});
