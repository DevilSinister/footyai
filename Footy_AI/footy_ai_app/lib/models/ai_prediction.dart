import 'package:flutter/material.dart';

class AIPrediction {
  final String matchId;
  final String homeTeam;
  final String awayTeam;
  final String homeLogo;
  final String awayLogo;
  final double homeWinProb;
  final double drawProb;
  final double awayWinProb;
  final String tacticalInsight;
  final String league;
  final DateTime matchTime;

  AIPrediction({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeLogo,
    required this.awayLogo,
    required this.homeWinProb,
    required this.drawProb,
    required this.awayWinProb,
    required this.tacticalInsight,
    required this.league,
    required this.matchTime,
  });

  factory AIPrediction.fromJson(Map<String, dynamic> json) {
    return AIPrediction(
      matchId: json['matchId'] ?? '',
      homeTeam: json['homeTeam'] ?? '',
      awayTeam: json['awayTeam'] ?? '',
      homeLogo: json['homeLogo'] ?? '',
      awayLogo: json['awayLogo'] ?? '',
      homeWinProb: (json['homeWinProb'] ?? 0.0).toDouble(),
      drawProb: (json['drawProb'] ?? 0.0).toDouble(),
      awayWinProb: (json['awayWinProb'] ?? 0.0).toDouble(),
      tacticalInsight: json['tacticalInsight'] ?? '',
      league: json['league'] ?? '',
      matchTime: json['matchTime'] != null 
          ? DateTime.parse(json['matchTime']) 
          : DateTime.now(),
    );
  }
}
