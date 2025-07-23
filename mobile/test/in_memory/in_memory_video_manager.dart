// ABOUTME: In-memory implementation of VideoManager for testing
// ABOUTME: Provides video management without external dependencies

import 'dart:async';
import 'package:openvine/models/video_event.dart';

class InMemoryVideoManager {
  final List<VideoEvent> _videos = [];
  final StreamController<List<VideoEvent>> _videosController =
      StreamController<List<VideoEvent>>.broadcast();

  Stream<List<VideoEvent>> get videosStream => _videosController.stream;
  List<VideoEvent> get videos => List.unmodifiable(_videos);

  void addVideo(VideoEvent video) {
    _videos.add(video);
    _videosController.add(videos);
  }

  void removeVideo(String videoId) {
    _videos.removeWhere((v) => v.id == videoId);
    _videosController.add(videos);
  }

  void clear() {
    _videos.clear();
    _videosController.add(videos);
  }

  void dispose() {
    _videosController.close();
  }
}
