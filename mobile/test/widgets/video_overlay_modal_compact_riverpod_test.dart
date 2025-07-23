// ABOUTME: TDD tests for video_overlay_modal_compact Riverpod conversion
// ABOUTME: Tests widget builds with Riverpod providers and VideoManager access through ref.read()

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openvine/models/video_event.dart';
import 'package:openvine/providers/video_manager_providers.dart';
import 'package:openvine/widgets/video_overlay_modal_compact.dart';

// Mock classes
class MockVideoManager extends Mock implements VideoManager {}
class MockVideoEvent extends Mock implements VideoEvent {}

void main() {
  group('VideoOverlayModalCompact Riverpod Migration Tests', () {
    late MockVideoManager mockVideoManager;
    late List<VideoEvent> testVideoList;
    late VideoEvent testStartingVideo;

    setUp(() {
      mockVideoManager = MockVideoManager();
      
      // Create test video events
      testStartingVideo = MockVideoEvent();
      when(() => testStartingVideo.id).thenReturn('test-video-1');
      when(() => testStartingVideo.content).thenReturn('Test Video 1');
      when(() => testStartingVideo.pubkey).thenReturn('test-pubkey-1');
      when(() => testStartingVideo.timestamp).thenReturn(DateTime.now());
      when(() => testStartingVideo.hasVideo).thenReturn(true);
      when(() => testStartingVideo.videoUrl).thenReturn('https://example.com/video1.mp4');
      when(() => testStartingVideo.thumbnailUrl).thenReturn('https://example.com/thumb1.jpg');
      when(() => testStartingVideo.title).thenReturn('Test Video 1');
      when(() => testStartingVideo.hashtags).thenReturn(<String>[]);
      when(() => testStartingVideo.createdAt).thenReturn(1000);
      
      final testVideo2 = MockVideoEvent();
      when(() => testVideo2.id).thenReturn('test-video-2');
      when(() => testVideo2.content).thenReturn('Test Video 2');
      when(() => testVideo2.pubkey).thenReturn('test-pubkey-2');
      when(() => testVideo2.timestamp).thenReturn(DateTime.now());
      when(() => testVideo2.hasVideo).thenReturn(true);
      when(() => testVideo2.videoUrl).thenReturn('https://example.com/video2.mp4');
      when(() => testVideo2.thumbnailUrl).thenReturn('https://example.com/thumb2.jpg');
      when(() => testVideo2.title).thenReturn('Test Video 2');
      when(() => testVideo2.hashtags).thenReturn(<String>[]);
      when(() => testVideo2.createdAt).thenReturn(2000);
      
      testVideoList = [testStartingVideo, testVideo2];

      // Setup mock video manager behavior
      when(() => mockVideoManager.addVideoEvent(any())).thenReturn(null);
      when(() => mockVideoManager.preloadVideo(any())).thenAnswer((_) async {});
      when(() => mockVideoManager.pauseAllVideos()).thenReturn(null);
    });

    testWidgets('should build with Riverpod providers (NOW PASSES)', (tester) async {
      // This test should NOW PASS because widget has been converted to ConsumerStatefulWidget
      // and uses ref.read() instead of Provider.of()
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override VideoManager with mock
            videoManagerProvider.overrideWith(() => mockVideoManager),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VideoOverlayModalCompact(
                startingVideo: testStartingVideo,
                videoList: testVideoList,
                contextTitle: 'Test Context',
                startingIndex: 0,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      
      // This should fail because widget still uses Provider.of() instead of ref.read()
      expect(find.byType(VideoOverlayModalCompact), findsOneWidget);
    });

    testWidgets('should access VideoManager through ref.read() (NOW PASSES after migration)', (tester) async {
      // This test should PASS because widget now uses ref.read(videoManagerProvider.notifier)
      
      bool videoManagerCalled = false;
      when(() => mockVideoManager.addVideoEvent(any())).thenAnswer((_) async {
        videoManagerCalled = true;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            videoManagerProvider.overrideWith(() => mockVideoManager),
          ],
          child: MaterialApp(
            home: VideoOverlayModalCompact(
              startingVideo: testStartingVideo,
              videoList: testVideoList,
              contextTitle: 'Test Context',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(); // Allow async initialization

      // This should fail because widget doesn't use Riverpod provider yet
      expect(videoManagerCalled, isTrue);
    });

    testWidgets('should handle animation and gesture behavior with Riverpod (SHOULD FAIL initially)', (tester) async {
      // Test that animations and gestures work with Riverpod providers
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            videoManagerProvider.overrideWith(() => mockVideoManager),
          ],
          child: MaterialApp(
            home: VideoOverlayModalCompact(
              startingVideo: testStartingVideo,
              videoList: testVideoList,
              contextTitle: 'Test Context',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350)); // Animation duration

      // Test swipe down gesture to dismiss
      await tester.drag(find.byType(PageView), const Offset(0, 500));
      await tester.pumpAndSettle();

      // Should be able to dismiss properly with Riverpod
      expect(find.byType(VideoOverlayModalCompact), findsOneWidget);
    });

    testWidgets('should handle compact modal specific behavior (SHOULD FAIL initially)', (tester) async {
      // Test compact modal header, drag handle, and page navigation
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            videoManagerProvider.overrideWith(() => mockVideoManager),
          ],
          child: MaterialApp(
            home: VideoOverlayModalCompact(
              startingVideo: testStartingVideo,
              videoList: testVideoList,
              contextTitle: 'Test Videos',
              startingIndex: 1,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Should show context title
      expect(find.text('Test Videos'), findsOneWidget);
      
      // Should show current position
      expect(find.text('2 of 2'), findsOneWidget);
      
      // Should have drag handle
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      
      // Should have PageView for video content
      expect(find.byType(PageView), findsOneWidget);
    });

    test('showCompactVideoOverlay helper function should work with Riverpod context', () {
      // Test the helper function that shows the modal
      // This should fail if context doesn't have proper Riverpod providers
      
      // Create a mock context that should have Riverpod providers
      final context = MockBuildContext();
      
      // This should not throw an exception once converted to Riverpod
      expect(() {
        showCompactVideoOverlay(
          context: context,
          startingVideo: testStartingVideo,
          videoList: testVideoList,
          contextTitle: 'Test Context',
          startingIndex: 0,
        );
      }, returnsNormally);
    });
  });
}

// Mock BuildContext for testing
class MockBuildContext extends Mock implements BuildContext {}