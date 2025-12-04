 import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicService {
  static final AudioPlayer _player = AudioPlayer();
  // Track current volume locally because AudioPlayer doesn't provide a reliable getter
  static double _currentVolume = 1.0;

  /// Obtener el volumen actual (0.0 - 1.0)
  static double get currentVolume => _currentVolume;

  static Future<void> playMenu() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      // Ensure player uses the remembered volume
      try {
        await _player.setVolume(_currentVolume);
      } catch (_) {}
      // Try playing as an asset first (recommended) asi es
      try {
        await _player.play(AssetSource('sounds/menu_music.mp3'));
        return;
      } catch (e) {
        // If asset playback fails on web (format/mime issues), try a URL fallback
        // We'll fall through to UrlSource below.
        debugPrint('AudioPlayers: AssetSource failed, trying UrlSource fallback: $e');
      }

      // Fallback: try resolving the asset via a URL (useful for web servers)
      try {
        final url = Uri.base.resolve('assets/sounds/menu_music.mp3').toString();
        await _player.play(UrlSource(url));
        return;
      } catch (err) {
        debugPrint('AudioPlayers: UrlSource fallback failed for mp3: $err');
      }

      // Try an OGG variant if available (some browsers prefer/require different encodings)
      try {
        final urlOgg = Uri.base.resolve('assets/sounds/menu_music.ogg').toString();
        await _player.play(UrlSource(urlOgg));
        return;
      } catch (err2) {
        debugPrint('AudioPlayers: UrlSource fallback failed for ogg: $err2');
        rethrow;
      }
    } catch (e) {
      // ignore errors silently for now
    }
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      // ignore
    }
  }

  /// Set the music player's volume (0.0 - 1.0) and remember it locally.
  static Future<void> setVolume(double v) async {
    _currentVolume = v.clamp(0.0, 1.0);
    try {
      await _player.setVolume(_currentVolume);
    } catch (e) {
      if (kDebugMode) debugPrint('MusicService.setVolume error: $e');
    }
  }

  /// Temporarily lower (duck) the music volume for [duration], then restore.
  /// The duck target is a fraction of the current volume (default 0.25).
  static Future<void> duckFor(Duration duration, {double duckFactor = 0.25}) async {
    final previous = _currentVolume;
    final target = (previous * duckFactor).clamp(0.0, 1.0);
    try {
      await setVolume(target);
    } catch (_) {}

    // Wait the requested duration but ensure we don't hold longer than 5s
    final maxDuration = const Duration(seconds: 5);
    final wait = duration <= maxDuration ? duration : maxDuration;
    await Future.delayed(wait);

    try {
      await setVolume(previous);
    } catch (_) {}
  }
}                                 