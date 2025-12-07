# ZeppNightscout

An app for Zepp OS that connects to Nightscout instance and displays CGM data.

## Features

- **Settings Text Field**: Configure your Nightscout API URL
- **URL Verification**: Verify your Nightscout URL before fetching data (uses `/api/v1/status` endpoint)
- **Glucose Graph**: Visual representation of recent glucose readings (displays 200 data points)
- **Calculated Values**: Display current BG, trend arrow, delta, and last update time
- **Internet Connectivity**: Fetches real-time data from Nightscout API
- **Pixel-Perfect Display**: 200 values for ~200px screen width (one pixel per value)

## Development Setup

### Quick Start

**New to the project?** See [QUICK-START.md](QUICK-START.md) for the fastest way to get the app running on your watch using `zeus preview`!

### Using GitHub Codespaces

This project is configured for GitHub Codespaces with GitHub Copilot support:

1. Click "Code" → "Create codespace on main"
2. The dev container will automatically:
   - Set up Node.js 20
   - Install dependencies
   - Configure VS Code with ESLint, Prettier, and GitHub Copilot extensions
   - Forward port 8080 for development server

## Testing

For detailed testing instructions, see the [Testing Guide](docs/TESTING.md).

### Automated Testing

This project uses GitHub Actions to automatically run tests on every pull request:

- ✅ JavaScript syntax validation
- ✅ Unit tests (26 assertions)
- ✅ Build validation (31 assertions)
- ✅ Actual app build with Zeus CLI
- ✅ Command verification

All tests must pass before merging.

### Quick Start

```bash
# Test data parser
npm test

# Check JavaScript syntax
npm run test:syntax

# Validate build requirements
npm run test:build

# Build and run in simulator (requires Zeus CLI)
npm run dev
```

## Building for Zepp OS

To build this app for Zepp OS devices, you'll need the Zepp OS development tools. Follow the official [Zepp OS documentation](https://docs.zepp.com/) for setup instructions.

### Quick Build

```bash
# Install Zeus CLI
npm install -g @zeppos/zeus-cli

# Build the app
zeus build --production

# Install to connected device
zeus install
```

### Quick Testing with QR Code

The easiest way to test the app on your watch is using `zeus preview`:

```bash
# Install Zeus CLI (if not already installed)
npm install -g @zeppos/zeus-cli

# Login to Zeus (one-time setup)
zeus login

# Generate QR code for quick install
zeus preview
```

Then:
1. Enable Developer Mode in Zepp App (tap Zepp icon 7 times in Profile → Settings → About)
2. Go to Profile → Your Device → Developer Mode in the Zepp App
3. Tap "Scan" and scan the QR code shown in your terminal
4. The app will be installed directly to your watch

For detailed build and deployment instructions, see [TESTING.md](docs/TESTING.md).

## API Integration

The app connects to Nightscout API using the following endpoints:

### URL Verification
```
GET {nightscout-url}/api/v1/status
```
This endpoint is used to verify the Nightscout URL without transferring CGM data. It returns server status information.

### Data Fetching
```
GET {nightscout-url}/api/v1/entries.json?count=200
```
Fetches 200 glucose readings for detailed trend visualization (one value per pixel for ~200px screen width).

### Security

**Important**: When configuring your Nightscout URL, ensure you use a token with **read-only access** to protect your data. 

To configure read-only access tokens:
1. Visit your Nightscout instance admin panel
2. Create a new token with read-only permissions
3. Use the token in your API URL: `https://your-nightscout.herokuapp.com?token=YOUR_READ_ONLY_TOKEN`

For more information about Nightscout security and token configuration, see:
- [Nightscout Security Documentation](http://www.nightscout.info/wiki/welcome/website-features/0-9-features/authentication-roles)
- [Nightscout Setup Guide](http://www.nightscout.info/)

Expected response format:
```json
[
  {
    "sgv": 120,
    "direction": "Flat",
    "dateString": "2023-12-07T12:00:00.000Z",
    "date": 1701950400000
  }
]
```

## Configuration

Update the `apiUrl` in `page/index.js` to point to your Nightscout instance:
```javascript
state: {
  apiUrl: 'https://your-nightscout.herokuapp.com',
  ...
}
```

## Technologies Used

- **Zepp OS SDK**: For device-side UI and app-side services
- **JavaScript**: Programming language
- **Canvas API**: For graph rendering
- **Fetch API**: For HTTP requests to Nightscout

## References

- [Zepp OS Documentation](https://docs.zepp.com/)
- [Zepp OS Samples](https://github.com/zepp-health/zeppos-samples)
- [Nightscout API](http://www.nightscout.info/)

## License

MIT
