// ABOUTME: Simple Dart script to test SubscriptionManager against real vine.hol.is relay
// ABOUTME: NO FLUTTER TEST FRAMEWORK - just raw Dart to prove SubscriptionManager is broken

import 'dart:async';
import 'dart:io';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:openvine/services/nostr_service.dart';
import 'package:openvine/services/nostr_key_manager.dart';
import 'package:openvine/services/subscription_manager.dart';

void main() async {
  print('🔍 REAL RELAY TEST: Testing SubscriptionManager vs Direct Subscription');
  print('📡 Connecting to vine.hol.is relay...');

  try {
    // Create key manager with in-memory keys (no platform dependencies)
    final keyManager = MockKeyManager();
    
    // Create real NostrService
    final nostrService = NostrService(keyManager);
    await nostrService.initialize(customRelays: ['wss://vine.hol.is']);
    
    print('✅ Connected to ${nostrService.connectedRelayCount} relays');
    
    // Wait for connection to stabilize
    await Future.delayed(Duration(seconds: 3));
    
    final subscriptionManager = SubscriptionManager(nostrService);
    
    // Test 1: SubscriptionManager
    print('\n🔍 TEST 1: Testing SubscriptionManager...');
    final managedEvents = <Event>[];
    final managedCompleter = Completer<void>();
    
    final managedSubId = await subscriptionManager.createSubscription(
      name: 'test_managed',
      filters: [Filter(kinds: [22], limit: 5)],
      onEvent: (event) {
        print('✅ MANAGED: Received event ${event.id.substring(0, 8)} kind=${event.kind}');
        managedEvents.add(event);
        if (managedEvents.length >= 3) managedCompleter.complete();
      },
      onError: (error) {
        print('❌ MANAGED: Error: $error');
        if (!managedCompleter.isCompleted) managedCompleter.completeError(error);
      },
      onComplete: () {
        print('🏁 MANAGED: Complete');
        if (!managedCompleter.isCompleted) managedCompleter.complete();
      },
    );
    
    // Wait for managed events with timeout
    try {
      await managedCompleter.future.timeout(Duration(seconds: 10));
    } catch (e) {
      print('⏰ MANAGED: Timeout after 10 seconds');
    }
    
    print('📊 MANAGED RESULT: ${managedEvents.length} events received');
    
    // Test 2: Direct Subscription
    print('\n🔍 TEST 2: Testing Direct Subscription...');
    final directEvents = <Event>[];
    final directCompleter = Completer<void>();
    
    final directStream = nostrService.subscribeToEvents(
      filters: [Filter(kinds: [22], limit: 5)]
    );
    
    final directSub = directStream.listen(
      (event) {
        print('✅ DIRECT: Received event ${event.id.substring(0, 8)} kind=${event.kind}');
        directEvents.add(event);
        if (directEvents.length >= 3) directCompleter.complete();
      },
      onError: (error) {
        print('❌ DIRECT: Error: $error');
        if (!directCompleter.isCompleted) directCompleter.completeError(error);
      },
      onDone: () {
        print('🏁 DIRECT: Complete');
        if (!directCompleter.isCompleted) directCompleter.complete();
      },
    );
    
    // Wait for direct events with timeout
    try {
      await directCompleter.future.timeout(Duration(seconds: 10));
    } catch (e) {
      print('⏰ DIRECT: Timeout after 10 seconds');
    }
    
    directSub.cancel();
    await subscriptionManager.cancelSubscription(managedSubId);
    
    print('📊 DIRECT RESULT: ${directEvents.length} events received');
    
    // Results
    print('\n🔍 FINAL COMPARISON:');
    print('  SubscriptionManager events: ${managedEvents.length}');
    print('  Direct subscription events: ${directEvents.length}');
    
    if (managedEvents.isEmpty && directEvents.isNotEmpty) {
      print('💥 PROOF: SubscriptionManager is BROKEN!');
      print('   Direct gets ${directEvents.length} events, SubscriptionManager gets 0');
      exit(1); // Exit with error code to indicate SubscriptionManager is broken
    } else if (managedEvents.length == directEvents.length && directEvents.isNotEmpty) {
      print('✅ Both methods work equally');
      exit(0);
    } else {
      print('⚠️  Different event counts - needs investigation');
      print('   This could indicate SubscriptionManager is partially broken');
      exit(2);
    }
    
  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
    exit(3);
  }
}

/// Mock key manager that doesn't use platform dependencies
class MockKeyManager extends NostrKeyManager {
  late String _privateKey;
  late String _publicKey;
  bool _initialized = false;
  
  @override
  bool get isInitialized => _initialized;
  
  @override
  bool get hasKeys => _initialized;
  
  @override
  String? get publicKey => _initialized ? _publicKey : null;
  
  @override
  String? get privateKey => _initialized ? _privateKey : null;
  
  @override
  Keychain? get keyPair => _initialized ? Keychain(_privateKey) : null;
  
  @override
  Future<void> initialize() async {
    // Generate test keys without platform dependencies
    _privateKey = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
    _publicKey = '02' + '0123456789abcdef' * 4; // Mock public key
    _initialized = true;
  }
  
  @override
  Future<Keychain> generateKeys() async {
    await initialize();
    return keyPair!;
  }
}