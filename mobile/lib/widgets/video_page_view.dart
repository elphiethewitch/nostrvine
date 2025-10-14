// ABOUTME: Consolidated video feed PageView component with intelligent preloading
// ABOUTME: Provides consistent vertical scrolling behavior across home feed and explore screens

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openvine/models/video_event.dart';
import 'package:openvine/providers/individual_video_providers.dart';
import 'package:openvine/providers/computed_active_video_provider.dart';
import 'package:openvine/providers/tab_visibility_provider.dart';
import 'package:openvine/providers/app_foreground_provider.dart';
import 'package:openvine/providers/video_prewarmer_provider.dart';
import 'package:openvine/widgets/video_feed_item.dart';
import 'package:openvine/utils/unified_logger.dart';

/// Consolidated video feed PageView widget
///
/// Provides consistent vertical scrolling video feed behavior with:
/// - Mouse/trackpad drag support (web + desktop)
/// - Touch gesture support (mobile)
/// - Intelligent prewarming of neighbor videos
/// - Optional preloading for upcoming videos
/// - Pull-to-refresh support
/// - Pagination callback when near end of list
class VideoPageView extends ConsumerStatefulWidget {
  const VideoPageView({
    super.key,
    required this.videos,
    this.controller,
    this.initialIndex = 0,
    this.hasBottomNavigation = true,
    this.enablePrewarming = true,
    this.enablePreloading = false,
    this.enableLifecycleManagement = true,
    this.tabIndex,
    this.screenId, // Screen ID for reactive context (e.g., 'home', 'explore', 'profile:npub123')
    this.contextTitle,
    this.onPageChanged,
    this.onLoadMore,
    this.onRefresh,
  });

  final List<VideoEvent> videos;
  final PageController? controller;
  final int initialIndex;
  final bool hasBottomNavigation;
  final bool enablePrewarming;
  final bool enablePreloading;
  final bool enableLifecycleManagement;
  final int? tabIndex; // Tab index this VideoPageView belongs to (for tab visibility checking)
  final String? screenId; // Screen ID for reactive page context management
  final String? contextTitle; // Optional context title to display (e.g., "#funny")
  final void Function(int index, VideoEvent video)? onPageChanged;
  final VoidCallback? onLoadMore;
  final Future<void> Function()? onRefresh;

  @override
  ConsumerState<VideoPageView> createState() => _VideoPageViewState();
}

class _VideoPageViewState extends ConsumerState<VideoPageView> {
  late PageController _pageController;
  int _currentIndex = 0;

  /// Check if this VideoPageView's tab is currently visible
  bool get _isTabVisible {
    // If no tab index specified, assume always visible (e.g., standalone screens like ExploreVideoScreenPure)
    if (widget.tabIndex == null) return true;

    // Check if our tab is the active tab
    final activeTab = ref.read(tabVisibilityProvider);
    return activeTab == widget.tabIndex;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = widget.controller ?? PageController(initialPage: widget.initialIndex);

    // Set initial page context if screenId is provided
    // Use Future.microtask to avoid modifying provider during build
    if (widget.enableLifecycleManagement && widget.screenId != null) {
      Future.microtask(() {
        if (!mounted) return;

        final isAppForeground = ref.read(appForegroundProvider);
        Log.debug('🔍 VideoPageView initState check: isAppForeground=$isAppForeground, _isTabVisible=$_isTabVisible, index=$_currentIndex',
            name: 'VideoPageView', category: LogCategory.video);
        if (isAppForeground && _isTabVisible && _currentIndex >= 0 && _currentIndex < widget.videos.length) {
          ref.read(currentPageContextProvider.notifier).setContext(widget.screenId!, _currentIndex);

          // Schedule prewarming
          if (widget.enablePrewarming) {
            _prewarmNeighbors(_currentIndex);
          }
        } else {
          Log.debug('⏭️ Skipping setContext in initState - conditions not met',
              name: 'VideoPageView', category: LogCategory.video);
        }
      });
    }

    // Listen for tab visibility changes to rebuild VideoFeedItems when tab becomes visible
    if (widget.tabIndex != null) {
      ref.listenManual(tabVisibilityProvider, (prev, next) {
        final wasVisible = prev == widget.tabIndex;
        final isVisibleNow = next == widget.tabIndex;

        // Rebuild when visibility changes
        if (wasVisible != isVisibleNow) {
          Log.debug('🔄 Tab visibility changed for tab ${widget.tabIndex}: $wasVisible -> $isVisibleNow',
              name: 'VideoPageView', category: LogCategory.video);

          if (mounted) {
            setState(() {
              // Trigger rebuild to switch between placeholders and VideoFeedItems
            });

            // If tab became visible, set page context (only if app is in foreground and screenId provided)
            if (isVisibleNow && widget.enableLifecycleManagement && widget.screenId != null) {
              Future.microtask(() {
                if (!mounted) return;
                final isAppForeground = ref.read(appForegroundProvider);
                if (isAppForeground && _currentIndex >= 0 && _currentIndex < widget.videos.length) {
                  ref.read(currentPageContextProvider.notifier).setContext(widget.screenId!, _currentIndex);
                }
              });
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    // Clear page context if this VideoPageView owns it
    if (widget.enableLifecycleManagement && widget.screenId != null) {
      try {
        ref.read(currentPageContextProvider.notifier).clear();
      } catch (e) {
        Log.error('Error clearing page context on dispose: $e',
            name: 'VideoPageView', category: LogCategory.video);
      }
    }

    // Only dispose controller if we created it
    if (widget.controller == null) {
      _pageController.dispose();
    }
    super.dispose();
  }

  void _prewarmNeighbors(int index) {
    if (!widget.enablePrewarming) return;

    final params = <VideoControllerParams>[];

    // AGGRESSIVE prewarming for demo-quality instant scrolling
    // Prewarm 10 videos ahead (more important for forward scrolling)
    // and 3 videos behind (less important for backward scrolling)
    // This ensures buttery-smooth infinite scrolling experience
    for (int offset = -3; offset <= 10; offset++) {
      final i = index + offset;
      if (i >= 0 && i < widget.videos.length) {
        final v = widget.videos[i];
        if (v.videoUrl != null && v.videoUrl!.isNotEmpty) {
          params.add(VideoControllerParams(
            videoId: v.id,
            videoUrl: v.videoUrl!,
            videoEvent: v,
          ));
        }
      }
    }

    if (params.isNotEmpty) {
      try {
        ref.read(videoPrewarmerProvider.notifier).prewarmVideos(params);
      } catch (e) {
        Log.error('Error prewarming neighbors: $e',
            name: 'VideoPageView', category: LogCategory.video);
      }
    }
  }

  void _handlePageChanged(int index) {
    Log.debug('📄 VideoPageView: Page changed to index $index (tabVisible: $_isTabVisible)',
        name: 'VideoPageView', category: LogCategory.video);
    setState(() => _currentIndex = index);

    if (index >= 0 && index < widget.videos.length) {
      final video = widget.videos[index];

      // Update page context ONLY if this tab is visible AND app is in foreground AND screenId is provided
      if (widget.enableLifecycleManagement && _isTabVisible && widget.screenId != null) {
        final isAppForeground = ref.read(appForegroundProvider);
        if (isAppForeground) {
          try {
            ref.read(currentPageContextProvider.notifier).setContext(widget.screenId!, index);
          } catch (e) {
            Log.error('Error setting page context: $e',
                name: 'VideoPageView', category: LogCategory.video);
          }
        } else {
          Log.debug('⏭️ Skipping setContext - app is backgrounded',
              name: 'VideoPageView', category: LogCategory.video);
        }
      } else if (!_isTabVisible) {
        Log.debug('⏭️ Skipping setContext - tab not visible (tab ${widget.tabIndex} vs active ${ref.read(tabVisibilityProvider)})',
            name: 'VideoPageView', category: LogCategory.video);
      }

      // Prewarm neighbors
      if (widget.enablePrewarming) {
        _prewarmNeighbors(index);
      }

      // Check for pagination
      if (widget.onLoadMore != null && index >= widget.videos.length - 3) {
        widget.onLoadMore!();
      }

      // Notify parent
      widget.onPageChanged?.call(index, video);
    }
  }

  Widget _buildPageView() {
    Log.debug('🎮 VideoPageView: Building PageView with controller=${_pageController.hashCode}, '
        'hasClients=${_pageController.hasClients}, '
        'position=${_pageController.hasClients ? _pageController.position.pixels : "no position"}, '
        'videoCount=${widget.videos.length}, '
        'hasBottomNav=${widget.hasBottomNavigation}, '
        'tabVisible=$_isTabVisible',
        name: 'VideoPageView', category: LogCategory.video);

    return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: _handlePageChanged,
          itemCount: widget.videos.length,
          pageSnapping: true,
          itemBuilder: (context, index) {
            if (index >= widget.videos.length) return const SizedBox.shrink();

            // CRITICAL: Only build VideoFeedItem (which creates controllers) when tab is visible
            // When tab is not visible, build lightweight placeholder to prevent controller creation
            if (!_isTabVisible) {
              return Container(
                key: ValueKey('placeholder-${widget.videos[index].id}'),
                color: Colors.black,
                child: const Center(
                  child: SizedBox.shrink(), // Empty placeholder when tab not visible
                ),
              );
            }

            return VideoFeedItem(
              key: ValueKey('video-${widget.videos[index].id}'),
              video: widget.videos[index],
              index: index,
              hasBottomNavigation: widget.hasBottomNavigation,
              contextTitle: widget.contextTitle,
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    Widget pageView = _buildPageView();

    // Wrap with ScrollConfiguration to enable mouse/trackpad dragging
    pageView = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      child: pageView,
    );

    // Note: RefreshIndicator cannot wrap vertical PageView as it conflicts with scrolling
    // Pull-to-refresh should be implemented differently (e.g., custom gesture detection
    // or a separate refresh button). For now, onRefresh callback is available but not
    // used with RefreshIndicator to avoid blocking vertical scrolling.

    return pageView;
  }
}
