 import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io' show Platform;

class MusicService {
  static final AudioPlayer _player = AudioPlayer();
  static double _currentVolume = 1.0;
  static bool _playRequestInProgress = false;
  static bool _playerListenersAttached = false;

  static double get currentVolume => _currentVolume;

  static Future<void> playMenu() async {
    if (_playRequestInProgress) {
      if (kDebugMode) debugPrint('MusicService: play request already in progress, ignoring.');
      return;
    }
    _playRequestInProgress = true;
    try {
      // Ensure player mode appropriate for music playback on Android
      try {
        await _player.setPlayerMode(PlayerMode.mediaPlayer);
      } catch (_) {}
      await _player.setReleaseMode(ReleaseMode.loop);
      // Attach debug listeners once to inspect runtime state changes
      if (!_playerListenersAttached) _attachPlayerListeners();
      try {
        await _player.setVolume(_currentVolume);
      } catch (_) {}
      // Intento principal: AssetSource (debe funcionar en debug y release si el asset está incluido)
      try {
        if (kDebugMode) debugPrint('MusicService: attempting AssetSource play...');
        await _player.play(AssetSource('sounds/menu_music.mp3'));
        if (kDebugMode) debugPrint('MusicService: AssetSource play started');
        return;
      } catch (e) {
        debugPrint('AudioPlayers: AssetSource failed: $e');
      }

      // Fallback: intentar reproducir desde la URL relativa (útil en web), o desde bytes (útil en APK)
      try {
        final url = Uri.base.resolve('assets/sounds/menu_music.mp3').toString();
        if (kDebugMode) debugPrint('MusicService: attempting UrlSource $url');
        await _player.play(UrlSource(url));
        return;
      } catch (err) {
        debugPrint('AudioPlayers: UrlSource fallback failed for mp3: $err');
      }

      // Último recurso: cargar bytes del asset y reproducir con BytesSource (funciona en APK)
      try {
        if (kDebugMode) debugPrint('MusicService: attempting BytesSource from asset bundle');
        final bytes = await rootBundle.load('assets/sounds/menu_music.mp3');
        await _player.play(BytesSource(bytes.buffer.asUint8List()));
        if (kDebugMode) debugPrint('MusicService: BytesSource play started');
        return;
      } catch (err2) {
        debugPrint('AudioPlayers: BytesSource fallback failed: $err2');
      }

      // Optionally try ogg variant
      try {
        final bytesOgg = await rootBundle.load('assets/sounds/menu_music.ogg');
        await _player.play(BytesSource(bytesOgg.buffer.asUint8List()));
        return;
      } catch (err3) {
        debugPrint('AudioPlayers: OGG BytesSource also failed: $err3');
      }
    } catch (e) {
      debugPrint('MusicService.playMenu unexpected error: $e');
    } finally {
      _playRequestInProgress = false;
    }
  }

  static void _attachPlayerListeners() {
    try {
      _player.onPlayerStateChanged.listen((state) {
        debugPrint('MusicService: onPlayerStateChanged -> $state');
      });
      _player.onDurationChanged.listen((dur) {
        debugPrint('MusicService: onDurationChanged -> $dur');
      });
      _player.onPositionChanged.listen((pos) {
        // avoid too chatty logging
      });
      _player.onPlayerComplete.listen((_) {
        debugPrint('MusicService: onPlayerComplete');
      });
      _playerListenersAttached = true;
    } catch (e) {
      debugPrint('MusicService: failed to attach listeners: $e');
    }
  }

  /// Debug helper to print current player state and volume
  static void debugState() {
    debugPrint('MusicService.debugState -> volume=$_currentVolume, listenersAttached=$_playerListenersAttached');
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

  /// Verifica si la música se pausó y la reanuda (fix para Android)
  static Future<void> ensurePlayingAfterSfx() async {
    try {
      final state = await _player.getCurrentPosition();
      
      // Si la posición actual no cambió, probablemente está pausada
      await Future.delayed(const Duration(milliseconds: 50));
      final newPosition = await _player.getCurrentPosition();
      
      if (state == newPosition) {
        // Música pausada, reanudarla
        debugPrint('MusicService: música estaba pausada, reanudando...');
        await _player.resume();
      }
    } catch (e) {
      debugPrint('MusicService.ensurePlayingAfterSfx error: $e');
    }
  }
}                                 