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

### Using GitHub Codespaces

This project is configured for GitHub Codespaces with GitHub Copilot support:

1. Click "Code" → "Create codespace on main"
2. The dev container will automatically:
   - Set up Node.js 20
   - Install dependencies
   - Configure VS Code with ESLint, Prettier, and GitHub Copilot extensions
   - Forward port 8080 for development server

## Building for Zepp OS

To build this app for Zepp OS devices, you'll need the Zepp OS development tools. Follow the official [Zepp OS documentation](https://docs.zepp.com/) for setup instructions.

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
