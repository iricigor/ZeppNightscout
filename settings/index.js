/**
 * Nightscout Zepp OS App - Settings Page
 * Settings page that displays in the Zepp mobile app
 */

AppSettingsPage({
  build(props) {
    return Section(
      {},
      [
        Text({
          label: 'Zepp Nightscout Settings'
        }),
        Text({
          label: 'Configure your Nightscout connection in the watch app (Page 3)'
        })
      ]
    );
  }
});
