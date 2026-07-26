class AppConfig {
  // Runtime overrides:
  // flutter run --dart-define=DB_API_BASE_URL=http://<ip>/Footy_AI/api
  //   --dart-define=PROCESSING_API_BASE_URL=http://<ip>:8000
  static const String _defaultDbApiBaseUrl = '';
  static const String _defaultProcessingApiBaseUrl = '';

  static String get dbApiBaseUrl {
    return const String.fromEnvironment(
      'DB_API_BASE_URL',
      defaultValue: _defaultDbApiBaseUrl,
    );
  }

  static String get processingApiBaseUrl {
    return const String.fromEnvironment(
      'PROCESSING_API_BASE_URL',
      defaultValue: _defaultProcessingApiBaseUrl,
    );
  }
}
