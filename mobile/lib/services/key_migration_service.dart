// ABOUTME: Migration service for transitioning from insecure to secure key storage
// ABOUTME: Handles safe migration of existing keys without exposure during transition

import 'dart:async';

import 'package:openvine/services/key_storage_service.dart';
import 'package:openvine/services/secure_key_storage_service.dart';
import 'package:openvine/utils/nostr_encoding.dart';
import 'package:openvine/utils/secure_key_container.dart';
import 'package:openvine/utils/unified_logger.dart';

/// Exception thrown during key migration operations
class KeyMigrationException implements Exception {
  const KeyMigrationException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'KeyMigrationException: $message';
}

/// Migration status for tracking progress
enum MigrationStatus {
  notNeeded, // No migration required
  pending, // Migration is needed but not started
  inProgress, // Migration is currently running
  completed, // Migration completed successfully
  failed, // Migration failed
}

/// Result of a migration operation
class MigrationResult {
  const MigrationResult({
    required this.status,
    required this.secureStorageAvailable,
    required this.legacyKeysFound,
    this.error,
    this.migratedNpub,
  });
  final MigrationStatus status;
  final String? error;
  final bool secureStorageAvailable;
  final bool legacyKeysFound;
  final String? migratedNpub;

  bool get isSuccess => status == MigrationStatus.completed;
  bool get requiresAction =>
      status == MigrationStatus.pending || status == MigrationStatus.failed;
}

/// Service for migrating keys from legacy to secure storage
class KeyMigrationService {
  // ignore: deprecated_member_use_from_same_package
  final KeyStorageService _legacyStorage = KeyStorageService();
  final SecureKeyStorageService _secureStorage = SecureKeyStorageService();

  // ignore: unused_field
  static const String _migrationCompleteKey = 'secure_migration_completed';
  // ignore: unused_field
  static const String _migrationVersionKey = 'migration_version';
  // ignore: unused_field
  static const int _currentMigrationVersion = 1;

  /// Check if migration is needed and get current status
  Future<MigrationResult> checkMigrationStatus() async {
    Log.debug('Checking key migration status',
        name: 'KeyMigrationService', category: LogCategory.auth);

    try {
      // Initialize services
      await Future.wait([
        _legacyStorage.initialize(),
        _secureStorage.initialize().catchError((e) {
          Log.error('Secure storage initialization failed: $e',
              name: 'KeyMigrationService', category: LogCategory.auth);
          return null;
        }),
      ]);

      // Check if secure storage is available
      final secureStorageAvailable = _secureStorage.securityInfo.isNotEmpty;

      // Check if legacy keys exist
      final legacyKeysExist = await _legacyStorage.hasKeys();

      // Check if migration was already completed
      final migrationCompleted = await _isMigrationCompleted();

      if (!legacyKeysExist) {
        Log.info('No legacy keys found - migration not needed',
            name: 'KeyMigrationService', category: LogCategory.auth);
        return MigrationResult(
          status: MigrationStatus.notNeeded,
          secureStorageAvailable: secureStorageAvailable,
          legacyKeysFound: false,
        );
      }

      if (migrationCompleted) {
        Log.info('Migration already completed',
            name: 'KeyMigrationService', category: LogCategory.auth);
        return MigrationResult(
          status: MigrationStatus.completed,
          secureStorageAvailable: secureStorageAvailable,
          legacyKeysFound: legacyKeysExist,
        );
      }

      if (!secureStorageAvailable) {
        Log.warning('Secure storage not available - migration cannot proceed',
            name: 'KeyMigrationService', category: LogCategory.auth);
        return const MigrationResult(
          status: MigrationStatus.failed,
          error: 'Secure storage not available on this device',
          secureStorageAvailable: false,
          legacyKeysFound: true,
        );
      }

      Log.info(
          'Migration pending - legacy keys found and secure storage available',
          name: 'KeyMigrationService',
          category: LogCategory.auth);
      return MigrationResult(
        status: MigrationStatus.pending,
        secureStorageAvailable: secureStorageAvailable,
        legacyKeysFound: legacyKeysExist,
      );
    } catch (e) {
      Log.error('Error checking migration status: $e',
          name: 'KeyMigrationService', category: LogCategory.auth);
      return MigrationResult(
        status: MigrationStatus.failed,
        error: e.toString(),
        secureStorageAvailable: false,
        legacyKeysFound: false,
      );
    }
  }

  /// Perform the migration from legacy to secure storage
  Future<MigrationResult> performMigration({
    String? biometricPrompt,
    bool deleteAfterMigration = true,
  }) async {
    Log.debug('Starting key migration to secure storage',
        name: 'KeyMigrationService', category: LogCategory.auth);
    try {
      // Check if migration should proceed
      final prerequisiteResult = await checkMigrationPrerequisites();
      if (prerequisiteResult != null) return prerequisiteResult;

      // Get legacy key pair and create secure container
      final legacyKeyPair = await retrieveLegacyKeys();
      final secureContainer =
          SecureKeyContainer.fromPrivateKeyHex(legacyKeyPair.privateKeyHex);

      try {
        // Store and verify migration
        final importedContainer = await storeAndVerifyMigration(
          legacyKeyPair: legacyKeyPair,
          secureContainer: secureContainer,
          biometricPrompt: biometricPrompt,
        );
        // Complete migration process
        await completeMigration(deleteAfterMigration: deleteAfterMigration);
        return buildSuccessResult(importedContainer.npub);
      } finally {
        secureContainer.dispose();
      }
    } catch (e) {
      return buildFailureResult(e);
    }
  }

  /// Check if the device supports secure migration
  Future<bool> supportsSecureMigration() async {
    try {
      await _secureStorage.initialize();
      return _secureStorage.securityInfo.isNotEmpty;
    } catch (e) {
      Log.warning('Device does not support secure migration: $e',
          name: 'KeyMigrationService', category: LogCategory.auth);
      return false;
    }
  }

  /// Get migration recommendations for the user
  Future<List<String>> getMigrationRecommendations() async {
    final recommendations = <String>[];

    try {
      final status = await checkMigrationStatus();

      if (status.status == MigrationStatus.notNeeded) {
        recommendations
            .add("No migration needed - you're already using secure storage");
        return recommendations;
      }

      if (status.status == MigrationStatus.completed) {
        recommendations
            .add('Migration completed - your keys are now securely stored');
        return recommendations;
      }

      if (!status.secureStorageAvailable) {
        recommendations
            .add('⚠️ Your device does not support hardware-backed security');
        recommendations
            .add('Consider using a newer device for better security');
        return recommendations;
      }

      if (status.legacyKeysFound) {
        recommendations
            .add('🔒 Migrate to secure storage for better protection');
        recommendations
            .add('Your Nostr keys will be protected by hardware security');

        final secureInfo = _secureStorage.securityInfo;
        if (secureInfo['biometrics_available'] == true) {
          recommendations
              .add('🔐 Enable biometric authentication for maximum security');
        }

        if (secureInfo['hardware_backed'] == true) {
          recommendations
              .add('🛡️ Hardware-backed security available on this device');
        }
      }
    } catch (e) {
      recommendations.add('Unable to determine migration requirements');
    }

    return recommendations;
  }

  /// Check if migration was already completed
  Future<bool> _isMigrationCompleted() async {
    try {
      // For now, we'll use a simple approach - check if secure storage has keys
      // and legacy storage tracking indicates migration was done
      return await _secureStorage.hasKeys();
    } catch (e) {
      return false;
    }
  }

  /// Mark migration as completed
  Future<void> _markMigrationCompleted() async {
    try {
      // We could store this in SharedPreferences or another mechanism
      // For now, the presence of keys in secure storage indicates completion
      Log.info('Migration marked as completed',
          name: 'KeyMigrationService', category: LogCategory.auth);
    } catch (e) {
      Log.error('Failed to mark migration as completed: $e',
          name: 'KeyMigrationService', category: LogCategory.auth);
    }
  }

  /// Clean up legacy storage completely (use with caution!)
  Future<void> cleanupLegacyStorage() async {
    Log.debug('🧹 Cleaning up legacy storage',
        name: 'KeyMigrationService', category: LogCategory.auth);

    try {
      await _legacyStorage.deleteKeys();
      Log.info('Legacy storage cleaned up',
          name: 'KeyMigrationService', category: LogCategory.auth);
    } catch (e) {
      Log.error('Failed to clean up legacy storage: $e',
          name: 'KeyMigrationService', category: LogCategory.auth);
    }
  }

  /// Extract: Verify that migration was successful by comparing keys
  Future<void> verifyMigration({
    required SecureKeyContainer originalContainer,
    required SecureKeyContainer? retrievedContainer,
  }) async {
    Log.info('Verifying migration success',
        name: 'KeyMigrationService', category: LogCategory.auth);

    if (retrievedContainer == null ||
        !retrievedContainer.hasSamePublicKey(originalContainer)) {
      throw const KeyMigrationException(
          'Migration verification failed - keys do not match');
    }
  }

  /// Extract: Retrieve legacy keys from storage
  Future<NostrKeyPair> retrieveLegacyKeys() async {
    Log.debug('🔑 Retrieving legacy key pair',
        name: 'KeyMigrationService', category: LogCategory.auth);

    final legacyKeyPair = await _legacyStorage.getKeyPair();
    if (legacyKeyPair == null) {
      throw const KeyMigrationException('No legacy keys found to migrate');
    }

    Log.debug(
        '🔑 Migrating key for: ${NostrEncoding.maskKey(legacyKeyPair.npub)}',
        name: 'KeyMigrationService',
        category: LogCategory.auth);
    return legacyKeyPair;
  }

  /// Extract: Delete legacy keys if requested
  Future<void> deleteLegacyKeysIfRequested(
      {required bool deleteAfterMigration}) async {
    if (deleteAfterMigration) {
      Log.debug('🗑️ Deleting legacy keys',
          name: 'KeyMigrationService', category: LogCategory.auth);
      await _legacyStorage.deleteKeys();
    }
  }

  /// Extract: Check if migration should proceed
  Future<MigrationResult?> checkMigrationPrerequisites() async {
    final status = await checkMigrationStatus();
    if (status.status == MigrationStatus.notNeeded ||
        status.status == MigrationStatus.completed) {
      return status;
    }

    if (status.status == MigrationStatus.failed) {
      throw KeyMigrationException(
          status.error ?? 'Migration prerequisites not met');
    }

    return null; // Continue with migration
  }

  /// Extract: Store and verify key migration
  Future<SecureKeyContainer> storeAndVerifyMigration({
    required NostrKeyPair legacyKeyPair,
    required SecureKeyContainer secureContainer,
    String? biometricPrompt,
  }) async {
    // Store in secure storage
    Log.debug('🔒 Storing key in secure storage',
        name: 'KeyMigrationService', category: LogCategory.auth);
    final importedContainer = await _secureStorage.importFromNsec(
      legacyKeyPair.nsec,
      biometricPrompt: biometricPrompt,
    );

    // Verify the migration worked using extracted method
    final retrievedContainer = await _secureStorage.getKeyContainer(
      biometricPrompt: biometricPrompt,
    );
    await verifyMigration(
      originalContainer: secureContainer,
      retrievedContainer: retrievedContainer,
    );

    return importedContainer;
  }

  /// Extract: Complete migration process
  Future<void> completeMigration({required bool deleteAfterMigration}) async {
    await _markMigrationCompleted();
    await deleteLegacyKeysIfRequested(
        deleteAfterMigration: deleteAfterMigration);
  }

  /// Extract: Build failure result with error details
  Future<MigrationResult> buildFailureResult(Object error) async {
    Log.error('Migration failed: $error',
        name: 'KeyMigrationService', category: LogCategory.auth);
    return MigrationResult(
      status: MigrationStatus.failed,
      error: error.toString(),
      secureStorageAvailable: await _secureStorage
          .initialize()
          .then((_) => true)
          .catchError((_) => false),
      legacyKeysFound: await _legacyStorage.hasKeys().catchError((_) => false),
    );
  }

  /// Extract: Build success result
  MigrationResult buildSuccessResult(String npub) {
    Log.info('✅ Migration completed successfully',
        name: 'KeyMigrationService', category: LogCategory.auth);
    return MigrationResult(
      status: MigrationStatus.completed,
      secureStorageAvailable: true,
      legacyKeysFound: true,
      migratedNpub: npub,
    );
  }
}
