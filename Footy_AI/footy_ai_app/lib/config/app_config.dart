import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  // One FastAPI service now owns auth, match data, and video processing.
  // Physical devices must override API_BASE_URL with the computer's LAN IP.
  static const String _buildApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const String _savedApiBaseUrlKey = 'api_base_url';
  static const String _dbApiOverride = String.fromEnvironment(
    'DB_API_BASE_URL',
    defaultValue: '',
  );
  static const String _processingApiOverride = String.fromEnvironment(
    'PROCESSING_API_BASE_URL',
    defaultValue: '',
  );
  static String _apiBaseUrl = _buildApiBaseUrl;

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedUrl = preferences.getString(_savedApiBaseUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _apiBaseUrl = savedUrl;
    }
  }

  static String get apiBaseUrl => _apiBaseUrl;

  static String? validateAndNormalizeApiBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final urlText = trimmed.contains('://') ? trimmed : 'http://$trimmed';
    final uri = Uri.tryParse(urlText);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      return null;
    }

    final port = uri.hasPort ? uri.port : 8000;
    return Uri(scheme: uri.scheme, host: uri.host, port: port).toString();
  }

  static Future<void> saveApiBaseUrl(String normalizedUrl) async {
    _apiBaseUrl = normalizedUrl;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_savedApiBaseUrlKey, normalizedUrl);
  }

  static Future<void> resetApiBaseUrl() async {
    _apiBaseUrl = _buildApiBaseUrl;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_savedApiBaseUrlKey);
  }

  static String get dbApiBaseUrl {
    return _dbApiOverride.isNotEmpty ? _dbApiOverride : _apiBaseUrl;
  }

  static String get processingApiBaseUrl {
    return _processingApiOverride.isNotEmpty
        ? _processingApiOverride
        : _apiBaseUrl;
  }
}
