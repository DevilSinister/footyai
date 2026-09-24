import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footy_ai_app/widgets/clip_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// A video platform with no device behind it: every player reports a 10 s
/// 1920x1080 clip, and the calls the widget makes are recorded.
class _FakeVideoPlatform extends VideoPlayerPlatform {
  int created = 0;
  final List<String> calls = [];
  Duration position = Duration.zero;
  final Map<int, StreamController<VideoEvent>> _events = {};

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async => _newPlayer();

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async =>
      _newPlayer();

  int _newPlayer() {
    final id = ++created;
    _events[id] = StreamController<VideoEvent>(
      onListen: () => _events[id]!.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 10),
          size: const Size(1920, 1080),
        ),
      ),
    );
    return id;
  }

  void complete(int playerId) {
    position = const Duration(seconds: 10);
    _events[playerId]!.add(VideoEvent(eventType: VideoEventType.completed));
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Widget buildView(int playerId) => const ColoredBox(color: Colors.black);

  @override
  Future<void> play(int playerId) async => calls.add('play');

  @override
  Future<void> pause(int playerId) async => calls.add('pause');

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    calls.add('seek ${position.inSeconds}');
    this.position = position;
  }

  @override
  Future<Duration> getPosition(int playerId) async => position;

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
}

void main() {
  late _FakeVideoPlatform platform;

  setUp(() {
    platform = _FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
  });

  // The summary and highlights screens put the player inside a scrolling
  // list, which gives it unbounded height - the case the old layout broke in.
  Widget inList() => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 360,
        child: ListView(
          children: const [
            ClipVideoPlayer(clipPath: 'http://test/goal-01.mp4'),
          ],
        ),
      ),
    ),
  );

  testWidgets('does not open the stream until tapped', (tester) async {
    await tester.pumpWidget(inList());
    expect(platform.created, 0);
    expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
  });

  testWidgets('plays inside a list with the seek bar on the video', (
    tester,
  ) async {
    await tester.pumpWidget(inList());
    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(platform.created, 1);
    expect(platform.calls, contains('play'));

    // 360 px wide at 16:9, and the seek bar sits on the bottom edge of the
    // picture, not in the middle of it.
    final video = tester.getRect(find.byType(AspectRatio));
    expect(video.height, closeTo(202.5, 0.5));
    final bar = tester.getRect(find.byType(VideoProgressIndicator));
    expect(bar.bottom, closeTo(video.bottom, 1.0));

    await tester.pumpWidget(const SizedBox()); // disposes the controller
  });

  testWidgets('replays from the start after the clip ends', (tester) async {
    await tester.pumpWidget(inList());
    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pump();
    await tester.pump();

    platform.complete(1);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byIcon(Icons.replay), findsOneWidget);

    platform.calls.clear();
    await tester.tap(find.byIcon(Icons.replay));
    await tester.pump();
    expect(platform.calls, ['seek 0', 'play']);

    await tester.pumpWidget(const SizedBox());
  });
}
