// ABOUTME: Custom exceptions for video-related services
// ABOUTME: Provides specific error types for subscription and network operations

/// Exception thrown when trying to subscribe without relay connections
class ConnectionException implements Exception {
  ConnectionException(this.message);
  final String message;

  @override
  String toString() => 'ConnectionException: $message';
}

/// Exception thrown when attempting duplicate subscriptions
class DuplicateSubscriptionException implements Exception {
  DuplicateSubscriptionException(this.message);
  final String message;

  @override
  String toString() => 'DuplicateSubscriptionException: $message';
}
