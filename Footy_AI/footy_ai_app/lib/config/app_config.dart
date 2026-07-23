class AppConfig {
  // Runtime overrides:
  // flutter run --dart-define=DB_API_BASE_URL=http://<ip>/Footy_AI/api
  //   --dart-define=PROCESSING_API_BASE_URL=http://<ip>:8000
  static const String _defaultDbApiBaseUrl = 'http://10.88.195.39/Footy_AI/api';
  static const String _defaultProcessingApiBaseUrl = 'http://10.88.195.39:8000';

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
