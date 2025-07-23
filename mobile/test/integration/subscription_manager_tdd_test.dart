// ABOUTME: TDD test for SubscriptionManager hitting real vine.hol.is relay - NO MOCKING
// ABOUTME: This test will fail first, then we fix SubscriptionManager to make it pass

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:openvine/services/nostr_service.dart';
import 'package:openvine/services/nostr_key_manager.dart';
import 'package:openvine/services/subscription_manager.dart';

void main() {
  // Initialize Flutter bindings and mock platform dependencies for test environment
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences
  const MethodChannel prefsChannel = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    prefsChannel,
    (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') return <String, dynamic>{};
      if (methodCall.method == 'setString' || methodCall.method == 'setStringList') return true;
      return null;
    },
  );

  // Mock connectivity
  const MethodChannel connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    connectivityChannel,
    (MethodCall methodCall) async {
      if (methodCall.method == 'check') return ['wifi'];
      return null;
    },
  );

  // Mock secure storage
  const MethodChannel secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    secureStorageChannel,
    (MethodCall methodCall) async {
      if (methodCall.method == 'write') return null;
      if (methodCall.method == 'read') return null;
      if (methodCall.method == 'readAll') return <String, String>{};
      return null;
    },
  );

  group('SubscriptionManager TDD - Real Relay Tests', () {
    late NostrService nostrService;
    late SubscriptionManager subscriptionManager;
    late NostrKeyManager keyManager;

    setUpAll(() async {
      keyManager = NostrKeyManager();
      await keyManager.initialize();
      
      nostrService = NostrService(keyManager);
      await nostrService.initialize(customRelays: ['wss://vine.hol.is']);
      
      // Wait for connection to stabilize
      await Future.delayed(Duration(seconds: 3));
      
      subscriptionManager = SubscriptionManager(nostrService);
    });

    tearDownAll(() async {
      await nostrService.closeAllSubscriptions();
      nostrService.dispose();
    });

    test('SubscriptionManager should receive kind 22 events from vine.hol.is relay', () async {
      print('🔍 TDD TEST: Testing SubscriptionManager with real vine.hol.is relay...');
      
      // This test will FAIL initially - that's the point of TDD!
      final receivedEvents = <Event>[];
      final completer = Completer<void>();
      
      // Create subscription using SubscriptionManager
      final subscriptionId = await subscriptionManager.createSubscription(
        name: 'tdd_test_video_feed',
        filters: [Filter(kinds: [22], limit: 3)],
        onEvent: (event) {
          print('✅ TDD: SubscriptionManager received event: kind=${event.kind}, id=${event.id.substring(0, 8)}');
          receivedEvents.add(event);
          if (receivedEvents.length >= 2) {
            completer.complete();
          }
        },
        onError: (error) {
          print('❌ TDD: SubscriptionManager error: $error');
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onComplete: () {
          print('🏁 TDD: SubscriptionManager subscription completed');
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      print('📡 TDD: Created subscription $subscriptionId, waiting for events...');
      
      // Wait for events with reasonable timeout
      try {
        await completer.future.timeout(Duration(seconds: 15));
      } catch (e) {
        print('⏰ TDD: Timeout waiting for events from SubscriptionManager');
      }

      // Clean up
      await subscriptionManager.cancelSubscription(subscriptionId);
      
      print('📊 TDD: SubscriptionManager received ${receivedEvents.length} events');
      
      // This assertion will FAIL initially - proving SubscriptionManager is broken
      expect(receivedEvents.length, greaterThan(0), 
        reason: 'SubscriptionManager should receive events from vine.hol.is relay (we know events exist from nak verification)');
    });
    
    test('Direct subscription should work for comparison (proves relay has events)', () async {
      print('🔍 TDD: Testing direct subscription as control test...');
      
      final directEvents = <Event>[];
      final directCompleter = Completer<void>();
      
      final directStream = nostrService.subscribeToEvents(
        filters: [Filter(kinds: [22], limit: 3)]
      );
      
      final directSub = directStream.listen(
        (event) {
          print('✅ TDD: Direct subscription received event: kind=${event.kind}, id=${event.id.substring(0, 8)}');
          directEvents.add(event);
          if (directEvents.length >= 2) {
            directCompleter.complete();
          }
        },
        onError: (error) {
          print('❌ TDD: Direct subscription error: $error');
          if (!directCompleter.isCompleted) {
            directCompleter.completeError(error);
          }
        },
      );

      try {
        await directCompleter.future.timeout(Duration(seconds: 15));
      } catch (e) {
        print('⏰ TDD: Timeout waiting for direct events');
      }

      directSub.cancel();
      
      print('📊 TDD: Direct subscription received ${directEvents.length} events');
      
      // This should pass - proving the relay has events and our test setup works
      expect(directEvents.length, greaterThan(0), 
        reason: 'Direct subscription should receive events (proves relay connectivity and events exist)');
    });
  });
}