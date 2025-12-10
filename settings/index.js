/**
 * Nightscout Zepp OS App - Settings Page
 * Settings page that displays in the Zepp mobile app
 */

AppSettingsPage({
  build(props) {
    return View(
      {
        style: {
          padding: '20px'
        }
      },
      [
        Text({
          label: 'Welcome to Zepp Nightscout settings',
          style: {
            fontSize: '16px',
            color: '#333333'
          }
        })
      ]
    );
  }
});
