# Development Guide

This guide provides detailed information for developing the Nightscout Zepp OS app.

## GitHub Codespaces Setup

The project is optimized for GitHub Codespaces with the following features:

### Automatic Configuration

When you open this project in Codespaces:
1. Node.js 20 is automatically installed
2. npm dependencies are automatically installed via `postCreateCommand`
3. VS Code extensions are automatically installed:
   - ESLint for code linting
   - Prettier for code formatting
   - GitHub Copilot for AI-assisted coding
   - GitHub Copilot Chat for conversational AI help

### Dev Container Features

- **Node.js 20**: Latest LTS version for JavaScript development
- **GitHub CLI**: Pre-installed for Git operations
- **Port Forwarding**: Port 8080 is forwarded for dev servers
- **Auto-formatting**: Code is formatted on save with Prettier
- **Linting**: ESLint automatically fixes issues on save

## GitHub Copilot Integration

This project is configured to work seamlessly with GitHub Copilot:

### Using Copilot for Development

1. **Code Completion**: Start typing and Copilot will suggest completions
2. **Function Generation**: Write a comment describing what you want, and Copilot will generate the code
3. **Chat Integration**: Use Copilot Chat to ask questions about the code

### Example Copilot Prompts

```javascript
// Generate a function to validate Nightscout URL
// [Copilot will suggest the implementation]

// Add error handling for network requests
// [Copilot will suggest try-catch blocks]

// Create a function to format glucose values with units
// [Copilot will generate the formatter]
```

## Zepp OS Development

### API Structure

The app follows Zepp OS architecture:

1. **Device Side** (`page/index.js`):
   - Runs on the watch/device
   - Handles UI rendering
   - Limited API access (no direct internet)
   - Communicates with app-side via messaging

2. **App Side** (`app-side/index.js`):
   - Runs on the companion device (phone)
   - Has full API access including internet
   - Handles data fetching and processing
   - Communicates with device-side via messaging

### UI Widgets Used

1. **TEXT**: For displaying labels and values
2. **CANVAS**: For drawing the glucose graph
3. **BUTTON**: For triggering data fetch

### Key APIs

- `hmUI.createWidget()`: Create UI elements
- `hmUI.widget.*`: Widget types (TEXT, CANVAS, BUTTON)
- `canvas.strokeLine()`: Draw lines on canvas
- `messaging.peerSocket`: Device-to-app communication

## Code Structure

### Page Lifecycle

```javascript
Page({
  onInit() {
    // Called when page is created
    // Build UI here
  },
  
  onShow() {
    // Called when page becomes visible
  },
  
  onHide() {
    // Called when page is hidden
  },
  
  onDestroy() {
    // Called when page is destroyed
    // Cleanup here
  }
});
```

### App-Side Service Lifecycle

```javascript
AppSideService({
  onInit() {
    // Initialize service
  },
  
  onRun() {
    // Service is running
  },
  
  onDestroy() {
    // Cleanup
  }
});
```

## Testing Strategy

For comprehensive testing instructions, including local development testing, simulator testing, and deployment to your personal watch, see the **[Testing Guide (TESTING.md)](TESTING.md)**.

### Quick Testing

```bash
# Run data parser tests
npm test

# Check JavaScript syntax
npm run test:syntax
```

### Manual Testing

1. **UI Testing**: Verify all widgets display correctly
2. **Data Flow**: Test message passing between device and app-side
3. **API Integration**: Test with real Nightscout URL
4. **Error Handling**: Test with invalid URLs, network errors

### Simulation

Use Zepp OS simulator for testing:
```bash
# Install Zeus CLI (official Zepp OS tool)
npm install -g @zeppos/zeus-cli

# Start simulator
zeus dev
```

For detailed simulation and device testing steps, refer to [TESTING.md](TESTING.md).

## Extending the App

### Adding New Features

1. **Add Settings Page**: Create a new page for configuration
2. **Add Alarms**: Implement glucose threshold alerts
3. **Add Historical Data**: Show 24-hour glucose trends
4. **Add Statistics**: Calculate average, time in range, etc.

### UI Customization

- Modify colors in widget properties
- Adjust layout positions for different screen sizes
- Add animations with widget property updates

### API Enhancements

- Support multiple Nightscout endpoints
- Add authentication tokens
- Implement data caching
- Add offline mode

## Best Practices

1. **Performance**:
   - Minimize API calls
   - Cache data when possible
   - Optimize canvas drawing

2. **Error Handling**:
   - Always wrap API calls in try-catch
   - Show user-friendly error messages
   - Log errors for debugging

3. **Code Quality**:
   - Follow ESLint rules
   - Use Prettier for consistent formatting
   - Write descriptive comments
   - Use meaningful variable names

4. **GitHub Copilot**:
   - Write clear comments for better suggestions
   - Review generated code before accepting
   - Use Copilot Chat for complex questions

## Resources

- [Zepp OS Official Documentation](https://docs.zepp.com/)
- [Zepp OS Samples Repository](https://github.com/zepp-health/zeppos-samples)
- [Nightscout API Documentation](http://www.nightscout.info/)
- [GitHub Codespaces Docs](https://docs.github.com/codespaces)
- [GitHub Copilot Docs](https://docs.github.com/copilot)

## Troubleshooting

### Common Issues

1. **Node modules not found**: Run `npm install`
2. **Port not forwarding**: Check `.devcontainer/devcontainer.json`
3. **Copilot not working**: Ensure you have an active Copilot subscription
4. **Build errors**: Check Zepp OS SDK installation

### Getting Help

- Use GitHub Copilot Chat for code questions
- Check Zepp OS documentation
- Review the samples repository
- Open an issue in this repository
