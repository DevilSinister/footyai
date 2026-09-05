import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/processing_service.dart';
import '../theme.dart';

class AIProcessingScreen extends StatefulWidget {
  const AIProcessingScreen({super.key});

  @override
  State<AIProcessingScreen> createState() => _AIProcessingScreenState();
}

class _AIProcessingScreenState extends State<AIProcessingScreen> {
  Timer? _pollTimer;
  String _status = 'queued';
  String _stage = 'Preparing upload';
  int _progressPercent = 0;
  String? _jobId;
  String? _error;
  List<Map<String, dynamic>> _teamCandidates = const [];
  final _teamOneController = TextEditingController();
  final _teamTwoController = TextEditingController();
  bool _isConfirming = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _jobId ??= args?['jobId'] as String?;
    if (_jobId != null && _pollTimer == null) {
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
      _poll();
    }
  }

  Future<void> _poll() async {
    final jobId = _jobId;
    if (jobId == null || _isConfirming) return;
    final statusData = await ProcessingService.getStatus(jobId);
    if (!mounted) return;
    if (statusData == null) {
      setState(() => _error = ProcessingService.lastError ?? 'Unable to reach the processing server.');
      return;
    }

    final status = (statusData['status'] ?? '').toString();
    final candidates = (statusData['team_candidates'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    setState(() {
      _status = status;
      _stage = (statusData['stage'] ?? _stage).toString();
      _progressPercent = ((statusData['progress_percent'] as num?)?.toInt() ??
              _progressPercent)
          .clamp(0, 100)
          .toInt();
      _error = statusData['error']?.toString();
      _teamCandidates = candidates;
    });

    if (status == 'awaiting_team_confirmation' || status == 'failed') {
      _pollTimer?.cancel();
      return;
    }
    if (status == 'completed') {
      _pollTimer?.cancel();
      final resultData = await ProcessingService.getResult(jobId);
      if (!mounted) return;
      final result = resultData?['result'] as Map<String, dynamic>?;
      final dbResponse = result?['db_response'] as Map<String, dynamic>?;
      final matchId = dbResponse?['matchId'] ?? result?['match_id'];
      Navigator.pushReplacementNamed(context, '/summary', arguments: {'matchId': matchId});
    }
  }

  Future<void> _confirmTeams() async {
    final first = _teamOneController.text.trim();
    final second = _teamTwoController.text.trim();
    if (first.isEmpty || second.isEmpty) {
      setState(() => _error = 'Enter a name for both detected teams.');
      return;
    }
    if (first.toLowerCase() == second.toLowerCase()) {
      setState(() => _error = 'Enter two different team names.');
      return;
    }
    final jobId = _jobId;
    if (jobId == null) return;
    setState(() {
      _isConfirming = true;
      _error = null;
    });
    final confirmed = await ProcessingService.confirmTeams(
      jobId: jobId,
      team1Name: first,
      team2Name: second,
    );
    if (!mounted) return;
    setState(() => _isConfirming = false);
    if (!confirmed) {
      setState(() => _error = ProcessingService.lastError ?? 'Unable to confirm the teams.');
      return;
    }
    setState(() {
      _status = 'queued';
      _stage = 'Team names confirmed';
      _progressPercent = 14;
    });
    _pollTimer ??= Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    _poll();
  }

  String _imageUrl(Map<String, dynamic> candidate) {
    final path = candidate['sample_image']?.toString() ?? '';
    return path.startsWith('http') ? path : '${AppConfig.processingApiBaseUrl}$path';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _teamOneController.dispose();
    _teamTwoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waitingForNames = _status == 'awaiting_team_confirmation';
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(waitingForNames ? 'Name the teams' : 'Match analysis'),
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  waitingForNames ? 'Which team is each kit?' : _stage,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  waitingForNames
                      ? 'Use the player images below to name the two teams. We use the detected kit colors automatically.'
                      : 'Your video is being analyzed. This page will update as each stage completes.',
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
                ),
                const SizedBox(height: 24),
                if (!waitingForNames) ...[
                  LinearProgressIndicator(value: _progressPercent / 100),
                  const SizedBox(height: 10),
                  Text('$_progressPercent% · $_status', style: const TextStyle(fontWeight: FontWeight.w700)),
                ] else ...[
                  _candidateInput(0, _teamOneController, 'Team 1'),
                  const SizedBox(height: 16),
                  _candidateInput(1, _teamTwoController, 'Team 2'),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isConfirming ? null : _confirmTeams,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(_isConfirming ? 'Confirming…' : 'Confirm teams and start analysis'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  Text(_error!, style: const TextStyle(color: Colors.red, height: 1.4)),
                  if (_status == 'failed')
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Choose another video'),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _candidateInput(int index, TextEditingController controller, String fallbackLabel) {
    final candidate = index < _teamCandidates.length ? _teamCandidates[index] : null;
    final label = candidate?['label']?.toString() ?? fallbackLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (candidate != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                _imageUrl(candidate),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Colors.white,
                  child: Center(child: Icon(Icons.person_outline, size: 44)),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLength: 100,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: '$label name',
            hintText: 'e.g. Liverpool',
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
