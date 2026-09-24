import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/processing_service.dart';
import '../services/session_service.dart';
import '../theme.dart';

class AIVideoUpload extends StatefulWidget {
  const AIVideoUpload({super.key});

  @override
  State<AIVideoUpload> createState() => _AIVideoUploadState();
}

class _AIVideoUploadState extends State<AIVideoUpload> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedVideo;
  bool _isSubmitting = false;
  double _uploadProgress = 0;

  Future<void> _pickVideo() async {
    try {
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (!mounted || video == null) return;
      setState(() => _selectedVideo = video);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open the video library: $error')),
      );
    }
  }

  Future<void> _submitFile() async {
    final video = _selectedVideo;
    if (video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a match video first.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0;
    });
    final userId = await SessionService.getUserId();
    final jobId = await ProcessingService.submitVideoFile(
      filePath: video.path,
      userId: userId,
      onProgress: (progress) {
        if (mounted) {
          setState(() => _uploadProgress = progress.clamp(0, 1).toDouble());
        }
      },
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (jobId == null || jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed. ${ProcessingService.lastError ?? 'Check the server address and try again.'}',
          ),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/processing', arguments: {'jobId': jobId});
  }

  @override
  Widget build(BuildContext context) {
    final videoName = _selectedVideo?.name ?? 'No video selected';
    final progressText = _isSubmitting
        ? '${(_uploadProgress * 100).round()}% uploaded'
        : _selectedVideo == null
        ? 'Choose an MP4, MOV, AVI, or MKV file'
        : 'Ready to find the two kits';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('New Analysis'),
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
                const Text(
                  'Add your match video',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Footy AI finds two representative players first. You will name the teams from those images before analysis begins.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  button: true,
                  label: 'Select a match video',
                  child: InkWell(
                    onTap: _isSubmitting ? null : _pickVideo,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.55),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.video_library_outlined,
                            color: AppColors.primary,
                            size: 48,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            videoName,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            progressText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isSubmitting) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: _uploadProgress),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _pickVideo,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Select video'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitFile,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isSubmitting ? 'Uploading…' : 'Detect the teams',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
