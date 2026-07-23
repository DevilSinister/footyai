import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../theme.dart';

class AIPredictionsScreen extends StatefulWidget {
  const AIPredictionsScreen({super.key});

  @override
  State<AIPredictionsScreen> createState() => _AIPredictionsScreenState();
}

class _AIPredictionsScreenState extends State<AIPredictionsScreen> {
  Future<List<Map<String, dynamic>>>? _matchesFuture;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) => _refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _matchesFuture = _loadMatches();
    });
  }

  Future<List<Map<String, dynamic>>> _loadMatches() async {
    final userId = await SessionService.getUserId();
    return ApiService.fetchRecentMatches(userId: userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'AI Predictions',
          style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return _buildRetry('Failed to load matches');
          }
          final matches = snapshot.data ?? const [];
          if (matches.isEmpty) {
            return _buildRetry('No uploaded matches found');
          }

          final grouped = _groupByDate(matches);
          final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dateKeys.length,
              itemBuilder: (context, i) {
                final dateKey = dateKeys[i];
                final items = grouped[dateKey]!;
                return _buildDateSection(dateKey, items);
              },
            ),
          );
        },
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(List<Map<String, dynamic>> matches) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final m in matches) {
      final raw = (m['matchDate'] ?? '').toString();
      final dt = DateTime.tryParse(raw);
      final key = dt == null ? 'Unknown Date' : _formatDateHeader(dt);
      grouped.putIfAbsent(key, () => []).add(m);
    }
    return grouped;
  }

  Widget _buildDateSection(String dateKey, List<Map<String, dynamic>> matches) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              dateKey,
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ...matches.map(_buildMatchTile),
        ],
      ),
    );
  }

  Widget _buildMatchTile(Map<String, dynamic> match) {
    final matchId = match['matchId'];
    final location = (match['location'] ?? 'Unknown').toString();
    final matchDateRaw = (match['matchDate'] ?? '').toString();
    final date = DateTime.tryParse(matchDateRaw);
    final dateText = date == null ? matchDateRaw : _formatShortDate(date);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/summary',
          arguments: {'matchId': matchId},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sports_soccer, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Match #$matchId',
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    location,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateText,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildRetry(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, style: const TextStyle(fontFamily: 'Lexend', fontSize: 14)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _refresh,
            child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDateHeader(date)} • $hour:$minute $suffix';
  }
}
