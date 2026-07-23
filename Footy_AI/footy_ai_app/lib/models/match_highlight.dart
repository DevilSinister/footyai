import 'package:flutter/material.dart';

class MatchStat {
  final IconData icon;
  final String label;

  const MatchStat({required this.icon, required this.label});
}

class RelatedHighlight {
  final String time;
  final String title;
  final String subtitle;

  const RelatedHighlight({
    required this.time,
    required this.title,
    required this.subtitle,
  });
}

class MatchHighlight {
  final String time;
  final String title;
  final String player;
  final String type;
  final String? team;
  final bool isAI;
  final String? probability;
  final String description;
  final int scoreHome;
  final int scoreAway;
  final String teamHome;
  final String teamAway;
  final List<MatchStat> stats;
  final List<RelatedHighlight> relatedHighlights;

  MatchHighlight({
    required this.time,
    required this.title,
    required this.player,
    required this.type,
    this.team,
    this.isAI = false,
    this.probability,
    required this.description,
    this.scoreHome = 0,
    this.scoreAway = 0,
    this.teamHome = '',
    this.teamAway = '',
    this.stats = const [],
    this.relatedHighlights = const [],
  });

  factory MatchHighlight.fromJson(Map<String, dynamic> json) {
    return MatchHighlight(
      time: json['time'] ?? '',
      title: json['title'] ?? '',
      player: json['player'] ?? '',
      type: json['type'] ?? '',
      team: json['team'],
      isAI: json['isAI'] ?? false,
      probability: json['probability'],
      description: json['description'] ?? '',
      scoreHome: json['scoreHome'] ?? 0,
      scoreAway: json['scoreAway'] ?? 0,
      teamHome: json['teamHome'] ?? '',
      teamAway: json['teamAway'] ?? '',
      stats: (json['stats'] as List<dynamic>?)
              ?.map((s) => MatchStat(icon: _getIconFromString(s['icon']), label: s['label'] ?? ''))
              .toList() ??
          [],
      relatedHighlights: (json['relatedHighlights'] as List<dynamic>?)
              ?.map((r) => RelatedHighlight(
                    time: r['time'] ?? '',
                    title: r['title'] ?? '',
                    subtitle: r['subtitle'] ?? '',
                  ))
              .toList() ??
          [],
    );
  }
}

IconData _getIconFromString(String iconName) {
  switch (iconName) {
    case 'sports_soccer':
      return Icons.sports_soccer;
    case 'style':
      return Icons.style_outlined;
    case 'pan_tool':
      return Icons.pan_tool_outlined;
    default:
      return Icons.sports_soccer;
  }
}
