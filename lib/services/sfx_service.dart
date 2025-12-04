import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class SfxService {
  // Reproduce el efecto corto de moneda. Usa un AudioPlayer temporal para sonidos cortos.
  static Future<void> playCoin() async {
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('coin_sfx.mp3'));
      // No esperar a que termine la reproducción; el player se liberará cuando el GC lo recoja.
    } catch (e) {
      debugPrint('SfxService: error reproduciendo coin_sfx.mp3: $e');
    }
  }
}
