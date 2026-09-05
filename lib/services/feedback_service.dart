import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

enum FeedbackType {
  tap,
  complete,
  delete,
  aiSuccess,
  notification,
  error,
}

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  bool _initialized = false;

  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('feedback_sound') ?? true;
      _hapticEnabled = prefs.getBool('feedback_haptic') ?? true;
      _initialized = true;
    } catch (e) {
      developer.log('FeedbackService init failed', error: e, name: 'FeedbackService');
    }
  }

  void trigger(FeedbackType type) {
    _haptic(type);
    _sound(type);
  }

  void _haptic(FeedbackType type) {
    if (!_hapticEnabled) return;
    if (kIsWeb) return;

    switch (type) {
      case FeedbackType.tap:
        HapticFeedback.lightImpact();
        break;
      case FeedbackType.complete:
        HapticFeedback.mediumImpact();
        break;
      case FeedbackType.delete:
        HapticFeedback.heavyImpact();
        break;
      case FeedbackType.aiSuccess:
        HapticFeedback.mediumImpact();
        break;
      case FeedbackType.notification:
        HapticFeedback.vibrate();
        break;
      case FeedbackType.error:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  Future<void> _sound(FeedbackType type) async {
    if (!_soundEnabled) return;
    if (kIsWeb) return;

    try {
      switch (type) {
        case FeedbackType.tap:
          await _player.setSource(AssetSource('sounds/tap.mp3'));
          await _player.setVolume(0.3);
          await _player.resume();
          break;
        case FeedbackType.complete:
          await _player.setSource(AssetSource('sounds/chime.mp3'));
          await _player.setVolume(0.5);
          await _player.resume();
          break;
        case FeedbackType.delete:
          await _player.setSource(AssetSource('sounds/delete.mp3'));
          await _player.setVolume(0.3);
          await _player.resume();
          break;
        case FeedbackType.aiSuccess:
          await _player.setSource(AssetSource('sounds/cyber.mp3'));
          await _player.setVolume(0.4);
          await _player.resume();
          break;
        case FeedbackType.notification:
          await _player.setSource(AssetSource('sounds/notify.mp3'));
          await _player.setVolume(0.6);
          await _player.resume();
          break;
        case FeedbackType.error:
          await _player.setSource(AssetSource('sounds/error.mp3'));
          await _player.setVolume(0.4);
          await _player.resume();
          break;
      }
    } catch (e) {
      developer.log('Sound playback failed for $type', error: e, name: 'FeedbackService');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
