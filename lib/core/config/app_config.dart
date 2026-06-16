class AppConfig {
  /// Prefer passing at build time:
  /// `--dart-define=OPENWEATHER_API_KEY=YOUR_KEY`
  ///
  /// NOTE: If you commit a real key in source, treat it as leaked and rotate it.
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: 'ec9d2ead2f16649d2ef771223db591c6',
  );

  static const String defaultWeatherCity = 'Layyah,PK';
}

