import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class UserModel {
  final int userId;
  final String username;
  final String email;

  const UserModel({
    required this.userId,
    required this.username,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId: json['userId'] as int,
    username: json['username'] as String,
    email: json['email'] as String,
  );
}

class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;

  const AuthResult({required this.success, required this.message, this.user});
}

// ── Service ─────────────────────────────────────────────────────────────────

class AuthService {
  static String get _baseUrl => ApiConstants.baseUrl;

  static const String _registerEndpoint = '/api/users/register';
  static const String _loginEndpoint = '/api/users/login';
  static const String _userEndpoint = '/api/users';

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static String _messageFromResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['message'] ?? data['detail'] ?? 'Request failed.')
          .toString();
    } catch (_) {
      return 'Server returned ${response.statusCode}.';
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  static Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_registerEndpoint'),
            headers: _headers,
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AuthResult(
          success: false,
          message: _messageFromResponse(response),
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final success = data['success'] == true;

      return AuthResult(
        success: success,
        message: data['message'] as String? ?? '',
        user: success && data['user'] != null
            ? UserModel.fromJson(data['user'] as Map<String, dynamic>)
            : null,
      );
    } catch (_) {
      return AuthResult(
        success: false,
        message:
            'Unable to reach $_baseUrl. Check Server Settings and make sure the FastAPI server is running.',
      );
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_loginEndpoint'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AuthResult(
          success: false,
          message: _messageFromResponse(response),
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final success = data['success'] == true;

      return AuthResult(
        success: success,
        message: data['message'] as String? ?? '',
        user: success && data['user'] != null
            ? UserModel.fromJson(data['user'] as Map<String, dynamic>)
            : null,
      );
    } catch (_) {
      return AuthResult(
        success: false,
        message:
            'Unable to reach $_baseUrl. Check Server Settings and make sure the FastAPI server is running.',
      );
    }
  }

  // ── Fetch user by ID ──────────────────────────────────────────────────────
  static Future<UserModel?> fetchUser(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$_userEndpoint/$userId'), headers: _headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return UserModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
