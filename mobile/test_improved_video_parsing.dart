// ABOUTME: Test the improved video URL parsing with various edge cases
// ABOUTME: Run with: dart test_improved_video_parsing.dart

import 'package:nostr_sdk/event.dart';
import 'package:openvine/utils/unified_logger.dart';

import 'lib/models/video_event.dart';

void main() {
  Log.debug('🚀 Testing improved video URL parsing...\n');
  
  // Test case 1: URL in content (no tags)
  testUrlInContent();
  
  // Test case 2: URL in unknown tag
  testUrlInUnknownTag();
  
  // Test case 3: Broken apt.openvine.co URL replacement
  testBrokenUrlReplacement();
  
  // Test case 4: Multiple URL sources (priority handling)
  testMultipleUrlSources();
  
  Log.debug('\n✅ All tests completed!');
}

void testUrlInContent() {
  Log.debug('=== Test 1: URL in content (no tags) ===');
  
  final event = Event(
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    22,
    [],
    'Check out this video: https://blossom.primal.net/test.mp4',
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
  
  try {
    final videoEvent = VideoEvent.fromNostrEvent(event);
    Log.debug('Result: hasVideo=${videoEvent.hasVideo}, videoUrl=${videoEvent.videoUrl}');
    
    if (videoEvent.hasVideo && videoEvent.videoUrl == 'https://blossom.primal.net/test.mp4') {
      Log.debug('✅ PASS: URL extracted from content');
    } else {
      Log.debug('❌ FAIL: URL not extracted from content');
    }
  } catch (e) {
    Log.debug('❌ ERROR: $e');
  }
  Log.debug('');
}

void testUrlInUnknownTag() {
  Log.debug('=== Test 2: URL in unknown tag ===');
  
  final event = Event(
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    22,
    [['custom', 'https://nostr.build/test.mp4']],
    'Video with URL in custom tag',
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
  
  try {
    final videoEvent = VideoEvent.fromNostrEvent(event);
    Log.debug('Result: hasVideo=${videoEvent.hasVideo}, videoUrl=${videoEvent.videoUrl}');
    
    if (videoEvent.hasVideo && videoEvent.videoUrl == 'https://nostr.build/test.mp4') {
      Log.debug('✅ PASS: URL extracted from unknown tag');
    } else {
      Log.debug('❌ FAIL: URL not extracted from unknown tag');
    }
  } catch (e) {
    Log.debug('❌ ERROR: $e');
  }
  Log.debug('');
}

void testBrokenUrlReplacement() {
  Log.debug('=== Test 3: Broken apt.openvine.co URL replacement ===');
  
  final event = Event(
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    22,
    [['url', 'https://apt.openvine.co/broken.mp4']],
    'Video with broken URL',
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
  
  try {
    final videoEvent = VideoEvent.fromNostrEvent(event);
    Log.debug('Result: hasVideo=${videoEvent.hasVideo}, videoUrl=${videoEvent.videoUrl}');
    
    if (videoEvent.hasVideo && !videoEvent.videoUrl!.contains('apt.openvine.co')) {
      Log.debug('✅ PASS: Broken URL replaced with fallback');
    } else {
      Log.debug('❌ FAIL: Broken URL not replaced');
    }
  } catch (e) {
    Log.debug('❌ ERROR: $e');
  }
  Log.debug('');
}

void testMultipleUrlSources() {
  Log.debug('=== Test 4: Multiple URL sources (priority) ===');
  
  final event = Event(
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    22,
    [
      ['url', 'https://blossom.primal.net/priority.mp4'],
      ['custom', 'https://nostr.build/fallback.mp4'],
    ],
    'Video with multiple URLs',
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
  
  try {
    final videoEvent = VideoEvent.fromNostrEvent(event);
    Log.debug('Result: hasVideo=${videoEvent.hasVideo}, videoUrl=${videoEvent.videoUrl}');
    
    if (videoEvent.hasVideo && videoEvent.videoUrl == 'https://blossom.primal.net/priority.mp4') {
      Log.debug('✅ PASS: Correct URL priority handling');
    } else {
      Log.debug('❌ FAIL: Incorrect URL priority');
    }
  } catch (e) {
    Log.debug('❌ ERROR: $e');
  }
  Log.debug('');
}
