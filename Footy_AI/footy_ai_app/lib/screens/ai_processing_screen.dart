import 'dart:async';
import 'package:flutter/material.dart';
import '../services/processing_service.dart';
import '../theme.dart';

class AIProcessingScreen extends StatefulWidget {
  const AIProcessingScreen({super.key});

  @override
  State<AIProcessingScreen> createState() => _AIProcessingScreenState();
}

class _AIProcessingScreenState extends State<AIProcessingScreen> {
  Timer? _pollTimer;
  Timer? _jokeTimer;
  String _status = 'queued';
  String _stage = 'Queued';
  int _progressPercent = 0;
  String? _jobId;
  String? _error;
  int _jokeIndex = 0;

  static const List<String> _jokes = [
    'Our AI is checking if the ball is faster than your internet.',
    'VAR is still faster than this model on CPU, but we are trying.',
    'Counting every touch. Even the accidental ones.',
    'No players were benched during this computation.',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _jobId ??= args?['jobId'] as String?;

    if (_jobId != null && _pollTimer == null) {
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
      _jokeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        setState(() => _jokeIndex = (_jokeIndex + 1) % _jokes.length);
      });
      _poll();
    }
  }

  int _fallbackProgress(String status) {
    switch (status) {
      case 'queued':
        return 0;
      case 'downloading':
        return 5;
      case 'uploaded':
        return 10;
      case 'processing':
        return _progressPercent < 12 ? 12 : _progressPercent;
      case 'completed':
        return 100;
      default:
        return _progressPercent;
    }
  }

  Future<void> _poll() async {
    if (_jobId == null) return;
    final statusData = await ProcessingService.getStatus(_jobId!);
    if (!mounted || statusData == null) return;

    final status = (statusData['status'] ?? '').toString();
    final stage = (statusData['stage'] ?? _stage).toString();
    final reportedProgress = (statusData['progress_percent'] as num?)?.toInt();
    final nextProgress = reportedProgress ?? _fallbackProgress(status);

    setState(() {
      _status = status;
      _stage = stage;
      _progressPercent = nextProgress.clamp(0, 100);
      _error = statusData['error']?.toString();
    });

    if (status == 'completed') {
      final resultData = await ProcessingService.getResult(_jobId!);
      final result = resultData?['result'] as Map<String, dynamic>?;
      final dbResponse = result?['db_response'] as Map<String, dynamic>?;
      final matchId = dbResponse?['matchId'];
      _pollTimer?.cancel();
      _jokeTimer?.cancel();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/summary', arguments: {'matchId': matchId});
    } else if (status == 'failed') {
      _pollTimer?.cancel();
      _jokeTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _jokeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressValue = _progressPercent / 100.0;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('AI Processing'),
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics_outlined, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Match Analysis In Progress',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Job ID: ${_jobId ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Text('Status: $_status', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Stage: $_stage'),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    minHeight: 10,
                    value: progressValue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('$_progressPercent%', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _jokes[_jokeIndex],
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
