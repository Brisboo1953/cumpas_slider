import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'music_service.dart';
import 'sfx_controller.dart'; // Importa el nuevo controlador

class SfxService {
  // Verifica si los SFX están habilitados antes de reproducir
  static bool get _canPlaySfx => SfxController.sfxEnabled;

  // Reproduce el sonido de moneda //
  static Future<void> playCoin() async {
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('sounds/coin_sfx.mp3'));
    } catch (e) {
      debugPrint('SfxService: error reproduciendo coin_sfx.mp3: $e');
    }
  }

  // Reproduce el sonido de serpiente //
  static Future<void> playSnakeHiss() async {
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('sounds/snake-hissing.mp3'));
    } catch (e) {
      debugPrint('SfxService: error reproduciendo snake-hissing.mp3: $e');
    }
  }

  static Future<void> playPaca() async {
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    
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
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    
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
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    
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
  
  static Future<void> playUnmoroSound() async {
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    
    final player = AudioPlayer();
    double previousVolume = MusicService.currentVolume;
    try {
      // Bajar el volumen de la música mientras suena el efecto
      final target = (previousVolume * 0.25).clamp(0.0, 1.0);
      await MusicService.setVolume(target);

      await player.setVolume(1.0);
      await player.setPlayerMode(PlayerMode.lowLatency);

      // Reproducir y esperar a que termine
      final completer = Completer<void>();
      late StreamSubscription sub;
      sub = player.onPlayerComplete.listen((_) {
        completer.complete();
        sub.cancel();
      });

      // Usar el mismo sonido que moro (horse-neigh.mp3)
      await player.play(AssetSource('sounds/horse-neigh.mp3'), volume: 1.0);

      // Espera a la finalización, pero no más de 10s para evitar bloqueos
      try {
        await completer.future.timeout(const Duration(seconds: 10));
      } catch (_) {}
    } catch (e) {
      debugPrint('SfxService: error reproduciendo horse-neigh.mp3 para unmoro: $e');
    } finally {
      // Restaurar volumen previo
      try {
        await MusicService.setVolume(previousVolume);
      } catch (_) {}
    }
  }
}