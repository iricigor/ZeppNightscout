# ZeppNightscout

An app for Zepp OS that connects to Nightscout instance and displays CGM data.

## Features

- **Settings Text Field**: Configure your Nightscout API URL
- **Glucose Graph**: Visual representation of recent glucose readings
- **Calculated Values**: Display current BG, trend arrow, delta, and last update time
- **Internet Connectivity**: Fetches real-time data from Nightscout API

## Project Structure

```
├── .devcontainer/          # GitHub Codespaces configuration
│   └── devcontainer.json   # Dev container setup for VS Code
├── app.json                # Zepp OS app manifest
├── package.json            # Node.js project configuration
├── page/                   # Device-side UI code
│   └── index.js           # Main page with UI widgets
├── app-side/              # App-side service code
│   └── index.js           # API fetching logic
├── shared/                # Shared code between device and app-side
│   └── message.js         # Message communication layer
└── assets/                # Images, fonts, and resources
```

## UI Components

1. **Text Display**: Shows Nightscout API URL configuration
2. **Large BG Value**: Displays current blood glucose reading in large font
3. **Trend Indicator**: Shows trend arrow (↑, →, ↓, etc.)
4. **Delta Value**: Shows change from previous reading
5. **Last Update Time**: Shows how long ago data was fetched
6. **Canvas Graph**: Visual chart of recent glucose readings
7. **Fetch Button**: Triggers data refresh from API

## Development Setup

### Using GitHub Codespaces

This project is configured for GitHub Codespaces with GitHub Copilot support:

1. Click "Code" → "Create codespace on main"
2. The dev container will automatically:
   - Set up Node.js 20
   - Install dependencies
   - Configure VS Code with ESLint, Prettier, and GitHub Copilot extensions
   - Forward port 8080 for development server

### Local Development

1. Install Node.js 20 or later
2. Clone the repository:
   ```bash
   git clone https://github.com/iricigor/ZeppNightscout.git
   cd ZeppNightscout
   ```
3. Install dependencies:
   ```bash
   npm install
   ```

## Building for Zepp OS

To build this app for Zepp OS devices, you'll need the Zepp OS development tools. Follow the official [Zepp OS documentation](https://docs.zepp.com/) for setup instructions.

## API Integration

The app connects to Nightscout API using the following endpoint:
```
GET {nightscout-url}/api/v1/entries.json?count=10
```

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
