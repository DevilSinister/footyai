import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_prediction.dart';
import '../models/match_highlight.dart';
import 'api_client.dart';
class ApiService {
  static String get _baseUrl => ApiConstants.baseUrl;

  static Future<List<AIPrediction>> fetchPredictions({int? userId}) async {
    try {
      final matches = await fetchRecentMatches(userId: userId);
      if (matches.isEmpty) {
        return [];
      }

      final sortedMatches = List<Map<String, dynamic>>.from(matches)
        ..sort((a, b) => _compareMatchDates(b, a));

      final predictions = <AIPrediction>[];
      for (final match in sortedMatches.take(6)) {
        final matchId = match['matchId']?.toString();
        if (matchId == null || matchId.isEmpty) {
          continue;
        }

        final summary = await fetchMatchSummary(matchId);
        final scoreboard = _extractScoreboard(summary);
        final matchTime =
            DateTime.tryParse((match['matchDate'] ?? '').toString()) ??
            DateTime.now();
        final probabilities = _buildPredictionProbabilities(
          scoreboard['homeScore'],
          scoreboard['awayScore'],
        );

        predictions.add(
          AIPrediction(
            matchId: matchId,
            homeTeam: scoreboard['homeTeam'],
            awayTeam: scoreboard['awayTeam'],
            homeLogo: '',
            awayLogo: '',
            homeWinProb: probabilities['home']!,
            drawProb: probabilities['draw']!,
            awayWinProb: probabilities['away']!,
            tacticalInsight: _buildPredictionInsight(
              scoreboard['homeScore'],
              scoreboard['awayScore'],
            ),
            league: 'Footy AI',
            matchTime: matchTime,
          ),
        );
      }

      return predictions;
    } catch (_) {
      return [];
    }
  }

  static Future<List<MatchHighlight>> fetchHighlights({int? userId}) async {
    try {
      final summary = await fetchLatestMatchSummary(userId: userId);
      if (summary == null) {
        return [];
      }
      return _buildHighlightsFromSummary(summary);
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchLatestMatchSummary({
    int? userId,
  }) async {
    try {
      final matches = await fetchRecentMatches(userId: userId);
      if (matches.isEmpty) {
        return null;
      }

      final sortedMatches = List<Map<String, dynamic>>.from(matches)
        ..sort((a, b) => _compareMatchDates(b, a));

      final matchId = sortedMatches.first['matchId']?.toString();
      if (matchId == null || matchId.isEmpty) {
        return null;
      }

      return fetchMatchSummary(matchId);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchMatchSummary(String matchId) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl${ApiConstants.matches}/$matchId',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRecentMatches({
    int? userId,
  }) async {
    try {
      final effectiveUserId = (userId ?? 1).toString();
      final uri = Uri.parse(
        '$_baseUrl${ApiConstants.matches}',
      ).replace(queryParameters: {'user_id': effectiveUserId});
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static List<MatchHighlight> _buildHighlightsFromSummary(
    Map<String, dynamic> summary,
  ) {
    final teamsRaw = (summary['teams'] as List<dynamic>?) ?? const [];
    final eventsRaw = (summary['events'] as List<dynamic>?) ?? const [];
    final occurByRaw = (summary['occurBy'] as List<dynamic>?) ?? const [];
    final playRaw = (summary['play'] as List<dynamic>?) ?? const [];
    final playersRaw = (summary['players'] as List<dynamic>?) ?? const [];

    final teamNameById = <int, String>{};
    final playTeamNameById = <int, String>{};
    final playerNameById = <int, String>{};
    final eventById = <dynamic, Map<String, dynamic>>{};

    for (final item in teamsRaw) {
      if (item is! Map<String, dynamic>) continue;
      final teamId = _readInt(item, ['teamId', 'tId', 'id']);
      if (teamId != null) {
        teamNameById[teamId] =
            _readString(item, ['teamName', 'tName', 'name']) ?? 'Team $teamId';
      }
    }

    for (final item in playRaw) {
      if (item is! Map<String, dynamic>) continue;
      final playId = _readInt(item, ['playId', 'plId', 'id']);
      final teamId = _readInt(item, ['teamId', 'tID', 'tId']);
      if (playId != null && teamId != null) {
        playTeamNameById[playId] = teamNameById[teamId] ?? 'Team $teamId';
      }
    }

    for (final item in playersRaw) {
      if (item is! Map<String, dynamic>) continue;
      final playerId = _readInt(item, [
        'playerId',
        'pId',
        'id',
        'playerLookupId',
      ]);
      final playerName = _readString(item, [
        'playerName',
        'name',
        'fullName',
        'username',
      ]);
      if (playerId != null && playerName != null && playerName.isNotEmpty) {
        playerNameById[playerId] = playerName;
      }
    }

    for (final item in eventsRaw) {
      if (item is Map<String, dynamic>) {
        final eventId = item['eventId'] ?? item['eId'] ?? item['id'];
        eventById[eventId] = item;
      }
    }

    final scoreboard = _extractScoreboard(summary);
    final highlights = <MatchHighlight>[];

    for (final item in occurByRaw) {
      if (item is! Map<String, dynamic>) continue;

      final eventId = item['eventId'] ?? item['eId'] ?? item['id'];
      final eventObj = eventById[eventId] ?? <String, dynamic>{};
      final playId = _readInt(item, ['playId', 'plId', 'pId']);
      final playerLookupId = _readInt(item, [
        'playerLookupId',
        'playerId',
        'pId',
        'detectedPlayerTrackId',
      ]);
      final detectedJersey =
          _readInt(item, ['detectedJerseyNo', 'jerseyNumber', 'jerseyNo']) ??
          _readInt(eventObj, ['jerseyNumber', 'detectedJerseyNo', 'jerseyNo']);
      final eventType =
          _readString(eventObj, ['eventType', 'type']) ??
          _readString(item, ['eventType', 'type']) ??
          'Event';
      final description =
          _readString(eventObj, [
            'description',
            'eventName',
            'reason',
            'detail',
          ]) ??
          _readString(item, ['description', 'detail']) ??
          eventType;
      final title =
          _readString(eventObj, ['eventName', 'title']) ?? description;
      final timeValue =
          _readString(item, ['startTime', 'time']) ??
          _readString(eventObj, ['time']) ??
          _formatSeconds(_readNum(eventObj, ['timeSec']));
      final playerName =
          (playerLookupId != null && playerNameById[playerLookupId] != null)
          ? playerNameById[playerLookupId]!
          : _readString(item, ['detectedPlayerName', 'playerName']) ??
                _readString(eventObj, ['player', 'playerName']) ??
                (detectedJersey == null
                    ? 'Scorer unavailable'
                    : '#$detectedJersey');
      final teamName = (playId != null && playTeamNameById[playId] != null)
          ? playTeamNameById[playId]!
          : _readString(eventObj, ['teamName', 'team']) ?? 'Team';

      highlights.add(
        MatchHighlight(
          time: timeValue,
          title: title,
          player: playerName,
          type: _titleCase(eventType),
          team: teamName,
          description: description,
          scoreHome: scoreboard['homeScore'],
          scoreAway: scoreboard['awayScore'],
          teamHome: scoreboard['homeTeam'],
          teamAway: scoreboard['awayTeam'],
        ),
      );
    }

    if (highlights.isEmpty) {
      for (final item in eventsRaw) {
        if (item is! Map<String, dynamic>) continue;
        final eventType = _readString(item, ['eventType', 'type']) ?? 'Event';
        final description =
            _readString(item, [
              'description',
              'eventName',
              'reason',
              'detail',
            ]) ??
            eventType;
        highlights.add(
          MatchHighlight(
            time: _readString(item, ['time', 'timeSec']) ?? '',
            title: _readString(item, ['eventName', 'title']) ?? description,
            player: _readString(item, ['player', 'playerName']) ?? description,
            type: _titleCase(eventType),
            team: _readString(item, ['teamName', 'team']) ?? 'Team',
            description: description,
            scoreHome: scoreboard['homeScore'],
            scoreAway: scoreboard['awayScore'],
            teamHome: scoreboard['homeTeam'],
            teamAway: scoreboard['awayTeam'],
          ),
        );
      }
    }

    return highlights;
  }

  static Map<String, dynamic> _extractScoreboard(
    Map<String, dynamic>? summary,
  ) {
    final teamsRaw = (summary?['teams'] as List<dynamic>?) ?? const [];
    final playRaw = (summary?['play'] as List<dynamic>?) ?? const [];

    String homeTeam = 'Team A';
    String awayTeam = 'Team B';
    int homeTeamId = -1;
    int awayTeamId = -1;
    int homeScore = 0;
    int awayScore = 0;

    if (teamsRaw.isNotEmpty && teamsRaw.first is Map<String, dynamic>) {
      final firstTeam = teamsRaw.first as Map<String, dynamic>;
      homeTeam =
          _readString(firstTeam, ['teamName', 'tName', 'name']) ?? homeTeam;
      homeTeamId = _readInt(firstTeam, ['teamId', 'tId', 'id']) ?? homeTeamId;
    }

    if (teamsRaw.length > 1 && teamsRaw[1] is Map<String, dynamic>) {
      final secondTeam = teamsRaw[1] as Map<String, dynamic>;
      awayTeam =
          _readString(secondTeam, ['teamName', 'tName', 'name']) ?? awayTeam;
      awayTeamId = _readInt(secondTeam, ['teamId', 'tId', 'id']) ?? awayTeamId;
    }

    for (final item in playRaw) {
      if (item is! Map<String, dynamic>) continue;
      final teamId = _readInt(item, ['teamId', 'tID', 'tId']);
      final score = _readInt(item, ['score']) ?? 0;
      if (teamId != null && teamId == homeTeamId) {
        homeScore = score;
      }
      if (teamId != null && teamId == awayTeamId) {
        awayScore = score;
      }
    }

    return {
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeScore': homeScore,
      'awayScore': awayScore,
    };
  }

  static Map<String, double> _buildPredictionProbabilities(
    int homeScore,
    int awayScore,
  ) {
    if (homeScore == awayScore) {
      return {'home': 0.33, 'draw': 0.34, 'away': 0.33};
    }
    if (homeScore > awayScore) {
      return {'home': 0.58, 'draw': 0.22, 'away': 0.20};
    }
    return {'home': 0.20, 'draw': 0.22, 'away': 0.58};
  }

  static String _buildPredictionInsight(int homeScore, int awayScore) {
    if (homeScore == awayScore) {
      return 'The processed match finished level, so the live data suggests a balanced contest.';
    }
    if (homeScore > awayScore) {
      return 'The processed match favored the home side, with live data showing a stronger attacking output.';
    }
    return 'The processed match favored the away side, with live data showing the stronger finish.';
  }

  static int _compareMatchDates(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final leftDate =
        DateTime.tryParse((left['matchDate'] ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final rightDate =
        DateTime.tryParse((right['matchDate'] ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return leftDate.compareTo(rightDate);
  }

  static String _formatSeconds(num? seconds) {
    if (seconds == null) return '';
    final totalSeconds = seconds.floor();
    final minutes = totalSeconds ~/ 60;
    final remainder = totalSeconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }

  static String _titleCase(String value) {
    return value
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  static int? _readInt(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value != null) {
        final parsed = int.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static num? _readNum(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is num) return value;
      if (value != null) {
        final parsed = num.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static String? _readString(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value == null) continue;
      final text = value.toString();
      if (text.isNotEmpty) return text;
    }
    return null;
  }
}
