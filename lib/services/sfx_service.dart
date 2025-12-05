import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'music_service.dart';

class SfxService {
  // Reproduce el sonido de moneda //
  static Future<void> playCoin() async {
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('sounds/coin_sfx.mp3'));
    } catch (e) {
      debugPrint('SfxService: error reproduciendo coin_sfx.mp3: $e');
    }
  }

  // Reproduce el sonido de serpiente //
  static Future<void> playSnakeHiss() async {
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('sounds/snake-hissing.mp3'));
    } catch (e) {
      debugPrint('SfxService: error reproduciendo snake-hissing.mp3: $e');
    }
  }

  static Future<void> playPaca() async {
    final player = AudioPlayer();
    try {
      await player.setVolume(1.0);
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.play(AssetSource('sounds/shaken-bush.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint('SfxService: error reproduciendo shaken-bush.mp3: $e');
    }
  }

  // Reproduce el sonido de arranque del motor //
  static Future<void> playCarEngine() async {
    final player = AudioPlayer();
    try {
      MusicService.duckFor(const Duration(seconds: 4));
      await player.setVolume(1.0);
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.play(AssetSource('sounds/car-engine.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint('SfxService: error reproduciendo car-engine.mp3: $e');
    }
  }

  // Reproduce el sonido del caballo //
  static Future<void> playHorseNeigh() async {
    final player = AudioPlayer();
    double previousVolume = MusicService.currentVolume;
    try {
      final target = (previousVolume * 0.25).clamp(0.0, 1.0);
      await MusicService.setVolume(target);

      await player.setVolume(1.0);
      await player.setPlayerMode(PlayerMode.lowLatency);

      final completer = Completer<void>();
      late StreamSubscription sub;
      sub = player.onPlayerComplete.listen((_) {
        completer.complete();
        sub.cancel();
      });

      await player.play(AssetSource('sounds/horse-neigh.mp3'), volume: 1.0);

      try {
        await completer.future.timeout(const Duration(seconds: 10));
      } catch (_) {}
    } catch (e) {
      debugPrint('SfxService: error reproduciendo horse-neigh.mp3: $e');
    } finally {
      try {
        await MusicService.setVolume(previousVolume);
      } catch (_) {}
    }
  }
}