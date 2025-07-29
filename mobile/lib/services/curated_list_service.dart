// ABOUTME: Service for managing NIP-51 curated lists (kind 30005) for video collections
// ABOUTME: Handles creation, updates, and management of user's public video lists

import 'dart:async';
import 'dart:convert';

import 'package:openvine/services/auth_service.dart';
import 'package:openvine/services/nostr_service_interface.dart';
import 'package:openvine/utils/unified_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum for playlist ordering options
enum PlayOrder {
  chronological, // Order by date added
  reverse, // Reverse chronological order
  manual, // Custom manual order
  shuffle, // Randomized order
}

/// Extension for PlayOrder serialization
extension PlayOrderExtension on PlayOrder {
  String get value {
    switch (this) {
      case PlayOrder.chronological:
        return 'chronological';
      case PlayOrder.reverse:
        return 'reverse';
      case PlayOrder.manual:
        return 'manual';
      case PlayOrder.shuffle:
        return 'shuffle';
    }
  }

  static PlayOrder fromString(String value) {
    switch (value) {
      case 'chronological':
        return PlayOrder.chronological;
      case 'reverse':
        return PlayOrder.reverse;
      case 'manual':
        return PlayOrder.manual;
      case 'shuffle':
        return PlayOrder.shuffle;
      default:
        return PlayOrder.chronological;
    }
  }
}

/// Represents a curated list of videos with enhanced playlist features
/// REFACTORED: Removed ChangeNotifier - now uses pure state management via Riverpod
class CuratedList {
  const CuratedList({
    required this.id,
    required this.name,
    required this.videoEventIds,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.imageUrl,
    this.isPublic = true,
    this.nostrEventId,
    this.tags = const [],
    this.isCollaborative = false,
    this.allowedCollaborators = const [],
    this.thumbnailEventId,
    this.playOrder = PlayOrder.chronological,
  });
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<String> videoEventIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final String? nostrEventId;
  final List<String> tags; // Tags for categorization and discovery
  final bool isCollaborative; // Allow others to add videos
  final List<String> allowedCollaborators; // Pubkeys allowed to collaborate
  final String? thumbnailEventId; // Featured video as thumbnail
  final PlayOrder playOrder; // How videos should be ordered

  CuratedList copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? videoEventIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    String? nostrEventId,
    List<String>? tags,
    bool? isCollaborative,
    List<String>? allowedCollaborators,
    String? thumbnailEventId,
    PlayOrder? playOrder,
  }) =>
      CuratedList(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        videoEventIds: videoEventIds ?? this.videoEventIds,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isPublic: isPublic ?? this.isPublic,
        nostrEventId: nostrEventId ?? this.nostrEventId,
        tags: tags ?? this.tags,
        isCollaborative: isCollaborative ?? this.isCollaborative,
        allowedCollaborators: allowedCollaborators ?? this.allowedCollaborators,
        thumbnailEventId: thumbnailEventId ?? this.thumbnailEventId,
        playOrder: playOrder ?? this.playOrder,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'videoEventIds': videoEventIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isPublic': isPublic,
        'nostrEventId': nostrEventId,
        'tags': tags,
        'isCollaborative': isCollaborative,
        'allowedCollaborators': allowedCollaborators,
        'thumbnailEventId': thumbnailEventId,
        'playOrder': playOrder.value,
      };

  static CuratedList fromJson(Map<String, dynamic> json) => CuratedList(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        imageUrl: json['imageUrl'],
        videoEventIds: List<String>.from(json['videoEventIds'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        isPublic: json['isPublic'] ?? true,
        nostrEventId: json['nostrEventId'],
        tags: List<String>.from(json['tags'] ?? []),
        isCollaborative: json['isCollaborative'] ?? false,
        allowedCollaborators: List<String>.from(json['allowedCollaborators'] ?? []),
        thumbnailEventId: json['thumbnailEventId'],
        playOrder: PlayOrderExtension.fromString(json['playOrder'] ?? 'chronological'),
      );
}

/// Service for managing NIP-51 curated lists
/// REFACTORED: Removed ChangeNotifier - now uses pure state management via Riverpod
class CuratedListService  {
  CuratedListService({
    required INostrService nostrService,
    required AuthService authService,
    required SharedPreferences prefs,
  })  : _nostrService = nostrService,
        _authService = authService,
        _prefs = prefs {
    _loadLists();
  }
  final INostrService _nostrService;
  final AuthService _authService;
  final SharedPreferences _prefs;

  static const String listsStorageKey = 'curated_lists';
  static const String defaultListId = 'my_vine_list';

  final List<CuratedList> _lists = [];
  bool _isInitialized = false;

  // Getters
  List<CuratedList> get lists => List.unmodifiable(_lists);
  bool get isInitialized => _isInitialized;

  /// Initialize the service and create default list if needed
  Future<void> initialize() async {
    try {
      if (!_authService.isAuthenticated) {
        Log.warning('Cannot initialize curated lists - user not authenticated',
            name: 'CuratedListService', category: LogCategory.system);
        return;
      }

      // Create default list if it doesn't exist
      if (!hasDefaultList()) {
        await _createDefaultList();
      }

      _isInitialized = true;
      Log.info('Curated list service initialized with ${_lists.length} lists',
          name: 'CuratedListService', category: LogCategory.system);

    } catch (e) {
      Log.error('Failed to initialize curated list service: $e',
          name: 'CuratedListService', category: LogCategory.system);
    }
  }

  /// Check if default list exists
  bool hasDefaultList() => _lists.any((list) => list.id == defaultListId);

  /// Get the default "My List" for quick adding
  CuratedList? getDefaultList() {
    try {
      return _lists.firstWhere((list) => list.id == defaultListId);
    } catch (e) {
      return null;
    }
  }

  /// Create a new curated list with enhanced playlist features
  Future<CuratedList?> createList({
    required String name,
    String? description,
    String? imageUrl,
    bool isPublic = true,
    List<String> tags = const [],
    bool isCollaborative = false,
    List<String> allowedCollaborators = const [],
    String? thumbnailEventId,
    PlayOrder playOrder = PlayOrder.chronological,
  }) async {
    try {
      final listId = 'list_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      final newList = CuratedList(
        id: listId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        videoEventIds: [],
        createdAt: now,
        updatedAt: now,
        isPublic: isPublic,
        tags: tags,
        isCollaborative: isCollaborative,
        allowedCollaborators: allowedCollaborators,
        thumbnailEventId: thumbnailEventId,
        playOrder: playOrder,
      );

      _lists.add(newList);
      await _saveLists();

      // Publish to Nostr if user is authenticated and list is public
      if (_authService.isAuthenticated && isPublic) {
        await _publishListToNostr(newList);
      }

      Log.info('Created new curated list: $name ($listId)',
          name: 'CuratedListService', category: LogCategory.system);

      return newList;
    } catch (e) {
      Log.error('Failed to create curated list: $e',
          name: 'CuratedListService', category: LogCategory.system);
      return null;
    }
  }

  /// Add video to a list
  Future<bool> addVideoToList(String listId, String videoEventId) async {
    try {
      final listIndex = _lists.indexWhere((list) => list.id == listId);
      if (listIndex == -1) {
        Log.warning('List not found: $listId',
            name: 'CuratedListService', category: LogCategory.system);
        return false;
      }

      final list = _lists[listIndex];

      // Check if video is already in the list
      if (list.videoEventIds.contains(videoEventId)) {
        Log.warning('Video already in list: $videoEventId',
            name: 'CuratedListService', category: LogCategory.system);
        return true; // Return true since it's already there
      }

      // Add video to list
      final updatedVideoIds = [...list.videoEventIds, videoEventId];
      final updatedList = list.copyWith(
        videoEventIds: updatedVideoIds,
        updatedAt: DateTime.now(),
      );

      _lists[listIndex] = updatedList;
      await _saveLists();

      // Update on Nostr if public
      if (updatedList.isPublic && _authService.isAuthenticated) {
        await _publishListToNostr(updatedList);
      }

      Log.debug('➕ Added video to list "${list.name}": $videoEventId',
          name: 'CuratedListService', category: LogCategory.system);

      return true;
    } catch (e) {
      Log.error('Failed to add video to list: $e',
          name: 'CuratedListService', category: LogCategory.system);
      return false;
    }
  }

  /// Remove video from a list
  Future<bool> removeVideoFromList(String listId, String videoEventId) async {
    try {
      final listIndex = _lists.indexWhere((list) => list.id == listId);
      if (listIndex == -1) {
        Log.warning('List not found: $listId',
            name: 'CuratedListService', category: LogCategory.system);
        return false;
      }

      final list = _lists[listIndex];
      final updatedVideoIds =
          list.videoEventIds.where((id) => id != videoEventId).toList();

      final updatedList = list.copyWith(
        videoEventIds: updatedVideoIds,
        updatedAt: DateTime.now(),
      );

      _lists[listIndex] = updatedList;
      await _saveLists();

      // Update on Nostr if public
      if (updatedList.isPublic && _authService.isAuthenticated) {
        await _publishListToNostr(updatedList);
      }

      Log.debug('➖ Removed video from list "${list.name}": $videoEventId',
          name: 'CuratedListService', category: LogCategory.system);

      return true;
    } catch (e) {
      Log.error('Failed to remove video from list: $e',
          name: 'CuratedListService', category: LogCategory.system);
      return false;
    }
  }

  /// Check if video is in a specific list
  bool isVideoInList(String listId, String videoEventId) {
    final list = _lists.where((l) => l.id == listId).firstOrNull;
    return list?.videoEventIds.contains(videoEventId) ?? false;
  }

  /// Check if video is in default list
  bool isVideoInDefaultList(String videoEventId) =>
      isVideoInList(defaultListId, videoEventId);

  /// Get list by ID
  CuratedList? getListById(String listId) {
    try {
      return _lists.firstWhere((list) => list.id == listId);
    } catch (e) {
      return null;
    }
  }

  /// Update list metadata with enhanced playlist features
  Future<bool> updateList({
    required String listId,
    String? name,
    String? description,
    String? imageUrl,
    bool? isPublic,
    List<String>? tags,
    bool? isCollaborative,
    List<String>? allowedCollaborators,
    String? thumbnailEventId,
    PlayOrder? playOrder,
  }) async {
    try {
      final listIndex = _lists.indexWhere((list) => list.id == listId);
      if (listIndex == -1) {
        return false;
      }

      final list = _lists[listIndex];
      final updatedList = list.copyWith(
        name: name ?? list.name,
        description: description ?? list.description,
        imageUrl: imageUrl ?? list.imageUrl,
        isPublic: isPublic ?? list.isPublic,
        tags: tags ?? list.tags,
        isCollaborative: isCollaborative ?? list.isCollaborative,
        allowedCollaborators: allowedCollaborators ?? list.allowedCollaborators,
        thumbnailEventId: thumbnailEventId ?? list.thumbnailEventId,
        playOrder: playOrder ?? list.playOrder,
        updatedAt: DateTime.now(),
      );

      _lists[listIndex] = updatedList;
      await _saveLists();

      // Update on Nostr if public
      if (updatedList.isPublic && _authService.isAuthenticated) {
        await _publishListToNostr(updatedList);
      }

      Log.debug('✏️ Updated list: ${updatedList.name}',
          name: 'CuratedListService', category: LogCategory.system);

      return true;
    } catch (e) {
      Log.error('Failed to update list: $e',
          name: 'CuratedListService', category: LogCategory.system);
      return false;
    }
  }

  /// Delete a list
  Future<bool> deleteList(String listId) async {
    try {
      // Don't allow deleting the default list
      if (listId == defaultListId) {
        Log.warning('Cannot delete default list',
            name: 'CuratedListService', category: LogCategory.system);
        return false;
      }

      final listIndex = _lists.indexWhere((list) => list.id == listId);
      if (listIndex == -1) {
        return false;
      }

      final list = _lists[listIndex];
      _lists.removeAt(listIndex);
      await _saveLists();

      // TODO: Send deletion event to Nostr if it was published

      Log.debug('📱️ Deleted list: ${list.name}',
          name: 'CuratedListService', category: LogCategory.system);

      return true;
    } catch (e) {
      Log.error('Failed to delete list: $e',
          name: 'CuratedListService', category: LogCategory.system);
      return false;
    }
  }

  // === ENHANCED PLAYLIST FEATURES ===

  /// Reorder videos in a playlist (manual play order)
  Future<bool> reorderVideos(String listId, List<String> newOrder) async {
    try {
      final listIndex = _lists.indexWhere((list) => list.id == listId);
      if (listIndex == -1) {
        Log.warning('List not found: $listId',
            name: 'CuratedListService', category: LogCategory.system);
        return false;
      }

      final list = _lists[listIndex];
      
      // Validate that all current videos are included in the new order
      final currentVideos = Set<String>.from(list.videoEventIds);
      final newOrderSet = Set<String>.from(newOrder);
      
      if (currentVideos.difference(newOrderSet).isNotEmpty || 
          newOrderSet.difference(currentVideos).isNotEmpty) {
        Log.warning('Invalid reorder: video lists do not match',
            name: 'CuratedListService', category: LogCategory.system);
        return false;
      }

      final updatedList = list.copyWith(
        videoEventIds: newOrder,
        playOrder: PlayOrder.manual, // Set to manual when reordering
        updatedAt: DateTime.now(),
      );

      _lists[listIndex] = updatedList;
      await _saveLists();

      // Update on Nostr if public
      if (updatedList.isPublic && _authService.isAuthenticated) {
        await _publishListToNostr(updatedList);
      }

      Log.debug('📱 Reordered videos in list "${list.name}"',
          name: 'CuratedListService', category: LogCategory.system);

      return true;
    } catch (e) {
      Log.error('Failed to reorder videos: $e',
          name: 'CuratedListService', category: LogCategory.system);
      return false;
    }
  }

  /// Get ordered video list based on play order setting
  List<String> getOrderedVideoIds(String listId) {
    final list = getListById(listId);
    if (list == null) return [];

    switch (list.playOrder) {
      case PlayOrder.chronological:
        return list.videoEventIds; // Already in chronological order
      case PlayOrder.reverse:
        return list.videoEventIds.reversed.toList();
      case PlayOrder.manual:
        return list.videoEventIds; // Manual order as stored
      case PlayOrder.shuffle:
        final shuffled = List<String>.from(list.videoEventIds);
        shuffled.shuffle();
        return shuffled;
    }
  }

  /// Add collaborator to a list
  Future<bool> addCollaborator(String listId, String pubkey) async {
    try {
      final listIndex = _lists.indexWhere((list) => list.id == listId);
      if (listIndex == -1) {
        return false;
      }

      final list = _lists[listIndex];
      if (!list.isCollaborative) {
        Log.warning('Cannot add collaborator - list is not collaborative',
            name: 'CuratedListService', category: LogCategory.system);
        return false;
      }

      if (list.allowedCollaborators.contains(pubkey)) {
        Log.debug('User already a collaborator: $pubkey',
            name: 'CuratedListService', category: LogCategory.system);
        return true;
      }

      final updatedCollaborators = [...list.allowedCollaborators, pubkey];
      final updatedList = list.copyWith(
        allowedCollaborators: updatedCollaborators,
        updatedAt: DateTime.now(),
      );

      _lists[listIndex] = updatedList;
      await _saveLists();

      // Update on Nostr if public
      if (updatedList.isPublic && _authService.isAuthenticated) {
        await _publishListToNostr(updatedList);
      }

      Log.debug('✅ Added collaborator to list "${list.name}": $pubkey',
          name: 'CuratedListService', category: LogCategory.system);

      return true;
    } catch (e) {
      Log.error('Failed to add collaborator: $e',
          name: 'CuratedListService', category: LogCategory.system);
      return false;
    }
  }

  /// Remove collaborator from a list
  Future<bool> removeCollaborator(String listId, String pubkey) async {
    try {
      final listIndex = _lists.indexWhere((list) => list.id == listId);
      if (listIndex == -1) {
        return false;
      }

      final list = _lists[listIndex];
      final updatedCollaborators = list.allowedCollaborators
          .where((collaborator) => collaborator != pubkey)
          .toList();

      final updatedList = list.copyWith(
        allowedCollaborators: updatedCollaborators,
        updatedAt: DateTime.now(),
      );

      _lists[listIndex] = updatedList;
      await _saveLists();

      // Update on Nostr if public
      if (updatedList.isPublic && _authService.isAuthenticated) {
        await _publishListToNostr(updatedList);
      }

      Log.debug('➖ Removed collaborator from list "${list.name}": $pubkey',
          name: 'CuratedListService', category: LogCategory.system);

      return true;
    } catch (e) {
      Log.error('Failed to remove collaborator: $e',
          name: 'CuratedListService', category: LogCategory.system);
      return false;
    }
  }

  /// Check if a user can collaborate on a list
  bool canCollaborate(String listId, String pubkey) {
    final list = getListById(listId);
    if (list == null) return false;
    
    // List owner can always collaborate
    if (_authService.currentPublicKeyHex == pubkey) return true;
    
    // Check if collaborative and user is allowed
    return list.isCollaborative && list.allowedCollaborators.contains(pubkey);
  }

  /// Get lists by tag for discovery
  List<CuratedList> getListsByTag(String tag) {
    return _lists.where((list) => 
        list.isPublic && list.tags.contains(tag.toLowerCase())).toList();
  }

  /// Get all unique tags across all lists
  List<String> getAllTags() {
    final allTags = <String>{};
    for (final list in _lists) {
      if (list.isPublic) {
        allTags.addAll(list.tags);
      }
    }
    return allTags.toList()..sort();
  }

  /// Search lists by name or description
  List<CuratedList> searchLists(String query) {
    if (query.trim().isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return _lists.where((list) => 
        list.isPublic && (
          list.name.toLowerCase().contains(lowerQuery) ||
          (list.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          list.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
        )).toList();
  }

  /// Get all lists that contain a specific video
  List<CuratedList> getListsContainingVideo(String videoEventId) {
    return _lists.where((list) => list.videoEventIds.contains(videoEventId)).toList();
  }

  /// Get readable summary of lists containing a video
  String getVideoListSummary(String videoEventId) {
    final listsContaining = getListsContainingVideo(videoEventId);
    
    if (listsContaining.isEmpty) {
      return 'Not in any lists';
    }
    
    if (listsContaining.length == 1) {
      return 'In "${listsContaining.first.name}"';
    }
    
    if (listsContaining.length <= 3) {
      final names = listsContaining.map((list) => '"${list.name}"').join(', ');
      return 'In $names';
    }
    
    return 'In ${listsContaining.length} lists';
  }

  /// Create the default "My List" for quick access
  Future<void> _createDefaultList() async {
    await createList(
      name: 'My List',
      description: 'My favorite vines and videos',
      isPublic: true,
    );

    // Update the ID to be the default ID
    final listIndex = _lists.indexWhere((list) => list.name == 'My List');
    if (listIndex != -1) {
      final list = _lists[listIndex];
      _lists[listIndex] = list.copyWith(id: defaultListId);
      await _saveLists();
    }
  }

  /// Publish list to Nostr as NIP-51 kind 30005 event
  Future<void> _publishListToNostr(CuratedList list) async {
    try {
      if (!_authService.isAuthenticated) {
        Log.warning('Cannot publish list - user not authenticated',
            name: 'CuratedListService', category: LogCategory.system);
        return;
      }

      // Create NIP-51 kind 30005 tags
      final tags = <List<String>>[
        ['d', list.id], // Identifier for replaceable event
        ['title', list.name],
        ['client', 'openvine'],
      ];

      // Add description if present
      if (list.description != null && list.description!.isNotEmpty) {
        tags.add(['description', list.description!]);
      }

      // Add image if present
      if (list.imageUrl != null && list.imageUrl!.isNotEmpty) {
        tags.add(['image', list.imageUrl!]);
      }

      // Add tags for categorization
      for (final tag in list.tags) {
        tags.add(['t', tag]);
      }

      // Add collaboration settings
      if (list.isCollaborative) {
        tags.add(['collaborative', 'true']);
        for (final collaborator in list.allowedCollaborators) {
          tags.add(['collaborator', collaborator]);
        }
      }

      // Add thumbnail if present
      if (list.thumbnailEventId != null) {
        tags.add(['thumbnail', list.thumbnailEventId!]);
      }

      // Add play order setting
      tags.add(['playorder', list.playOrder.value]);

      // Add video events as 'e' tags
      for (final videoEventId in list.videoEventIds) {
        tags.add(['e', videoEventId]);
      }

      final content = list.description ?? 'Curated video list: ${list.name}';

      final event = await _authService.createAndSignEvent(
        kind: 30005, // NIP-51 curated list
        content: content,
        tags: tags,
      );

      if (event != null) {
        final result = await _nostrService.broadcastEvent(event);
        if (result.successCount > 0) {
          // Update local list with Nostr event ID
          final listIndex = _lists.indexWhere((l) => l.id == list.id);
          if (listIndex != -1) {
            _lists[listIndex] = list.copyWith(nostrEventId: event.id);
            await _saveLists();
          }
          Log.debug('Published list to Nostr: ${list.name} (${event.id})',
              name: 'CuratedListService', category: LogCategory.system);
        }
      }
    } catch (e) {
      Log.error('Failed to publish list to Nostr: $e',
          name: 'CuratedListService', category: LogCategory.system);
    }
  }

  /// Load lists from local storage
  void _loadLists() {
    final listsJson = _prefs.getString(listsStorageKey);
    if (listsJson != null) {
      try {
        final List<dynamic> listsData = jsonDecode(listsJson);
        _lists.clear();
        _lists.addAll(
          listsData.map(
              (json) => CuratedList.fromJson(json as Map<String, dynamic>)),
        );
        Log.debug('📱 Loaded ${_lists.length} curated lists from storage',
            name: 'CuratedListService', category: LogCategory.system);
      } catch (e) {
        Log.error('Failed to load curated lists: $e',
            name: 'CuratedListService', category: LogCategory.system);
      }
    }
  }

  /// Save lists to local storage
  Future<void> _saveLists() async {
    try {
      final listsJson = _lists.map((list) => list.toJson()).toList();
      await _prefs.setString(listsStorageKey, jsonEncode(listsJson));
    } catch (e) {
      Log.error('Failed to save curated lists: $e',
          name: 'CuratedListService', category: LogCategory.system);
    }
  }
}
