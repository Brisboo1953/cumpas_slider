 import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicService {
  static final AudioPlayer _player = AudioPlayer();
  static double _currentVolume = 1.0;

  static double get currentVolume => _currentVolume;

  static Future<void> playMenu() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      try {
        await _player.setVolume(_currentVolume);
      } catch (_) {}
      try {
        await _player.play(AssetSource('sounds/menu_music.mp3'));
        return;
      } catch (e) {
        debugPrint('AudioPlayers: AssetSource failed, trying UrlSource fallback: $e');
      }

      try {
        final url = Uri.base.resolve('assets/sounds/menu_music.mp3').toString();
        await _player.play(UrlSource(url));
        return;
      } catch (err) {
        debugPrint('AudioPlayers: UrlSource fallback failed for mp3: $err');
      }

      try {
        final urlOgg = Uri.base.resolve('assets/sounds/menu_music.ogg').toString();
        await _player.play(UrlSource(urlOgg));
        return;
      } catch (err2) {
        debugPrint('AudioPlayers: UrlSource fallback failed for ogg: $err2');
        rethrow;
      }
    } catch (e) {
    }
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
    }
  }

  static Future<void> setVolume(double v) async {
    _currentVolume = v.clamp(0.0, 1.0);
    try {
      await _player.setVolume(_currentVolume);
    } catch (e) {
      if (kDebugMode) debugPrint('MusicService.setVolume error: $e');
    }
  }

  static Future<void> duckFor(Duration duration, {double duckFactor = 0.25}) async {
    final previous = _currentVolume;
    final target = (previous * duckFactor).clamp(0.0, 1.0);
    try {
      await setVolume(target);
    } catch (_) {}

    final maxDuration = const Duration(seconds: 5);
    final wait = duration <= maxDuration ? duration : maxDuration;
    await Future.delayed(wait);

    try {
      await setVolume(previous);
    } catch (_) {}
  }
}                                 