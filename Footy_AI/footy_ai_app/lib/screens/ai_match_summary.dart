import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../theme.dart';

class MatchEvent {
  final String type;
  final String startTime;
  final String endTime;
  final String title;
  final String? detail;
  final String? clipPath;

  MatchEvent({
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.detail,
    this.clipPath,
  });

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    final type = (json['eventType'] ?? json['type'] ?? '').toString();
    final teamName = (json['teamName'] ?? 'team 1').toString();
    final rawStartTime = json['startTime'] ?? json['time'] ?? '';
    final rawEndTime = json['endTime'] ?? '';

    return MatchEvent(
      type: type,
      startTime: rawStartTime.toString(),
      endTime: rawEndTime.toString(),
      title: _eventTitle(teamName, type),
      detail: (json['description'] ?? json['eventName'] ?? json['detail'])?.toString(),
      clipPath: (json['clipFileLocation'] ?? json['clip_path'] ?? json['clipPath'])?.toString(),
    );
  }

  static String _eventTitle(String teamName, String type) {
    final cleanTeam = teamName.trim().isEmpty ? 'team 1' : teamName.trim();
    if (type == 'goal') return '${_titleCase(cleanTeam)} scored';
    if (type == 'foul') return '${_titleCase(cleanTeam)} committed a foul';
    return '${_titleCase(cleanTeam)} ${type.replaceAll('_', ' ')}';
  }

  static String _titleCase(String value) {
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  String get timeRange {
    final start = _formatClock(startTime);
    final end = _formatClock(endTime);
    if (end.isEmpty) return start;
    return '$start - $end';
  }

  static String _formatClock(String raw) {
    if (raw.trim().isEmpty) return '';
    final parts = raw.split(':');
    if (parts.length >= 3) {
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = double.tryParse(parts[2])?.floor() ?? 0;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    final secondsValue = double.tryParse(raw);
    if (secondsValue != null) {
      final totalSeconds = secondsValue.floor();
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return raw;
  }
}

class AIMatchSummary extends StatefulWidget {
  const AIMatchSummary({super.key});

  @override
  State<AIMatchSummary> createState() => _AIMatchSummaryState();
}

class _AIMatchSummaryState extends State<AIMatchSummary> {
  List<MatchEvent> _events = [];
  String _teamAName = 'Team A';
  String _teamBName = 'Team B';
  int _teamAScore = 0;
  int _teamBScore = 0;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadMatchEvents();
    }
  }

  Future<void> _loadMatchEvents() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final dynamic matchId = args?['matchId'];
    if (matchId == null) return;

    final matchData = await ApiService.fetchMatchSummary(matchId.toString());
    if (matchData == null || !mounted) return;

    final eventsRaw = (matchData['events'] as List<dynamic>?) ?? const [];
    final occurByRaw = (matchData['occurBy'] as List<dynamic>?) ?? const [];
    final teamsRaw = (matchData['teams'] as List<dynamic>?) ?? const [];
    final playRaw = (matchData['play'] as List<dynamic>?) ?? const [];

    final teamNameById = <int, String>{};
    for (final item in teamsRaw) {
      if (item is! Map<String, dynamic>) continue;
      final teamId = (item['teamId'] as num?)?.toInt();
      if (teamId != null) {
        teamNameById[teamId] = (item['teamName'] ?? 'team $teamId').toString();
      }
    }

    final playTeamNameById = <int, String>{};
    for (final item in playRaw) {
      if (item is! Map<String, dynamic>) continue;
      final playId = (item['playId'] as num?)?.toInt();
      final teamId = (item['teamId'] as num?)?.toInt();
      if (playId != null && teamId != null) {
        playTeamNameById[playId] = teamNameById[teamId] ?? 'team $teamId';
      }
    }

    final eventById = <dynamic, Map<String, dynamic>>{};
    for (final item in eventsRaw) {
      if (item is Map<String, dynamic>) {
        eventById[item['eventId']] = item;
      }
    }

    final events = <MatchEvent>[];
    for (final item in occurByRaw) {
      if (item is! Map<String, dynamic>) continue;
      final eventObj = eventById[item['eventId']] ?? <String, dynamic>{};
      final playId = (item['playId'] as num?)?.toInt();
      events.add(
        MatchEvent.fromJson({
          ...eventObj,
          ...item,
          'teamName': playTeamNameById[playId] ?? eventObj['teamName'] ?? 'team 1',
        }),
      );
    }

    String teamA = _teamAName;
    String teamB = _teamBName;
    int scoreA = 0;
    int scoreB = 0;

    if (teamsRaw.length >= 2) {
      final firstTeam = teamsRaw[0] as Map<String, dynamic>;
      final secondTeam = teamsRaw[1] as Map<String, dynamic>;
      teamA = (firstTeam['teamName'] ?? 'Team A').toString();
      teamB = (secondTeam['teamName'] ?? 'Team B').toString();
      final firstTeamId = (firstTeam['teamId'] as num?)?.toInt();
      final secondTeamId = (secondTeam['teamId'] as num?)?.toInt();

      for (final row in playRaw) {
        if (row is! Map<String, dynamic>) continue;
        final teamId = (row['teamId'] as num?)?.toInt();
        final score = (row['score'] as num?)?.toInt() ?? 0;
        if (teamId == firstTeamId) scoreA = score;
        if (teamId == secondTeamId) scoreB = score;
      }
    }

    setState(() {
      _events = events;
      _teamAName = teamA;
      _teamBName = teamB;
      _teamAScore = scoreA;
      _teamBScore = scoreB;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildScoreboard(),
                    _buildMatchTimeline(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleButton(
            onPressed: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
          ),
          const Text(
            'AI Match Summary',
            style: TextStyle(fontFamily: 'Lexend', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          _circleButton(
            child: const Icon(Icons.share, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({VoidCallback? onPressed, required Widget child}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: onPressed == null ? Center(child: child) : IconButton(onPressed: onPressed, icon: child),
    );
  }

  Widget _buildScoreboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: _buildTeamColumn(_teamAName, true)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$_teamAScore - $_teamBScore',
                style: const TextStyle(fontFamily: 'Lexend', fontSize: 34, fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(child: _buildTeamColumn(_teamBName, false)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamColumn(String name, bool isHome) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child: Icon(isHome ? Icons.shield_outlined : Icons.shield, size: 30, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Lexend', fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMatchTimeline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'MATCH EVENTS',
              style: TextStyle(fontFamily: 'Lexend', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.grey.shade500),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: _events.isEmpty
                  ? const [Padding(padding: EdgeInsets.all(8), child: Text('No events available yet.'))]
                  : _events.map(_buildEventTile).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(MatchEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: _getEventColor(event.type).withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(_getEventIcon(event.type), color: _getEventColor(event.type), size: 16),
        ),
        title: Text(event.title, style: const TextStyle(fontFamily: 'Lexend', fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text('${event.timeRange} - ${event.type}', style: TextStyle(fontFamily: 'Lexend', fontSize: 12, color: Colors.grey.shade600)),
        children: [
          if ((event.detail ?? '').isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(event.detail!, style: TextStyle(fontFamily: 'Lexend', fontSize: 12, color: Colors.grey.shade800)),
            ),
          if ((event.clipPath ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipVideoPlayer(clipPath: event.clipPath!),
          ],
        ],
      ),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'goal':
        return AppColors.primary;
      case 'card':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'goal':
        return Icons.sports_soccer;
      case 'card':
        return Icons.style_outlined;
      default:
        return Icons.history;
    }
  }
}

class ClipVideoPlayer extends StatefulWidget {
  const ClipVideoPlayer({super.key, required this.clipPath});

  final String clipPath;

  @override
  State<ClipVideoPlayer> createState() => _ClipVideoPlayerState();
}

class _ClipVideoPlayerState extends State<ClipVideoPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(_clipUrl(widget.clipPath)));
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  String _clipUrl(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return _encodeClipUrl('${AppConfig.processingApiBaseUrl}$raw');

    final normalized = raw.replaceAll('\\', '/');
    final parts = normalized.split('/');
    final eventsIndex = parts.lastIndexOf('events');
    if (eventsIndex > 0 && eventsIndex < parts.length - 1) {
      final jobId = parts[eventsIndex - 1];
      final fileName = parts.last;
      return _encodeClipUrl('${AppConfig.processingApiBaseUrl}/api/processing/clips/$jobId/$fileName');
    }
    return raw;
  }

  String _encodeClipUrl(String url) {
    final uri = Uri.parse(url);
    return uri.replace(pathSegments: uri.pathSegments.map(Uri.decodeComponent)).toString();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return _videoFrame(
        child: const Text('Clip preview unavailable', style: TextStyle(fontFamily: 'Lexend', fontSize: 12)),
      );
    }
    if (controller == null) {
      return _videoFrame(
        child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          IconButton.filled(
            onPressed: () {
              setState(() {
                controller.value.isPlaying ? controller.pause() : controller.play();
              });
            },
            icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
          ),
        ],
      ),
    );
  }

  Widget _videoFrame({required Widget child}) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: child,
    );
  }
}
