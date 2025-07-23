// ABOUTME: Simple video thumbnail tile for explore screen  
// ABOUTME: Shows clean thumbnail with title/hashtag overlay - full screen handled by parent

import 'package:flutter/material.dart';
import 'package:openvine/models/video_event.dart';
import 'package:openvine/widgets/video_thumbnail_widget.dart';

/// Video thumbnail tile for explore screen
/// - Shows clean thumbnail with title/hashtag overlay
/// - Parent screen handles full-screen overlay when tapped
class VideoExploreTile extends StatelessWidget {
  // Not used anymore but kept for API compatibility

  const VideoExploreTile({
    required this.video,
    required this.isActive,
    super.key,
    this.onTap,
    this.onClose,
  });
  final VideoEvent video;
  final bool isActive; // Not used anymore but kept for API compatibility
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          debugPrint('🎯 VideoExploreTile tapped for video ${video.id.substring(0, 8)}...');
          onTap?.call();
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Smart thumbnail with automatic API generation
                VideoThumbnailWidget(
                  video: video,
                  fit: BoxFit.cover,
                  showPlayIcon: false,
                  borderRadius: BorderRadius.circular(8),
                ),

                // Video info overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (video.title != null)
                          Text(
                            video.title!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (video.hashtags.isNotEmpty)
                          Text(
                            video.hashtags.map((tag) => '#$tag').join(' '),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
