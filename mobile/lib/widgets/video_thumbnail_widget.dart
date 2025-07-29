// ABOUTME: Smart video thumbnail widget that automatically generates thumbnails when missing
// ABOUTME: Uses the new thumbnail API service with proper loading states and fallbacks

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:openvine/models/video_event.dart';
import 'package:openvine/services/thumbnail_api_service.dart';
import 'package:openvine/utils/unified_logger.dart';
import 'package:openvine/widgets/blurhash_display.dart';
import 'package:openvine/widgets/video_icon_placeholder.dart';
import 'package:video_player/video_player.dart';

/// Smart thumbnail widget that automatically generates thumbnails from the API
class VideoThumbnailWidget extends StatefulWidget {
  const VideoThumbnailWidget({
    required this.video,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.timeSeconds = 2.5,
    this.size = ThumbnailSize.medium,
    this.showPlayIcon = false,
    this.borderRadius,
  });
  final VideoEvent video;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double timeSeconds;
  final ThumbnailSize size;
  final bool showPlayIcon;
  final BorderRadius? borderRadius;

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  String? _thumbnailUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if video ID, time, or size changed
    if (oldWidget.video.id != widget.video.id ||
        oldWidget.timeSeconds != widget.timeSeconds ||
        oldWidget.size != widget.size) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    Log.debug(
      '🖼️ VideoThumbnailWidget: Loading thumbnail for video ${widget.video.id.substring(0, 8)}...',
      name: 'VideoThumbnailWidget',
      category: LogCategory.video,
    );
    Log.debug(
      '   Video URL: ${widget.video.videoUrl}',
      name: 'VideoThumbnailWidget',
      category: LogCategory.video,
    );
    Log.debug(
      '   Existing thumbnail: ${widget.video.thumbnailUrl}',
      name: 'VideoThumbnailWidget',
      category: LogCategory.video,
    );

    // First check if we have an existing thumbnail URL
    if (widget.video.thumbnailUrl != null && widget.video.thumbnailUrl!.isNotEmpty) {
      Log.info(
        '✅ Using existing thumbnail for ${widget.video.id.substring(0, 8)}: ${widget.video.thumbnailUrl}',
        name: 'VideoThumbnailWidget',
        category: LogCategory.video,
      );
      setState(() {
        _thumbnailUrl = widget.video.thumbnailUrl;
        _isLoading = false;
      });
      return;
    }

    Log.info(
      '🚀 No existing thumbnail found, requesting API generation for ${widget.video.id.substring(0, 8)}...',
      name: 'VideoThumbnailWidget',
      category: LogCategory.video,
    );
    Log.debug(
      '   timeSeconds: ${widget.timeSeconds}, size: ${widget.size}',
      name: 'VideoThumbnailWidget',
      category: LogCategory.video,
    );

    // Try to get thumbnail from API
    setState(() {
      _isLoading = true;
    });

    try {
      final apiUrl = await widget.video.getApiThumbnailUrl(
        timeSeconds: widget.timeSeconds,
        size: widget.size,
      );

      Log.info(
        '🖼️ Thumbnail API response for ${widget.video.id.substring(0, 8)}: ${apiUrl ?? "null"}',
        name: 'VideoThumbnailWidget',
        category: LogCategory.video,
      );

      // Check if the API returned a placeholder SVG
      if (apiUrl != null && await _isPlaceholderSvg(apiUrl)) {
        Log.debug(
          '⚠️ Thumbnail API returned placeholder SVG for ${widget.video.id.substring(0, 8)}, using icon placeholder instead',
          name: 'VideoThumbnailWidget',
          category: LogCategory.video,
        );
        if (mounted) {
          setState(() {
            _thumbnailUrl = null; // Use placeholder instead
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _thumbnailUrl = apiUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      Log.error(
        '❌ Thumbnail API failed for ${widget.video.id.substring(0, 8)}: $e',
        name: 'VideoThumbnailWidget',
        category: LogCategory.video,
      );
      if (mounted) {
        setState(() {
          _thumbnailUrl = null;
          _isLoading = false;
        });
      }
    }
  }

  /// Check if a URL returns a placeholder SVG
  Future<bool> _isPlaceholderSvg(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      final contentType = response.headers['content-type'];
      if (contentType != null && contentType.contains('image/svg+xml')) {
        Log.debug(
          '🔍 Detected SVG content type for ${widget.video.id.substring(0, 8)}, treating as placeholder',
          name: 'VideoThumbnailWidget',
          category: LogCategory.video,
        );
        return true;
      }
      return false;
    } catch (e) {
      Log.debug(
        '🔍 Could not check content type for ${widget.video.id.substring(0, 8)}, assuming real thumbnail: $e',
        name: 'VideoThumbnailWidget',
        category: LogCategory.video,
      );
      return false;
    }
  }

  Widget _buildContent() {
    // While determining what thumbnail to use, show blurhash if available
    if (_isLoading && widget.video.blurhash != null) {
      return Stack(
        children: [
          BlurhashDisplay(
            blurhash: widget.video.blurhash!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          ),
          if (widget.showPlayIcon)
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
        ],
      );
    }
    
    if (_isLoading) {
      return VideoIconPlaceholder(
        width: widget.width,
        height: widget.height,
        showLoading: true,
        showPlayIcon: widget.showPlayIcon,
        borderRadius: widget.borderRadius?.topLeft.x ?? 8.0,
      );
    }

    if (_thumbnailUrl != null) {
      // Use BlurhashImage to show blurhash while loading the actual thumbnail
      return BlurhashImage(
        imageUrl: _thumbnailUrl!,
        blurhash: widget.video.blurhash,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => 
          widget.video.blurhash != null
            ? BlurhashDisplay(
                blurhash: widget.video.blurhash!,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
              )
            : VideoIconPlaceholder(
                width: widget.width,
                height: widget.height,
                showPlayIcon: widget.showPlayIcon,
                borderRadius: widget.borderRadius?.topLeft.x ?? 8.0,
              ),
      );
    }

    // Fallback - if we have a video URL, show a frame from the video
    if (widget.video.videoUrl != null && widget.video.videoUrl!.isNotEmpty) {
      return _VideoFrameWidget(
        videoUrl: widget.video.videoUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        showPlayIcon: widget.showPlayIcon,
      );
    }
    
    // Final fallback - try blurhash first, then icon placeholder
    if (widget.video.blurhash != null) {
      return BlurhashDisplay(
        blurhash: widget.video.blurhash!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }
    
    return VideoIconPlaceholder(
      width: widget.width,
      height: widget.height,
      showPlayIcon: widget.showPlayIcon,
      borderRadius: widget.borderRadius?.topLeft.x ?? 8.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🖼️ VideoThumbnailWidget build: width=${widget.width}, height=${widget.height}, fit=${widget.fit}');
    var content = _buildContent();

    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return content;
  }
}

/// Widget that displays a frame from a video as a thumbnail
class _VideoFrameWidget extends StatefulWidget {
  const _VideoFrameWidget({
    required this.videoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.showPlayIcon = false,
  });
  
  final String videoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool showPlayIcon;

  @override
  State<_VideoFrameWidget> createState() => _VideoFrameWidgetState();
}

class _VideoFrameWidgetState extends State<_VideoFrameWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();
      
      // Seek to 2.5 seconds or middle of video for better thumbnail
      if (_controller!.value.duration > Duration.zero) {
        final seekTime = _controller!.value.duration > const Duration(seconds: 5)
            ? const Duration(milliseconds: 2500)
            : _controller!.value.duration ~/ 2;
        await _controller!.seekTo(seekTime);
      }
      
      // Set volume to 0 to avoid playing audio
      await _controller!.setVolume(0.0);
      
      // Play for a frame then pause to ensure we have video data
      await _controller!.play();
      await Future.delayed(const Duration(milliseconds: 100));
      await _controller!.pause();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      Log.error(
        '❌ Failed to initialize video for thumbnail: $e',
        name: '_VideoFrameWidget',
        category: LogCategory.video,
      );
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return VideoIconPlaceholder(
        width: widget.width,
        height: widget.height,
        showPlayIcon: widget.showPlayIcon,
      );
    }

    if (!_isInitialized || _controller == null) {
      return VideoIconPlaceholder(
        width: widget.width,
        height: widget.height,
        showLoading: true,
        showPlayIcon: widget.showPlayIcon,
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: widget.fit,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
          if (widget.showPlayIcon)
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

