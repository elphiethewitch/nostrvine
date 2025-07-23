// ABOUTME: Simple failing test to verify VideoOverlayModal needs Riverpod migration
// ABOUTME: Tests that current implementation fails with Riverpod-only providers

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openvine/models/video_event.dart';
import 'package:openvine/widgets/video_overlay_modal.dart';

void main() {
  group('VideoOverlayModal TDD Baseline', () {
    testWidgets('should build successfully with Riverpod providers', (WidgetTester tester) async {
      // This test should pass because the widget now uses ref.read() instead of Provider.of() 
      // and we have ProviderScope with proper providers
      
      final testVideo = VideoEvent(
        id: 'test-video',
        pubkey: 'test-pubkey',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unix timestamp in seconds
        content: 'Test video',
        timestamp: DateTime.now(),
      );

      // Arrange - Only ProviderScope, no Provider ancestor
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: VideoOverlayModal(
              startingVideo: testVideo,
              videoList: [testVideo],
              contextTitle: 'Test Context',
            ),
          ),
        ),
      );

      // This should pass because VideoOverlayModal uses ref.read(videoManagerProvider.notifier)
      await tester.pumpAndSettle();
      
      expect(find.byType(VideoOverlayModal), findsOneWidget);
      expect(find.text('Test Context'), findsOneWidget);
    });
  });
}