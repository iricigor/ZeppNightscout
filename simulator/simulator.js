/**
 * Zepp Nightscout Simulator
 * Browser-based simulator for quick testing
 */

// Mock data for testing
const MOCK_DATA = Array.from({ length: 200 }, (_, i) => {
  const baseValue = 120;
  const variation = Math.sin(i / 10) * 30;
  const randomNoise = (Math.random() - 0.5) * 10;
  const timestamp = Date.now() - (199 - i) * 5 * 60 * 1000; // 5 minutes apart

  // Ensure glucose values are within realistic range (40-400 mg/dL)
  const sgv = Math.max(
    40,
    Math.min(400, Math.round(baseValue + variation + randomNoise))
  );

  return {
    sgv: sgv,
    direction: i > 195 ? "Flat" : "FortyFiveUp",
    dateString: new Date(timestamp).toISOString(),
    date: timestamp,
  };
});

// Trend arrow mapping
const TREND_MAP = {
  DoubleUp: "⇈",
  SingleUp: "↑",
  FortyFiveUp: "↗",
  Flat: "→",
  FortyFiveDown: "↘",
  SingleDown: "↓",
  DoubleDown: "⇊",
  "NOT COMPUTABLE": "-",
  "RATE OUT OF RANGE": "⇕",
};

// State
let currentState = {
  apiUrl: "",
  apiToken: "",
  currentBG: "--",
  trend: "--",
  delta: "--",
  lastUpdate: "--",
  dataPoints: [],
  tokenValidationStatus: "unvalidated", // unvalidated, validating, valid-readonly, valid-admin, invalid
};

// Initialize
document.addEventListener("DOMContentLoaded", () => {
  log("Simulator ready");
  setupEventListeners();
  initializeGraph();
});

function setupEventListeners() {
  document
    .getElementById("verify-btn")
    .addEventListener("click", validateToken);
  document.getElementById("fetch-btn").addEventListener("click", fetchData);
  document.getElementById("mock-btn").addEventListener("click", loadMockData);

  // Enable/disable verify button based on input fields
  const apiUrlInput = document.getElementById("api-url");
  const apiTokenInput = document.getElementById("api-token");
  const verifyBtn = document.getElementById("verify-btn");

  function updateVerifyButtonState() {
    const hasUrl = apiUrlInput.value.trim().length > 0;
    const hasToken = apiTokenInput.value.trim().length > 0;
    verifyBtn.disabled = !(hasUrl && hasToken);

    // Reset button to initial state when inputs change
    if (!verifyBtn.disabled) {
      verifyBtn.textContent = "Verify Access";
      verifyBtn.style.backgroundColor = "";
      verifyBtn.style.color = "";
    }
  }

  apiUrlInput.addEventListener("input", updateVerifyButtonState);
  apiTokenInput.addEventListener("input", updateVerifyButtonState);
}

function log(message, type = "info") {
  const logsContainer = document.getElementById("console-logs");
  const entry = document.createElement("div");
  entry.className = `log-entry ${type}`;
  const timestamp = new Date().toLocaleTimeString();
  entry.textContent = `[${timestamp}] ${message}`;
  logsContainer.appendChild(entry);
  logsContainer.scrollTop = logsContainer.scrollHeight;

  // Also log to console
  console.log(message);
}

function showStatus(message, type = "info") {
  const container = document.getElementById("status-container");
  container.innerHTML = `<div class="status ${type}">${message}</div>`;

  // Auto-hide success messages after 5 seconds
  if (type === "success") {
    setTimeout(() => {
      container.innerHTML = "";
    }, 5000);
  }
}

async function verifyUrl() {
  const apiUrl = document.getElementById("api-url").value.trim();

  if (!apiUrl) {
    showStatus("Please enter a Nightscout URL", "error");
    log("Verification failed: No URL provided", "error");
    return;
  }

  // Check if URL is HTTPS
  if (!apiUrl.startsWith("https://")) {
    showStatus("✗ URL must use HTTPS", "error");
    log("Verification failed: URL must use HTTPS", "error");
    return;
  }

  log(`Verifying URL: ${apiUrl}`);
  showStatus("Verifying URL...", "info");

  try {
    const apiToken = document.getElementById("api-token").value.trim();
    let statusUrl = `${apiUrl}/api/v1/status`;
    if (apiToken) {
      statusUrl += `?token=${apiToken}`;
    }
    log(`Fetching: ${statusUrl}`);

    const response = await fetch(statusUrl);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const data = await response.json();
    log("URL verification successful", "success");
    showStatus("✓ URL verified successfully!", "success");

    currentState.apiUrl = apiUrl;

    log(`Server status: ${data.status || "ok"}`);
    if (data.name) log(`Server name: ${data.name}`);
    if (data.apiEnabled !== undefined) log(`API enabled: ${data.apiEnabled}`);
  } catch (error) {
    log(`Verification failed: ${error.message}`, "error");
    showStatus(`✗ Verification failed: ${error.message}`, "error");
  }
}

async function fetchData() {
  const apiUrl = document.getElementById("api-url").value.trim();

  if (!apiUrl) {
    showStatus("Please enter a Nightscout URL", "error");
    log("Fetch failed: No URL provided", "error");
    return;
  }

  log(`Fetching data from: ${apiUrl}`);
  showStatus("Fetching glucose data...", "info");

  try {
    const apiToken = document.getElementById("api-token").value.trim();
    let entriesUrl = `${apiUrl}/api/v1/entries.json?count=200`;
    if (apiToken) {
      entriesUrl += `&token=${apiToken}`;
    }
    log(`Fetching: ${entriesUrl}`);

    const response = await fetch(entriesUrl);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const entries = await response.json();

    if (!entries || entries.length === 0) {
      throw new Error("No data returned from server");
    }

    log(`Received ${entries.length} entries`, "success");
    showStatus(`✓ Loaded ${entries.length} glucose readings`, "success");

    processData(entries);
  } catch (error) {
    log(`Fetch failed: ${error.message}`, "error");
    showStatus(`✗ Fetch failed: ${error.message}`, "error");
  }
}

async function validateToken() {
  const apiUrl = document.getElementById("api-url").value.trim();
  const apiToken = document.getElementById("api-token").value.trim();

  if (!apiUrl) {
    showTokenStatus("error", "✗", "✗ Please enter API URL first");
    log("Token validation failed: No URL provided", "error");
    return;
  }

  if (!apiToken) {
    showTokenStatus("error", "✗", "✗ No token provided");
    log("Token validation failed: No token provided", "error");
    return;
  }

  log("Validating API token...");
  showTokenStatus("validating", "⌛", "Validating token...");

  try {
    // Step 1: Test read access with status endpoint
    const statusUrl = `${apiUrl}/api/v1/status?token=${apiToken}`;
    log(`Testing read access: ${statusUrl}`);

    const statusResponse = await fetch(statusUrl);

    if (!statusResponse.ok) {
      throw new Error("Token invalid or unauthorized");
    }

    log("Token has read access", "success");

    // Step 2: Test write access with admin endpoint (treatments)
    // Attempting to POST a test note entry to verify write access
    const adminUrl = `${apiUrl}/api/v1/treatments.json?token=${apiToken}`;
    log(`Testing write access: ${adminUrl}`);

    const testEntry = [
      {
        eventType: "Note",
        notes: "test-verify-only",
        duration: 0,
        created_at: new Date().toISOString(),
      },
    ];

    try {
      const adminResponse = await fetch(adminUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(testEntry),
      });

      if (adminResponse.ok) {
        // Token has admin/write access
        log("Token has write access - this is not recommended!", "error");
        showTokenStatus(
          "error",
          "❗",
          "❗ Token has admin access! Use read-only token."
        );
        currentState.tokenValidationStatus = "valid-admin";
      } else {
        // Admin access failed - this is the expected behavior for read-only token
        log("Token is read-only - this is the expected safe state", "success");
        showTokenStatus("success", "✅", "✅ Token is read-only (safe)");
        currentState.tokenValidationStatus = "valid-readonly";
      }
    } catch (adminError) {
      // Admin request failed (network error or CORS) - assume read-only
      log("Token appears to be read-only", "success");
      showTokenStatus("success", "✅", "✅ Token is read-only (safe)");
      currentState.tokenValidationStatus = "valid-readonly";
    }

    currentState.apiToken = apiToken;
  } catch (error) {
    log(`Token validation failed: ${error.message}`, "error");
    showTokenStatus("error", "✗", `✗ ${error.message}`);
    currentState.tokenValidationStatus = "invalid";
  }
}

function showTokenStatus(type, icon, message) {
  const verifyBtn = document.getElementById("verify-btn");

  // Update button text with status
  verifyBtn.textContent = `${icon} ${message}`;

  // Update button styling based on status
  if (type === "success") {
    verifyBtn.style.backgroundColor = "#48bb78";
    verifyBtn.style.color = "white";
  } else if (type === "error") {
    verifyBtn.style.backgroundColor = "#f56565";
    verifyBtn.style.color = "white";
  } else if (type === "validating") {
    verifyBtn.style.backgroundColor = "#ecc94b";
    verifyBtn.style.color = "black";
  } else {
    verifyBtn.style.backgroundColor = "";
    verifyBtn.style.color = "";
  }
}

function loadMockData() {
  log("Loading mock data...");
  showStatus("Loading mock data...", "info");

  setTimeout(() => {
    log(`Loaded ${MOCK_DATA.length} mock entries`, "success");
    showStatus(`✓ Loaded ${MOCK_DATA.length} mock glucose readings`, "success");
    processData(MOCK_DATA);
  }, 500);
}

function processData(entries) {
  if (!entries || entries.length === 0) {
    log("No data to process", "error");
    return;
  }

  const latest = entries[0];
  const previous = entries[1];

  // Calculate delta
  let delta = 0;
  let deltaDisplay = "--";
  if (previous && latest.sgv && previous.sgv) {
    delta = latest.sgv - previous.sgv;
    deltaDisplay = (delta >= 0 ? "+" : "") + delta;
  }

  // Map trend arrow
  const trend = TREND_MAP[latest.direction] || "?";
  if (!TREND_MAP[latest.direction]) {
    console.warn(`Unknown trend direction: ${latest.direction}`);
  }

  // Extract data points
  const dataPoints = entries.map((entry) => entry.sgv || 0).reverse();

  // Format time
  const lastUpdate = formatTimeSince(latest.date || latest.dateString);

  // Update state
  currentState = {
    apiUrl: document.getElementById("api-url").value,
    currentBG: latest.sgv ? latest.sgv.toString() : "--",
    trend: trend,
    delta: deltaDisplay,
    lastUpdate: lastUpdate,
    dataPoints: dataPoints,
  };

  log(
    `Current BG: ${currentState.currentBG}, Trend: ${currentState.trend}, Delta: ${currentState.delta}`
  );
  log(`Last update: ${currentState.lastUpdate}`);

  updateUI();
}

function updateUI() {
  // Update stats
  document.getElementById("current-bg").textContent = currentState.currentBG;
  document.getElementById("trend").textContent = currentState.trend;
  document.getElementById("delta").textContent = currentState.delta;
  document.getElementById("last-update").textContent = currentState.lastUpdate;

  // Update graph
  drawGraph(currentState.dataPoints);
}

function formatTimeSince(timestamp) {
  try {
    const date = new Date(timestamp);
    const now = new Date();
    const diffMs = now - date;
    const diffMin = Math.floor(diffMs / 60000);

    if (diffMin < 1) return "Just now";
    if (diffMin === 1) return "1 min ago";
    if (diffMin < 60) return `${diffMin} min ago`;

    const diffHour = Math.floor(diffMin / 60);
    if (diffHour === 1) return "1 hour ago";
    return `${diffHour} hours ago`;
  } catch (error) {
    console.error("Error formatting time:", error);
    return "Unknown";
  }
}

function initializeGraph() {
  const canvas = document.getElementById("glucose-graph");
  const ctx = canvas.getContext("2d");

  // Set canvas size
  canvas.width = canvas.offsetWidth;
  canvas.height = canvas.offsetHeight;

  // Draw placeholder
  ctx.fillStyle = "#333";
  ctx.font = "14px Arial";
  ctx.textAlign = "center";
  ctx.fillText("No data loaded", canvas.width / 2, canvas.height / 2);
}

function drawGraph(dataPoints) {
  if (!dataPoints || dataPoints.length === 0) {
    initializeGraph();
    return;
  }

  const canvas = document.getElementById("glucose-graph");
  const ctx = canvas.getContext("2d");

  // Clear canvas
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  // Calculate dimensions
  const padding = 10;
  const width = canvas.width - 2 * padding;
  const height = canvas.height - 2 * padding;

  // Find min/max for scaling
  const validPoints = dataPoints.filter((p) => p > 0);
  if (validPoints.length === 0) {
    // No valid data points, show message
    ctx.fillStyle = "#888";
    ctx.font = "14px Arial";
    ctx.textAlign = "center";
    ctx.fillText("No valid data points", canvas.width / 2, canvas.height / 2);
    return;
  }

  const minBG = Math.min(...validPoints);
  const maxBG = Math.max(...validPoints);
  const range = maxBG - minBG || 100;

  // Draw background zones
  const targetLow = 70;
  const targetHigh = 180;

  // Low zone (red)
  const lowY = padding + height - ((targetLow - minBG) / range) * height;
  ctx.fillStyle = "rgba(255, 0, 0, 0.1)";
  ctx.fillRect(padding, lowY, width, height - lowY + padding);

  // Target zone (green)
  const highY = padding + height - ((targetHigh - minBG) / range) * height;
  ctx.fillStyle = "rgba(0, 255, 0, 0.1)";
  ctx.fillRect(padding, highY, width, lowY - highY);

  // High zone (yellow)
  ctx.fillStyle = "rgba(255, 255, 0, 0.1)";
  ctx.fillRect(padding, padding, width, highY - padding);

  // Draw grid lines
  ctx.strokeStyle = "#333";
  ctx.lineWidth = 1;
  for (let i = 0; i <= 4; i++) {
    const y = padding + (height / 4) * i;
    ctx.beginPath();
    ctx.moveTo(padding, y);
    ctx.lineTo(padding + width, y);
    ctx.stroke();

    // Draw value labels
    const value = Math.round(maxBG - (range / 4) * i);
    ctx.fillStyle = "#666";
    ctx.font = "10px Arial";
    ctx.textAlign = "right";
    ctx.fillText(value, padding - 5, y + 4);
  }

  // Draw data line
  ctx.strokeStyle = "#4ade80";
  ctx.lineWidth = 2;
  ctx.beginPath();

  const pointSpacing = width / (dataPoints.length - 1);

  dataPoints.forEach((value, index) => {
    if (value <= 0) return;

    const x = padding + index * pointSpacing;
    const y = padding + height - ((value - minBG) / range) * height;

    if (index === 0) {
      ctx.moveTo(x, y);
    } else {
      ctx.lineTo(x, y);
    }
  });

  ctx.stroke();

  // Draw dots at data points
  ctx.fillStyle = "#4ade80";
  dataPoints.forEach((value, index) => {
    if (value <= 0) return;

    const x = padding + index * pointSpacing;
    const y = padding + height - ((value - minBG) / range) * height;

    ctx.beginPath();
    ctx.arc(x, y, 2, 0, 2 * Math.PI);
    ctx.fill();
  });

  log(`Graph updated with ${dataPoints.length} points`);
}

// Expose for debugging
window.simulator = {
  state: currentState,
  loadMockData,
  fetchData,
  verifyUrl,
};
