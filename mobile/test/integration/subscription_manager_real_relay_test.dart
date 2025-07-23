// ABOUTME: Real relay test for SubscriptionManager - NO MOCKING to prove it's broken
// ABOUTME: This test hits vine.hol.is relay directly to show SubscriptionManager doesn't work

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:openvine/services/nostr_service.dart';
import 'package:openvine/services/nostr_key_manager.dart';
import 'package:openvine/services/subscription_manager.dart';

void main() {
  // Initialize Flutter bindings for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences channel
  const MethodChannel prefsChannel = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    prefsChannel,
    (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{}; // Return empty preferences
      }
      if (methodCall.method == 'setString' || methodCall.method == 'setStringList') {
        return true; // Mock successful writes
      }
      return null;
    },
  );

  // Mock connectivity channel
  const MethodChannel connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    connectivityChannel,
    (MethodCall methodCall) async {
      if (methodCall.method == 'check') {
        return ['wifi']; // Mock being online with correct type
      }
      return null;
    },
  );

  // Mock flutter_secure_storage channel
  const MethodChannel secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    secureStorageChannel,
    (MethodCall methodCall) async {
      if (methodCall.method == 'write') {
        return null; // Mock successful writes
      }
      if (methodCall.method == 'read') {
        return null; // Mock empty reads
      }
      if (methodCall.method == 'readAll') {
        return <String, String>{}; // Mock empty storage
      }
      return null;
    },
  );

  group('SubscriptionManager Real Relay Tests - NO MOCKING', () {
    late NostrService nostrService;
    late SubscriptionManager subscriptionManager;
    late NostrKeyManager keyManager;

    setUpAll(() async {
      // Create and initialize key manager
      keyManager = NostrKeyManager();
      await keyManager.initialize();
      
      // Create real NostrService that connects to actual relay
      nostrService = NostrService(keyManager);
      await nostrService.initialize();
      
      // Add vine.hol.is relay
      await nostrService.addRelay('wss://vine.hol.is');
      
      // Wait for connection
      await Future.delayed(Duration(seconds: 2));
      
      subscriptionManager = SubscriptionManager(nostrService);
    });

    tearDownAll(() async {
      await nostrService.closeAllSubscriptions();
      nostrService.dispose();
    });

    test('SubscriptionManager should receive kind 22 events from vine.hol.is - REAL RELAY', () async {
      print('🔍 TEST: Starting SubscriptionManager real relay test...');
      
      final receivedEvents = <Event>[];
      final completer = Completer<void>();
      
      // Create subscription for kind 22 events - same as what VideoEventService does
      final subscriptionId = await subscriptionManager.createSubscription(
        name: 'test_video_feed',
        filters: [
          Filter(
            kinds: [22], 
            limit: 5
          )
        ],
        onEvent: (event) {
          print('✅ SUBSCRIPTION_MANAGER: Received event via SubscriptionManager: kind=${event.kind}, id=${event.id.substring(0, 8)}');
          receivedEvents.add(event);
          if (receivedEvents.length >= 3) {
            completer.complete();
          }
        },
        onError: (error) {
          print('❌ SUBSCRIPTION_MANAGER: Error: $error');
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onComplete: () {
          print('🏁 SUBSCRIPTION_MANAGER: Subscription completed');
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      print('📡 TEST: Created SubscriptionManager subscription ID: $subscriptionId');
      
      // Wait for events with timeout
      try {
        await completer.future.timeout(Duration(seconds: 15));
      } catch (e) {
        print('⏰ TEST: Timeout waiting for SubscriptionManager events');
      }

      print('📊 TEST: SubscriptionManager received ${receivedEvents.length} events');
      
      // Now test direct subscription for comparison
      print('🔍 TEST: Now testing direct subscription for comparison...');
      
      final directEvents = <Event>[];
      final directCompleter = Completer<void>();
      
      final directStream = nostrService.subscribeToEvents(
        filters: [Filter(kinds: [22], limit: 5)]
      );
      
      final directSub = directStream.listen(
        (event) {
          print('✅ DIRECT: Received event via direct subscription: kind=${event.kind}, id=${event.id.substring(0, 8)}');
          directEvents.add(event);
          if (directEvents.length >= 3) {
            directCompleter.complete();
          }
        },
        onError: (error) {
          print('❌ DIRECT: Error: $error');
          if (!directCompleter.isCompleted) {
            directCompleter.completeError(error);
          }
        },
        onDone: () {
          print('🏁 DIRECT: Direct subscription completed');
          if (!directCompleter.isCompleted) {
            directCompleter.complete();
          }
        },
      );

      try {
        await directCompleter.future.timeout(Duration(seconds: 15));
      } catch (e) {
        print('⏰ TEST: Timeout waiting for direct subscription events');
      }

      directSub.cancel();
      
      print('📊 TEST: Direct subscription received ${directEvents.length} events');
      
      // Print detailed comparison
      print('🔍 COMPARISON RESULTS:');
      print('  SubscriptionManager events: ${receivedEvents.length}');
      print('  Direct subscription events: ${directEvents.length}');
      
      if (receivedEvents.isEmpty && directEvents.isNotEmpty) {
        print('💥 PROOF: SubscriptionManager is BROKEN - receives 0 events while direct gets ${directEvents.length}');
      } else if (receivedEvents.length == directEvents.length) {
        print('✅ Both methods work equally');
      } else {
        print('⚠️  Different event counts - needs investigation');
      }
      
      // The test assertion
      expect(receivedEvents.length, greaterThan(0), 
        reason: 'SubscriptionManager should receive events from vine.hol.is relay like direct subscription does');
      
      // Clean up
      await subscriptionManager.cancelSubscription(subscriptionId);
    });

    test('Direct comparison: Both should get same events from vine.hol.is', () async {
      print('🔍 TEST: Direct comparison test...');
      
      // Test SubscriptionManager
      final managedEvents = <Event>[];
      final managedCompleter = Completer<void>();
      
      final managedSubId = await subscriptionManager.createSubscription(
        name: 'comparison_managed',
        filters: [Filter(kinds: [22], limit: 3)],
        onEvent: (event) {
          print('📱 MANAGED: ${event.id.substring(0, 8)}');
          managedEvents.add(event);
          if (managedEvents.length >= 3) managedCompleter.complete();
        },
        onError: (error) {
          if (!managedCompleter.isCompleted) managedCompleter.completeError(error);
        },
        onComplete: () {
          if (!managedCompleter.isCompleted) managedCompleter.complete();
        },
      );

      // Test direct subscription
      final directEvents = <Event>[];
      final directCompleter = Completer<void>();
      
      final directStream = nostrService.subscribeToEvents(
        filters: [Filter(kinds: [22], limit: 3)]
      );
      
      final directSub = directStream.listen(
        (event) {
          print('🔗 DIRECT: ${event.id.substring(0, 8)}');
          directEvents.add(event);
          if (directEvents.length >= 3) directCompleter.complete();
        },
        onError: (error) {
          if (!directCompleter.isCompleted) directCompleter.completeError(error);
        },
        onDone: () {
          if (!directCompleter.isCompleted) directCompleter.complete();
        },
      );

      // Wait for both
      await Future.wait([
        managedCompleter.future.timeout(Duration(seconds: 10), onTimeout: () {}),
        directCompleter.future.timeout(Duration(seconds: 10), onTimeout: () {}),
      ]);

      directSub.cancel();
      await subscriptionManager.cancelSubscription(managedSubId);

      print('📊 FINAL COMPARISON:');
      print('  SubscriptionManager: ${managedEvents.length} events');
      print('  Direct subscription: ${directEvents.length} events');
      
      if (managedEvents.isEmpty && directEvents.isNotEmpty) {
        print('💥 CONFIRMED: SubscriptionManager is completely broken!');
        print('   Direct gets ${directEvents.length} events, SubscriptionManager gets 0');
      }

      // This will fail if SubscriptionManager is broken
      expect(managedEvents.length, equals(directEvents.length),
        reason: 'SubscriptionManager should get same number of events as direct subscription');
    });
  });
}