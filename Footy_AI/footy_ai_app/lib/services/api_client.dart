import '../config/app_config.dart';

class ApiConstants {
  static String get baseUrl => AppConfig.dbApiBaseUrl;
  
  static const String usersRegister = '/Users/Register';
  static const String usersLogin = '/Users/Login';
  static const String usersById = '/Users/GetUserById';

  static const String processingIngest = '/Processing/IngestMatchSummary';
  static const String processingGetByUser = '/Processing/GetMatchesByUser';
  static const String processingGetMatchSummary = '/Processing/GetMatchSummary';
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
