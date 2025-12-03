import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameOrientation { vertical, horizontal }

class SettingsService {
  // Valores por defecto
  static GameOrientation orientation = GameOrientation.vertical;

  // Índices seleccionados
  static int selectedCarIndex = 0;
  static int selectedSceneIndex = 0;

  // Rutas a assets disponibles (ajusta aquí si añades más)
  static const List<String> availableCars = [
    // store base names; actual asset depends on orientation
    'orange_car',
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
  ];

  static void setOrientation(GameOrientation o) {
    orientation = o;
  }

  static void setSelectedCar(int index) {
    if (index < 0 || index >= availableCars.length) return;
    selectedCarIndex = index;
    if (kDebugMode) {
      print('SettingsService: selectedCarIndex = $selectedCarIndex');
    }
  }

  static void setSelectedScene(int index) {
    if (index < 0 || index >= availableScenes.length) return;
    selectedSceneIndex = index;
    if (kDebugMode) {
      print('SettingsService: selectedSceneIndex = $selectedSceneIndex');
    }
  }

  /// Inicializa desde SharedPreferences (llamar antes de runApp)
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      orientation = GameOrientation.values[prefs.getInt('orientation') ?? orientation.index];
      selectedCarIndex = prefs.getInt('selectedCarIndex') ?? selectedCarIndex;
      selectedSceneIndex = prefs.getInt('selectedSceneIndex') ?? selectedSceneIndex;
      if (kDebugMode) {
        print('SettingsService.init: orientation=$orientation, car=$selectedCarIndex, scene=$selectedSceneIndex');
      }
    } catch (e) {
      if (kDebugMode) print('SettingsService.init error: $e');
    }
  }

  /// Guarda las opciones actuales en SharedPreferences
  static Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('orientation', orientation.index);
      await prefs.setInt('selectedCarIndex', selectedCarIndex);
      await prefs.setInt('selectedSceneIndex', selectedSceneIndex);
      if (kDebugMode) print('SettingsService.save: saved');
    } catch (e) {
      if (kDebugMode) print('SettingsService.save error: $e');
    }
  }
}
