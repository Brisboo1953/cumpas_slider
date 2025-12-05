import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameOrientation { vertical, horizontal }

class SettingsService {
  static GameOrientation orientation = GameOrientation.vertical;

  static int selectedCarIndex = 0;
  static int selectedSceneIndex = 0;
  // Nombre del jugador //
  static String? playerName;

  static const List<String> availableCars = [
    'orange_car',
    'moro'
  ];

  static String getCarAsset(int index, GameOrientation orientation) {
    if (index < 0 || index >= availableCars.length) index = 0;
    final base = availableCars[index];
    if (orientation == GameOrientation.horizontal) {
      return 'assets/cars/${base}_h.png';
    }
    return 'assets/cars/${base}.png';
  }

  static const List<String> availableScenes = [
    'assets/escenarios/camino.png',
    'assets/escenarios/calle.jpg',
    'assets/escenarios/campo.jpg',
    'assets/escenarios/playa.jpg',
  ];

  static void setOrientation(GameOrientation o) {
    orientation = o;
  }

  static void setSelectedCar(int index) {
    if (index < 0 || index >= availableCars.length) return;
    selectedCarIndex = index;
    if (kDebugMode) {
      debugPrint('SettingsService: selectedCarIndex = $selectedCarIndex');
    }
  }

  static void setSelectedScene(int index) {
    if (index < 0 || index >= availableScenes.length) return;
    selectedSceneIndex = index;
    if (kDebugMode) {
      debugPrint('SettingsService: selectedSceneIndex = $selectedSceneIndex');
    }
  }

  /// Inicia la app con preferencias predeterminadas //
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      orientation = GameOrientation.values[prefs.getInt('orientation') ?? orientation.index];
      selectedCarIndex = prefs.getInt('selectedCarIndex') ?? selectedCarIndex;
      selectedSceneIndex = prefs.getInt('selectedSceneIndex') ?? selectedSceneIndex;
      playerName = prefs.getString('playerName');
      if (kDebugMode) {
        debugPrint('SettingsService.init: orientation=$orientation, car=$selectedCarIndex, scene=$selectedSceneIndex');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SettingsService.init error: $e');
    }
  }

  /// Guarda las opciones de preferencias //
  static Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('orientation', orientation.index);
      await prefs.setInt('selectedCarIndex', selectedCarIndex);
      await prefs.setInt('selectedSceneIndex', selectedSceneIndex);
      if (playerName == null) {
        await prefs.remove('playerName');
      } else {
        await prefs.setString('playerName', playerName!);
      }
      if (kDebugMode) debugPrint('SettingsService.save: saved');
    } catch (e) {
      if (kDebugMode) debugPrint('SettingsService.save error: $e');
    }
  }

  /// Actualiza el nombre del jugador en la memoria//
  static Future<void> setPlayerName(String? name) async {
    playerName = (name == null || name.trim().isEmpty) ? null : name.trim();
    await save();
    if (kDebugMode) debugPrint('SettingsService: playerName set to $playerName');
  }
}
