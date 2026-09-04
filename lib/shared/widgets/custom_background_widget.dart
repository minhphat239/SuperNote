import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../services/custom_background_service.dart';

class CustomBackgroundWidget extends StatefulWidget {
  final CustomBackgroundService backgroundService;
  final Widget child;
  final double overlayOpacity;

  const CustomBackgroundWidget({
    super.key,
    required this.backgroundService,
    required this.child,
    this.overlayOpacity = 0.65,
  });

  @override
  State<CustomBackgroundWidget> createState() => _CustomBackgroundWidgetState();
}

class _CustomBackgroundWidgetState extends State<CustomBackgroundWidget>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  int _videoInitGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.backgroundService.addListener(_onBackgroundChanged);
    _initBackground();
  }

  void _onBackgroundChanged() {
    _disposeVideo();
    _initBackground();
  }

  @override
  void didUpdateWidget(CustomBackgroundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backgroundService != widget.backgroundService) {
      oldWidget.backgroundService.removeListener(_onBackgroundChanged);
      widget.backgroundService.addListener(_onBackgroundChanged);
      _disposeVideo();
      _initBackground();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _videoController!.pause();
    } else if (state == AppLifecycleState.resumed) {
      _videoController!.play();
    }
  }

  Future<void> _initBackground() async {
    final bg = widget.backgroundService;
    if (!bg.isActive) {
      if (mounted) setState(() {});
      return;
    }

    if (bg.type == CustomBackgroundType.video && bg.filePath != null) {
      await _initVideo(bg.filePath!);
    }
    if (mounted) setState(() {});
  }

  Future<void> _initVideo(String path) async {
    final generation = ++_videoInitGeneration;
    try {
      final controller = VideoPlayerController.file(File(path));
      _videoController = controller;
      await controller.initialize();
      if (generation != _videoInitGeneration) {
        // A newer init was started, discard this result
        controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();
      if (mounted) setState(() => _isVideoInitialized = true);
    } catch (_) {
      if (generation == _videoInitGeneration) {
        _videoController?.dispose();
        _videoController = null;
        if (mounted) setState(() => _isVideoInitialized = false);
      }
    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.backgroundService.removeListener(_onBackgroundChanged);
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundService;
    if (!bg.isActive) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackgroundLayer(bg),
        _buildDarkOverlay(),
        widget.child,
      ],
    );
  }

  Widget _buildBackgroundLayer(CustomBackgroundService bg) {
    if (bg.type == CustomBackgroundType.video &&
        _videoController != null &&
        _isVideoInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    }

    if (bg.type == CustomBackgroundType.image && bg.file != null) {
      return SizedBox.expand(
        child: Image.file(
          bg.file!,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          // Cap decoded bitmap size to avoid OOM on low-RAM devices with large photos.
          // 1080x1920 covers most phones while keeping memory ~8MB.
          cacheWidth: 1080,
          cacheHeight: 1920,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDarkOverlay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base dark overlay
        Container(
          color: Colors.black.withValues(alpha: widget.overlayOpacity),
        ),
        // Top gradient (status bar area)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bottom gradient (navigation bar area)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
