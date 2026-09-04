import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_theme.dart';
import '../../services/theme_service.dart';

class ThemeVideoBackground extends StatefulWidget {
  final ThemeService themeService;
  final Widget child;

  const ThemeVideoBackground({
    super.key,
    required this.themeService,
    required this.child,
  });

  @override
  State<ThemeVideoBackground> createState() => _ThemeVideoBackgroundState();
}

class _ThemeVideoBackgroundState extends State<ThemeVideoBackground>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _currentVideoPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.themeService.addListener(_onThemeChanged);
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant ThemeVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeService != widget.themeService) {
      oldWidget.themeService.removeListener(_onThemeChanged);
      widget.themeService.addListener(_onThemeChanged);
      _initVideo();
    }
  }

  void _onThemeChanged() {
    final newPath = widget.themeService.current.videoPath;
    if (newPath != _currentVideoPath) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final videoPath = widget.themeService.current.videoPath;
    if (videoPath == null) {
      _disposeVideo();
      if (mounted) setState(() => _currentVideoPath = null);
      return;
    }

    if (videoPath == _currentVideoPath && _isInitialized) return;

    _disposeVideo();
    _currentVideoPath = videoPath;

    try {
      final controller = VideoPlayerController.asset(videoPath);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);

      if (!mounted || _currentVideoPath != videoPath) {
        controller.dispose();
        return;
      }

      _controller = controller;
      if (mounted) {
        setState(() => _isInitialized = true);
        _controller!.play();
      }
    } catch (e) {
      debugPrint('[ThemeVideoBackground] Failed to load video: $e');
      if (mounted) setState(() => _isInitialized = false);
    }
  }

  void _disposeVideo() {
    final old = _controller;
    _controller = null;
    _isInitialized = false;
    old?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.paused) {
      _controller!.pause();
    } else if (state == AppLifecycleState.resumed) {
      _controller!.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.themeService.removeListener(_onThemeChanged);
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Solid theme background color (fallback while video loads)
        ColoredBox(color: AppColors.background),

        // Layer 2: Video
        if (_isInitialized && _controller != null)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),

        // Layer 3: Dark overlay for readability (0.4–0.6 per design spec)
        ColoredBox(
          color: Colors.black.withValues(alpha: 0.5),
        ),

        // Layer 4: Content
        widget.child,
      ],
    );
  }
}
