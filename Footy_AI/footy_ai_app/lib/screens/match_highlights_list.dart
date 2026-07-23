import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/match_highlight.dart';
import '../services/api_service.dart';

class MatchHighlightsList extends StatefulWidget {
  const MatchHighlightsList({super.key});

  @override
  State<MatchHighlightsList> createState() => _MatchHighlightsListState();
}

class _MatchHighlightsListState extends State<MatchHighlightsList> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Goals', 'Cards', 'Saves'];

  List<MatchHighlight> _highlights = [];

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    final highlights = await ApiService.fetchHighlights();
    if (mounted) {
      setState(() {
        _highlights = highlights;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTeamLogo('RMA', true),
              const SizedBox(width: 24),
              Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        '3',
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
                      const Text(
                        '2',
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
              _buildTeamLogo('BAR', false),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'May 24, 2024 • Santiago Bernabéu',
            style: TextStyle(
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
              const Text(
                'AI-POWERED ANALYSIS READY',
                style: TextStyle(
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 80),
        ..._highlights.map((highlight) => _buildHighlightCard(highlight)),
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
          if (highlight.description != null) ...[
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
                    highlight.description!,
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
}