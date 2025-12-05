import 'package:flutter/foundation.dart';

class SfxController {
  static bool _sfxEnabled = true;
  
  /// Obtener estado actual de los SFX
  static bool get sfxEnabled => _sfxEnabled;
  
  /// Activar/desactivar SFX
  static void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
    if (kDebugMode) {
      debugPrint('SFX ${enabled ? "activados" : "desactivados"}');
    }
  }
  
  /// Alternar estado de SFX
  static void toggleSfx() {
    _sfxEnabled = !_sfxEnabled;
    if (kDebugMode) {
      debugPrint('SFX ${_sfxEnabled ? "activados" : "desactivados"}');
    }
  }
}