import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Map<String, dynamic>>>? _recentMatchesFuture;

  @override
  void initState() {
    super.initState();
    _recentMatchesFuture = _fetchRecentMatches();
  }

  Future<List<Map<String, dynamic>>> _fetchRecentMatches() async {
    final userId = await SessionService.getUserId();
    return ApiService.fetchRecentMatches(userId: userId);
  }

  void _refreshRecentAnalysis() {
    setState(() => _recentMatchesFuture = _fetchRecentMatches());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _refreshRecentAnalysis(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildQuickActions(context),
                _buildRecentAnalysisSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back',
                style: TextStyle(fontFamily: 'Lexend', fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    TextSpan(text: 'Footy'),
                    TextSpan(text: 'AI', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _roundIcon(Icons.notifications_outlined),
              const SizedBox(width: 12),
              _roundIcon(Icons.person_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Icon(icon, color: AppColors.textPrimary),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontFamily: 'Lexend', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            icon: Icons.cloud_upload_outlined,
            label: 'Upload Match',
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, '/upload').then((_) => _refreshRecentAnalysis()),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            icon: Icons.auto_awesome_outlined,
            label: 'AI Predictions',
            color: Colors.purple,
            onTap: () => Navigator.pushNamed(context, '/predictions').then((_) => _refreshRecentAnalysis()),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(fontFamily: 'Lexend', fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAnalysisSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Analysis',
            style: TextStyle(fontFamily: 'Lexend', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _recentMatchesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final matches = snapshot.data ?? const [];
              if (matches.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No analysis yet',
                      style: TextStyle(fontFamily: 'Lexend', color: Colors.grey.shade500),
                    ),
                  ),
                );
              }

              return Column(
                children: matches.take(5).map((match) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRecentAnalysisCard(context, match),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRecentAnalysisCard(BuildContext context, Map<String, dynamic> match) {
    final matchId = match['matchId'];
    final date = DateTime.tryParse((match['matchDate'] ?? '').toString());
    final subtitle = date == null ? 'Analysis ready' : 'Analysis ready - ${_formatShortDate(date)}';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/summary', arguments: {'matchId': matchId}),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Match #$matchId',
                    style: const TextStyle(fontFamily: 'Lexend', fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontFamily: 'Lexend', fontSize: 12, color: Colors.grey.shade600),
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

  String _formatShortDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute $suffix';
  }
}
