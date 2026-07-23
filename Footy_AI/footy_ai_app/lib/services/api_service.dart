import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import '../models/ai_prediction.dart';
import '../models/match_highlight.dart';

class ApiService {
  static final ApiClient _client = ApiClient();

  static Future<List<AIPrediction>> fetchPredictions() async {
    return [];
  }

  static Future<List<MatchHighlight>> fetchHighlights() async {
    return [];
  }

  static Future<Map<String, dynamic>?> fetchMatchSummary(String matchId) async {
    try {
      final uri = Uri.parse('${_client.baseUrl}${ApiConstants.processingGetMatchSummary}')
          .replace(queryParameters: {'matchId': matchId});
      final response = await http.get(
        uri,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRecentMatches({int? userId}) async {
    try {
      final effectiveUserId = (userId ?? 1).toString();
      final uri = Uri.parse('${_client.baseUrl}${ApiConstants.processingGetByUser}')
          .replace(queryParameters: {'userId': effectiveUserId});
      final response = await http.get(
        uri,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
