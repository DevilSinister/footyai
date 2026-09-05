import '../config/app_config.dart';

class ApiConstants {
  static String get baseUrl => AppConfig.dbApiBaseUrl;

  static const String usersRegister = '/api/users/register';
  static const String usersLogin = '/api/users/login';
  static const String usersById = '/api/users';

  static const String matches = '/api/matches';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String _baseUrl = ApiConstants.baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  String get baseUrl => _baseUrl;
}
