import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../config/app_config.dart';
import '../theme.dart';

/// Plays one highlight clip served by the processing API.
///
/// Used by the match summary rows, the highlights list and the expanded
/// highlight view.
///
/// Three things used to break playback and are handled here:
///
/// * Every player opened its stream as soon as it was built, so a summary with
///   several clips started several ExoPlayer instances at once and ran out of
///   hardware decoders. The player now loads only when the user taps it.
/// * The play/pause buttons and the seek bar sat in a nested `Stack` that was
///   sized by the play button, not by the video, so the seek bar floated in the
///   middle of the picture and pressing play left that `Stack` with nothing to
///   size it by inside a scrolling list. The controls now fill the video frame
///   exactly (`StackFit.expand` inside the `AspectRatio`).
/// * At the end of a clip "play" did nothing, because the position was already
///   at the end. It now restarts from the beginning.
///
/// Android also refuses plain `http://` video unless cleartext traffic is
/// allowed; see `android:usesCleartextTraffic` in `AndroidManifest.xml`.
class ClipVideoPlayer extends StatefulWidget {
  const ClipVideoPlayer({
    super.key,
    required this.clipPath,
    this.placeholderHeight = 120,
    this.showProgressBar = true,
  });

  final String clipPath;

  /// Height of the idle, loading and failure frames, before the real aspect
  /// ratio is known. The highlights screens want a taller box than the summary
  /// rows.
  final double placeholderHeight;

  final bool showProgressBar;

  @override
  State<ClipVideoPlayer> createState() => _ClipVideoPlayerState();
}

class _ClipVideoPlayerState extends State<ClipVideoPlayer> {
  /// A clip that has not started within this long is reported as unreachable.
  static const _loadTimeout = Duration(seconds: 20);

  VideoPlayerController? _controller;
  bool _loading = false;
  String? _error;

  @override
  void didUpdateWidget(ClipVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clipPath != widget.clipPath) {
      // A different clip: drop the old stream and go back to the tap-to-play
      // frame rather than loading the new one unasked.
      _controller?.dispose();
      _controller = null;
      _loading = false;
      _error = null;
    }
  }

  /// Opens the stream and starts playing. Called from the tap-to-play frame
  /// and from "Try again" after a failure.
  Future<void> _loadAndPlay() async {
    final url = clipUrl(widget.clipPath);
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await controller.initialize().timeout(_loadTimeout);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
      await controller.play();
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Could not play this clip from ${Uri.parse(url).origin}. '
            'Check Server Settings and that the FastAPI server is running.';
      });
    }
  }

  /// Resolves whatever the backend stored into a playable URL.
  ///
  /// The server sends a served path such as
  /// `/api/processing/clips/<jobId>/goal-01.mp4`, but an absolute filesystem
  /// path can also reach us, so the job id and file name are recovered from it.
  static String clipUrl(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) {
      return _encodeClipUrl('${AppConfig.processingApiBaseUrl}$raw');
    }

    final normalized = raw.replaceAll('\\', '/');
    final parts = normalized.split('/');
    for (final marker in const ['clips', 'events']) {
      final index = parts.lastIndexOf(marker);
      if (index >= 0 && index < parts.length - 2) {
        final jobId = parts[index + 1];
        final fileName = parts.last;
        return _encodeClipUrl(
          '${AppConfig.processingApiBaseUrl}/api/processing/clips/$jobId/$fileName',
        );
      }
    }
    return raw;
  }

  static String _encodeClipUrl(String url) {
    final uri = Uri.parse(url);
    return uri
        .replace(pathSegments: uri.pathSegments.map(Uri.decodeComponent))
        .toString();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_error != null) {
      return _frame(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: _loadAndPlay,
                child: const Text(
                  'Try again',
                  style: TextStyle(fontFamily: 'Lexend'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_loading) {
      return _frame(
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }
    if (controller == null) {
      // Idle: nothing is downloaded until the user asks for this clip.
      return Semantics(
        button: true,
        label: 'Play highlight clip',
        child: GestureDetector(
          onTap: _loadAndPlay,
          child: _frame(
            child: const Icon(
              Icons.play_circle_fill,
              size: 56,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    final size = controller.value.size;
    final aspectRatio = size.width > 0 && size.height > 0
        ? size.width / size.height
        : 16 / 9;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          // The video and its controls both take exactly the video's frame.
          fit: StackFit.expand,
          children: [
            VideoPlayer(controller),
            // Rebuilds on every position tick so the button and the seek bar
            // stay in step with playback.
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) => _controls(controller, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(VideoPlayerController controller, VideoPlayerValue value) {
    final ended =
        value.duration > Duration.zero && value.position >= value.duration;

    Future<void> togglePlayback() async {
      if (value.isPlaying) {
        await controller.pause();
      } else {
        // play() at the last frame does nothing; start the clip over.
        if (ended) await controller.seekTo(Duration.zero);
        await controller.play();
      }
    }

    return GestureDetector(
      // A tap anywhere on the picture plays or pauses.
      behavior: HitTestBehavior.opaque,
      onTap: togglePlayback,
      child: Stack(
        children: [
          if (value.isBuffering)
            const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else if (!value.isPlaying)
            Center(
              child: IconButton.filled(
                iconSize: 32,
                tooltip: ended ? 'Replay' : 'Play',
                onPressed: togglePlayback,
                icon: Icon(ended ? Icons.replay : Icons.play_arrow),
              ),
            ),
          if (value.hasError)
            Center(
              child: Text(
                value.errorDescription ?? 'Playback stopped.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          if (widget.showProgressBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black45,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 2),
                      child: Text(
                        '${_clock(value.position)} / ${_clock(value.duration)}',
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      colors: const VideoProgressColors(
                        playedColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _clock(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// The box shown before the video is playing: idle, loading or failed.
  Widget _frame({required Widget child}) {
    return Container(
      height: widget.placeholderHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
