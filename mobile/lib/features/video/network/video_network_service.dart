// ABOUTME: Handles network operations for video events including subscriptions and queries
// ABOUTME: Manages WebSocket connections and relay communication for NIP-71 events

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:openvine/services/nostr_service_interface.dart';
import 'package:openvine/services/subscription_manager.dart';
import 'package:openvine/utils/unified_logger.dart';

/// Exception thrown when network connection issues occur
class ConnectionException implements Exception {
  /// Creates a new connection exception with the given message
  ConnectionException(this.message);

  /// Error message describing the connection issue
  final String message;

  @override
  String toString() => 'ConnectionException: $message';
}

/// Service responsible for video event network operations
class VideoNetworkService {
  /// Creates a new video network service
  VideoNetworkService({
    required this.nostrService,
    required this.subscriptionManager,
  });

  /// Nostr service for relay communication
  final INostrService nostrService;

  /// Subscription manager for handling relay subscriptions
  final SubscriptionManager subscriptionManager;

  final StreamController<Event> _eventController =
      StreamController<Event>.broadcast();
  final List<String> _activeSubscriptionIds = [];

  /// Callback invoked when unsubscribing from feeds
  VoidCallback? onUnsubscribe;

  /// Stream of incoming video events
  Stream<Event> get eventStream => _eventController.stream;

  /// Subscribe to video feed with various filters
  Future<void> subscribeToVideoFeed({
    List<String>? authors,
    List<String>? hashtags,
    String? group,
    int? since,
    int? until,
    int limit = 50,
    bool includeReposts = false,
  }) async {
    if (nostrService.connectedRelayCount == 0) {
      throw ConnectionException('Not connected to any relays');
    }

    await _cancelExistingSubscriptions();

    final kinds = includeReposts ? [22, 6] : [22];

    // Combine group filter with vine tag requirement
    List<String>? hTags;
    if (group != null) {
      hTags = [group, 'vine'];
    } else {
      hTags = ['vine'];
    }

    final filter = Filter(
      kinds: kinds,
      authors: authors,
      t: hashtags,
      h: hTags,
      since: since,
      until: until,
      limit: limit,
    );

    Log.debug(
      'Subscribing to video feed: kinds=$kinds, authors=$authors, hashtags=$hashtags, group=$group',
      name: 'VideoNetworkService',
      category: LogCategory.video,
    );

    final subscriptionId = await subscriptionManager.createSubscription(
      name: 'video-feed',
      filters: [filter],
      onEvent: _handleEvent,
      priority: 5,
    );

    _activeSubscriptionIds.add(subscriptionId);
  }

  /// Query historical events
  Future<List<Event>> queryHistoricalEvents({
    int? until,
    int limit = 200,
    List<String>? authors,
    List<String>? hashtags,
  }) async {
    final filter = Filter(
      kinds: [22],
      authors: authors,
      t: hashtags,
      until: until,
      limit: limit,
    );

    Log.debug(
      'Querying historical events: until=$until, limit=$limit',
      name: 'VideoNetworkService',
      category: LogCategory.video,
    );

    // Use subscribeToEvents for one-time query
    final events = <Event>[];
    final completer = Completer<List<Event>>();

    late StreamSubscription<Event> subscription;
    subscription = nostrService.subscribeToEvents(filters: [filter]).listen(
      events.add,
      onDone: () {
        completer.complete(events);
      },
      onError: (Object error) {
        completer.completeError(error);
      },
    );

    // Close subscription after a short delay to allow events to arrive
    Timer(const Duration(seconds: 2), () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(events);
      }
    });

    return completer.future;
  }

  /// Handle incoming event
  void handleNewEvent(Event event) {
    _handleEvent(event);
  }

  void _handleEvent(Event event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  Future<void> _cancelExistingSubscriptions() async {
    onUnsubscribe?.call();

    for (final id in _activeSubscriptionIds) {
      await subscriptionManager.cancelSubscription(id);
    }
    _activeSubscriptionIds.clear();
  }

  /// Clean up resources
  void dispose() {
    _cancelExistingSubscriptions();
    _eventController.close();
  }
}
