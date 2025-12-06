import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'music_service.dart';
import 'sfx_controller.dart'; // Importa el nuevo controlador
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

/// SfxService: usa instancias separadas de AudioPlayer para cada tipo de SFX
/// para evitar interrumpir la música de fondo y otros efectos
class SfxService {
  static final AudioPlayer _coinPlayer = AudioPlayer();
  static final AudioPlayer _snakePlayer = AudioPlayer();
  static final AudioPlayer _pacaPlayer = AudioPlayer();
  static final AudioPlayer _carEnginePlayer = AudioPlayer();
  static final AudioPlayer _horsePlayer = AudioPlayer();
  static final AudioPlayer _gasPlayer = AudioPlayer();
  static final AudioPlayer _bachePlayer = AudioPlayer();
  static final Map<String, Uint8List> _cache = {};

  // Verifica si los SFX están habilitados antes de reproducir
  static bool get _canPlaySfx => SfxController.sfxEnabled;

  static Future<void> _ensurePlayer(AudioPlayer player) async {
    try {
      // Use mediaPlayer mode so BytesSource is supported on Android.
      await player.setPlayerMode(PlayerMode.mediaPlayer);
      await player.setVolume(1.0);
    } catch (_) {}
  }

  // Reproduce el sonido de moneda //
  static Future<void> playCoin() async {
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    await _ensurePlayer(_coinPlayer);
    const assetKey = 'assets/sounds/coin_sfx.mp3';
    try {
      // Preferir BytesSource (más fiable en APK). Cachear para no recargar.
      final cached = _cache[assetKey];
      if (cached != null) {
        await _coinPlayer.play(BytesSource(cached));
        return;
      }

      // Intentar cargar bytes (con timeout corto)
      final bytesData = await rootBundle.load(assetKey).timeout(const Duration(seconds: 3));
      final bytes = bytesData.buffer.asUint8List();
      _cache[assetKey] = bytes;
      await _coinPlayer.play(BytesSource(bytes));
      return;
    } catch (e) {
      debugPrint('SfxService: BytesSource play failed for coin_sfx: $e');
    }
  }

  // Reproduce el sonido de serpiente //
  static Future<void> playSnakeHiss() async {
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    await _ensurePlayer(_snakePlayer);
    const assetKey = 'assets/sounds/snake-hissing.mp3';
    try {
      final cached = _cache[assetKey];
      if (cached != null) {
        await _snakePlayer.play(BytesSource(cached));
        return;
      }
      final bytesData = await rootBundle.load(assetKey).timeout(const Duration(seconds: 3));
      final bytes = bytesData.buffer.asUint8List();
      _cache[assetKey] = bytes;
      await _snakePlayer.play(BytesSource(bytes));
      return;
    } catch (e) {
      debugPrint('SfxService: BytesSource play failed for snake-hissing: $e');
    }
  }

  static Future<void> playPaca() async {
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    await _ensurePlayer(_pacaPlayer);
    const assetKey = 'assets/sounds/shaken-bush.mp3';
    try {
      final cached = _cache[assetKey];
      if (cached != null) {
        await _pacaPlayer.play(BytesSource(cached), volume: 1.0);
        return;
      }
      final bytesData = await rootBundle.load(assetKey).timeout(const Duration(seconds: 3));
      final bytes = bytesData.buffer.asUint8List();
      _cache[assetKey] = bytes;
      await _pacaPlayer.play(BytesSource(bytes), volume: 1.0);
      return;
    } catch (e) {
      debugPrint('SfxService: error reproduciendo shaken-bush.mp3: $e');
    }
  }

  // Reproduce el sonido de arranque del motor //
  static Future<void> playCarEngine() async {
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    await _ensurePlayer(_carEnginePlayer);
    const assetKey = 'assets/sounds/car-engine.mp3';
    try {
      final cached = _cache[assetKey];
      if (cached != null) {
        await _carEnginePlayer.play(BytesSource(cached), volume: 0.7);
        return;
      }
      final bytesData = await rootBundle.load(assetKey).timeout(const Duration(seconds: 3));
      final bytes = bytesData.buffer.asUint8List();
      _cache[assetKey] = bytes;
      await _carEnginePlayer.play(BytesSource(bytes), volume: 0.7);
      return;
    } catch (e) {
      debugPrint('SfxService: error reproduciendo car-engine.mp3: $e');
    }
  }

  // Reproduce el sonido del caballo //
  static Future<void> playHorseNeigh() async {
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    await _ensurePlayer(_horsePlayer);
    try {
      await _horsePlayer.setVolume(0.8);
      await _horsePlayer.play(AssetSource('sounds/horse-neigh.mp3'), volume: 0.8);
    } catch (e) {
      debugPrint('SfxService: error reproduciendo horse-neigh.mp3: $e');
    }
  }
  
  static Future<void> playUnmoroSound() async {
    if (!_canPlaySfx) return; // No reproducir si SFX desactivados
    // Usa el mismo reproductor que moro (horse)
    await playHorseNeigh();
  }

  // Reproduce el sonido de gas (para carro naranja) //
  static Future<void> playGas() async {
    if (!_canPlaySfx) return;
    await _ensurePlayer(_gasPlayer);
    const assetKey = 'assets/sounds/car-engineq.mp3';
    try {
      final cached = _cache[assetKey];
      if (cached != null) {
        await _gasPlayer.play(BytesSource(cached), volume: 1.0);
        return;
      }
      final bytesData = await rootBundle.load(assetKey).timeout(const Duration(seconds: 3));
      final bytes = bytesData.buffer.asUint8List();
      _cache[assetKey] = bytes;
      await _gasPlayer.play(BytesSource(bytes), volume: 1.0);
      return;
    } catch (e) {
      debugPrint('SfxService: error reproduciendo car-engineq.mp3: $e');
    }
  }

  // Reproduce el sonido de bache (para carro naranja) //
  static Future<void> playBache() async {
    if (!_canPlaySfx) return;
    await _ensurePlayer(_bachePlayer);
    const assetKey = 'assets/sounds/bache.mp3';
    try {
      final cached = _cache[assetKey];
      if (cached != null) {
        await _bachePlayer.play(BytesSource(cached), volume: 1.0);
        return;
      }
      final bytesData = await rootBundle.load(assetKey).timeout(const Duration(seconds: 3));
      final bytes = bytesData.buffer.asUint8List();
      _cache[assetKey] = bytes;
      await _bachePlayer.play(BytesSource(bytes), volume: 1.0);
      return;
    } catch (e) {
      debugPrint('SfxService: error reproduciendo bache.mp3: $e');
    }
  }
}