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
    this.overlayOpacity = 0.45,
  });

  @override
  State<CustomBackgroundWidget> createState() => _CustomBackgroundWidgetState();
}

class _CustomBackgroundWidgetState extends State<CustomBackgroundWidget>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initBackground();
  }

  @override
  void didUpdateWidget(CustomBackgroundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backgroundService != widget.backgroundService) {
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
    if (!bg.isActive) return;

    if (bg.type == CustomBackgroundType.video && bg.filePath != null) {
      await _initVideo(bg.filePath!);
    }
    if (mounted) setState(() {});
  }

  Future<void> _initVideo(String path) async {
    try {
      _videoController = VideoPlayerController.file(File(path));
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.setVolume(0.0);
      await _videoController!.play();
      if (mounted) setState(() => _isVideoInitialized = true);
    } catch (_) {
      _videoController?.dispose();
      _videoController = null;
      if (mounted) setState(() => _isVideoInitialized = false);
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
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDarkOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: widget.overlayOpacity),
    );
  }
}
