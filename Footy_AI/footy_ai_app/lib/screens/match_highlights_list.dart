import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/match_highlight.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class MatchHighlightsList extends StatefulWidget {
  const MatchHighlightsList({super.key});

  @override
  State<MatchHighlightsList> createState() => _MatchHighlightsListState();
}

class _MatchHighlightsListState extends State<MatchHighlightsList> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Goals', 'Cards', 'Saves'];

  List<MatchHighlight> _highlights = [];
  _MatchSummaryInfo _summaryInfo = const _MatchSummaryInfo(
    homeTeam: 'Team A',
    awayTeam: 'Team B',
    homeScore: 0,
    awayScore: 0,
    dateLabel: 'Latest processed match',
    location: 'Unknown location',
    statusLabel: 'NO EVENTS FOUND',
  );
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final userId = await SessionService.getUserId();
      final summary = await ApiService.fetchLatestMatchSummary(userId: userId);
      final highlights = await ApiService.fetchHighlights(userId: userId);

      if (!mounted) return;
      setState(() {
        _summaryInfo = summary == null
            ? const _MatchSummaryInfo(
                homeTeam: 'Team A',
                awayTeam: 'Team B',
                homeScore: 0,
                awayScore: 0,
                dateLabel: 'Latest processed match',
                location: 'Unknown location',
                statusLabel: 'NO EVENTS FOUND',
              )
            : _MatchSummaryInfo.fromSummary(summary);
        _highlights = highlights;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Failed to load live match data',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _loadContent();
                    },
                    child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildMatchSummary(),
                _buildFilterChips(),
                Expanded(child: _buildHighlightsList()),
              ],
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildFAB(),
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
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/upload'),
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 28,
          ),
          const Text(
            'Match Highlights',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchSummary() {
    final info = _summaryInfo;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTeamLogo(info.homeTeam, true),
              const SizedBox(width: 24),
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${info.homeScore}',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '-',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${info.awayScore}',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FULL TIME',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              _buildTeamLogo(info.awayTeam, false),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${info.dateLabel} • ${info.location}',
            style: const TextStyle(
              fontFamily: 'Lexend',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                info.statusLabel,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String team, bool isHome) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
              ),
            ],
          ),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isHome ? Icons.shield_outlined : Icons.shield,
              size: 32,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          team,
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade200,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFilterIcon(filter),
                      size: 18,
                      color: isSelected
                          ? AppColors.textPrimary
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filter == 'All' ? 'All Moments' : filter,
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.textPrimary
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Goals':
        return Icons.sports_soccer;
      case 'Cards':
        return Icons.style_outlined;
      case 'Saves':
        return Icons.pan_tool_outlined;
      default:
        return Icons.list;
    }
  }

  Widget _buildHighlightsList() {
    final highlights = _filteredHighlights;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 80),
        if (highlights.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No live highlights found yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lexend',
                color: Colors.grey.shade600,
              ),
            ),
          )
        else
          ...highlights.map((highlight) => _buildHighlightCard(highlight)),
      ],
    );
  }

  Widget _buildHighlightCard(MatchHighlight highlight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: AppColors.white,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        iconColor: Colors.grey,
        collapsedIconColor: Colors.grey,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getHighlightColor(highlight.type).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getHighlightIcon(highlight.type),
                color: _getHighlightColor(highlight.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${highlight.type} – ${highlight.time}',
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${highlight.player} (${highlight.team})',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          if (highlight.description.isNotEmpty) ...[
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.shade400,
                          Colors.grey.shade500,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: AppColors.textPrimary,
                      size: 32,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '0:12',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            '0:35',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(
                    color: AppColors.primary,
                    width: 4,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'AI SUMMARY',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    highlight.description,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 48,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ],
        onExpansionChanged: (expanded) {
          if (expanded) {
            Navigator.pushNamed(context, '/expanded', arguments: highlight);
          }
        },
      ),
    );
  }

  Color _getHighlightColor(String type) {
    switch (type) {
      case 'Goal':
        return AppColors.primary;
      case 'Card':
        return Colors.amber;
      case 'Save':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  IconData _getHighlightIcon(String type) {
    switch (type) {
      case 'Goal':
        return Icons.sports_soccer;
      case 'Card':
        return Icons.style_outlined;
      case 'Save':
        return Icons.pan_tool_outlined;
      default:
        return Icons.sports_soccer;
    }
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle,
              color: AppColors.white,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'WATCH FULL HIGHLIGHT REEL',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '4:20',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MatchHighlight> get _filteredHighlights {
    if (_selectedFilter == 'All') {
      return _highlights;
    }

    final expected = switch (_selectedFilter) {
      'Goals' => 'goal',
      'Cards' => 'card',
      'Saves' => 'save',
      _ => '',
    };

    return _highlights.where((highlight) => highlight.type.toLowerCase() == expected).toList();
  }
}

class _MatchSummaryInfo {
  const _MatchSummaryInfo({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.dateLabel,
    required this.location,
    required this.statusLabel,
  });

  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String dateLabel;
  final String location;
  final String statusLabel;

  factory _MatchSummaryInfo.fromSummary(Map<String, dynamic> summary) {
    final match = summary['match'] is Map<String, dynamic>
        ? summary['match'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final teams = (summary['teams'] as List<dynamic>?) ?? const [];
    final play = (summary['play'] as List<dynamic>?) ?? const [];
    final scoreboard = _scoreboardFromSummary(teams, play);
    final matchDateRaw = (match['mDate'] ?? match['matchDate'] ?? '').toString();
    final matchDate = DateTime.tryParse(matchDateRaw);
    final location = _readString(match, ['mLocation', 'location']) ?? 'Unknown location';
    final eventCount = (summary['events'] as List<dynamic>?)?.length ?? 0;
    final statusLabel = eventCount > 0 ? 'LIVE DATA LOADED' : 'NO EVENTS FOUND';

    return _MatchSummaryInfo(
      homeTeam: scoreboard['homeTeam'] as String,
      awayTeam: scoreboard['awayTeam'] as String,
      homeScore: scoreboard['homeScore'] as int,
      awayScore: scoreboard['awayScore'] as int,
      dateLabel: matchDate == null ? 'Latest processed match' : _formatDate(matchDate),
      location: location,
      statusLabel: statusLabel,
    );
  }

  static Map<String, Object> _scoreboardFromSummary(
    List<dynamic> teams,
    List<dynamic> play,
  ) {
    String homeTeam = 'Team A';
    String awayTeam = 'Team B';
    int homeTeamId = -1;
    int awayTeamId = -1;
    int homeScore = 0;
    int awayScore = 0;

    if (teams.isNotEmpty && teams.first is Map<String, dynamic>) {
      final firstTeam = teams.first as Map<String, dynamic>;
      homeTeam = _readString(firstTeam, ['teamName', 'tName', 'name']) ?? homeTeam;
      homeTeamId = _readInt(firstTeam, ['teamId', 'tId', 'id']) ?? homeTeamId;
    }

    if (teams.length > 1 && teams[1] is Map<String, dynamic>) {
      final secondTeam = teams[1] as Map<String, dynamic>;
      awayTeam = _readString(secondTeam, ['teamName', 'tName', 'name']) ?? awayTeam;
      awayTeamId = _readInt(secondTeam, ['teamId', 'tId', 'id']) ?? awayTeamId;
    }

    for (final row in play) {
      if (row is! Map<String, dynamic>) continue;
      final teamId = _readInt(row, ['teamId', 'tID', 'tId']);
      final score = _readInt(row, ['score']) ?? 0;
      if (teamId != null && teamId == homeTeamId) homeScore = score;
      if (teamId != null && teamId == awayTeamId) awayScore = score;
    }

    return {
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeScore': homeScore,
      'awayScore': awayScore,
    };
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

  static String? _readString(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value == null) continue;
      final text = value.toString();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
