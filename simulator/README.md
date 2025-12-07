# Zepp Nightscout Simulator

Browser-based simulator for quick testing and development of the Zepp Nightscout app.

![Zepp Nightscout Simulator](https://github.com/user-attachments/assets/bb4f4591-4bfc-463a-b7f1-071d6b2bb8f1)

## Quick Start

### Using F5 (Recommended)

1. Open the project in VS Code
2. Press **F5**
3. The simulator will open in your browser automatically

### Using npm

```bash
npm run simulator
# or
npm start
```

The simulator will start on `http://localhost:8080` and open automatically in your browser.

## Features

- **Watch Interface Simulation**: Visual representation of the Zepp OS watch screen (480x480)
- **Real-time Data Fetching**: Connect to actual Nightscout APIs for testing
- **Mock Data Testing**: Load simulated glucose data without a Nightscout instance
- **URL Verification**: Test Nightscout URL connectivity
- **Interactive Graph**: Visual glucose trend display with color-coded zones
- **Console Logging**: Monitor API calls and data processing

## Using the Simulator

### Testing with Mock Data

1. Click **"Load Mock Data"**
2. The simulator will display 200 simulated glucose readings
3. Perfect for UI testing and development without a Nightscout instance

### Testing with Real Nightscout API

1. Enter your Nightscout URL (e.g., `https://your-nightscout.herokuapp.com`)
2. Click **"Verify URL"** to test connectivity
3. Click **"Fetch Data"** to load real glucose readings
4. Monitor the console logs for API response details

### Supported Features

- ✅ Current blood glucose value
- ✅ Trend arrows (⇈ ↑ ↗ → ↘ ↓ ⇊)
- ✅ Delta (change from previous reading)
- ✅ Last update timestamp
- ✅ Glucose graph with 200 data points
- ✅ Color-coded zones (low/target/high)

## GitHub Codespaces Support

The simulator is fully compatible with GitHub Codespaces:

1. Start the simulator with `npm run simulator`
2. Codespaces will automatically detect port 8080
3. Click the pop-up notification to open in browser
4. Or use the "Ports" tab to access the forwarded port

The simulator automatically detects Codespaces and configures the correct URL.

## Development

### File Structure

```
simulator/
├── index.html      # Simulator UI
└── simulator.js    # Simulator logic and API handling

scripts/
└── start-simulator.js  # HTTP server with auto-browser opening

.vscode/
└── launch.json     # F5 debug configuration
```

### Customization

Edit `simulator/simulator.js` to customize:
- Mock data generation
- API endpoints
- Graph rendering
- UI behavior

Edit `simulator/index.html` to customize:
- Layout and styling
- Watch screen dimensions
- UI components

## Keyboard Shortcuts

- **F5**: Start simulator (in VS Code)
- **Ctrl+C**: Stop server (in terminal)

## Troubleshooting

### Browser doesn't open automatically
- Manually open `http://localhost:8080` in your browser
- In Codespaces, use the forwarded port URL from the "Ports" tab

### CORS errors when testing with Nightscout
- Ensure your Nightscout instance has CORS enabled
- Check that your Nightscout URL is correct and accessible
- Try using the mock data first to verify the simulator is working

### Port 8080 already in use
- Stop any other services using port 8080
- Or set a different port: `PORT=3000 npm run simulator`

## Comparison with Zeus Simulator

| Feature | Browser Simulator | Zeus Simulator |
|---------|------------------|----------------|
| Startup time | Instant | Slower |
| Browser-based | ✅ | ❌ |
| F5 support | ✅ | ❌ |
| Codespaces | ✅ | ❌ |
| Full device API | ❌ | ✅ |
| Quick iteration | ✅ | ❌ |
| Production testing | ❌ | ✅ |

**Use Browser Simulator for**: Quick testing, UI development, API testing, rapid iteration

**Use Zeus Simulator for**: Full device testing, production builds, device-specific features

## Contributing

To improve the simulator:
1. Edit files in `simulator/` directory
2. Test changes with `npm run simulator`
3. Submit a pull request

## License

MIT
