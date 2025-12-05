import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'music_service.dart';
import 'sfx_controller.dart'; // Importa el nuevo controlador

class SfxService {
  // Verifica si los SFX están habilitados antes de reproducir
  static bool get _canPlaySfx => SfxController.sfxEnabled;

  // Reproduce el efecto corto de moneda. Usa un AudioPlayer temporal para sonidos cortos.
  static Future<void> playCoin() async {
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('sounds/coin_sfx.mp3'));
      // No esperar a que termine la reproducción; el player se liberará cuando el GC lo recoja.
    } catch (e) {
      debugPrint('SfxService: error reproduciendo coin_sfx.mp3: $e');
    }
  }

  // Reproduce el efecto de sonido de serpiente (hiss) al colisionar
  static Future<void> playSnakeHiss() async {
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('sounds/snake-hissing.mp3'));
      // No esperar a que termine la reproducción; el player se liberará cuando el GC lo recoja.
    } catch (e) {
      debugPrint('SfxService: error reproduciendo snake-hissing.mp3: $e');
    }
  }

  // Reproduce el efecto al recoger una paca (sonido positivo / reabastecimiento)
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

  // Reproduce el sonido de arranque del motor una sola vez (no loop)
  static Future<void> playCarEngine() async {
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    
    final player = AudioPlayer();
    try {
      // Duck the music briefly so the SFX stands out (max 5s)
      MusicService.duckFor(const Duration(seconds: 4));
      // Asegurar volumen al máximo para el SFX (0.0 - 1.0)
      await player.setVolume(1.0);
      // Usar modo de baja latencia para sonidos cortos
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.play(AssetSource('sounds/car-engine.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint('SfxService: error reproduciendo car-engine.mp3: $e');
    }
  }

  // Reproduce el sonido del caballo y baja la música mientras suena, luego la restaura
  static Future<void> playHorseNeigh() async {
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    
    final player = AudioPlayer();
    double previousVolume = MusicService.currentVolume;
    try {
      // calcular objetivo de duck (25% del volumen actual)
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

      await player.play(AssetSource('sounds/horse-neigh.mp3'), volume: 1.0);

      // Espera a la finalización, pero no más de 10s para evitar bloqueos
      try {
        await completer.future.timeout(const Duration(seconds: 10));
      } catch (_) {}
    } catch (e) {
      debugPrint('SfxService: error reproduciendo horse-neigh.mp3: $e');
    } finally {
      // Restaurar volumen previo
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