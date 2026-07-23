class AppConfig {
  // Update these two IPs when your local network changes.
  // Example: http://10.146.25.39/...10.88.195.39
  static const String dbApiBaseUrlFixed = 'http://10.88.195.39/Footy_AI/api';
  static const String processingApiBaseUrlFixed = 'http://10.88.195.39:8000';

  static String get dbApiBaseUrl {
    return dbApiBaseUrlFixed;
  }

  static String get processingApiBaseUrl {
    return processingApiBaseUrlFixed;
  }
}
