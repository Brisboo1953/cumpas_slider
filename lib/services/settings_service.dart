import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameOrientation { vertical, horizontal }

class SettingsService {
  // Valores por defecto
  static GameOrientation orientation = GameOrientation.vertical;

  // Índices seleccionados
  static int selectedCarIndex = 0;
  static int selectedSceneIndex = 0;
  static int selectedProfilePicture = 0; // NUEVO: índice de foto de perfil
  // Nombre del jugador (persistido en SharedPreferences)
  static String? playerName;

  // Rutas a assets disponibles (ajusta aquí si añades más)
  static const List<String> availableCars = [
    'orange_car',
    'moro',
    'unmoro'
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

  // NUEVO: Método para guardar la foto de perfil seleccionada
  static void setSelectedProfilePicture(int index) {
    if (index < 0 || index >= 5) return; // Solo 5 fotos disponibles
    selectedProfilePicture = index;
    if (kDebugMode) {
      debugPrint('SettingsService: selectedProfilePicture = $selectedProfilePicture');
    }
  }

  /// Inicializa desde SharedPreferences (llamar antes de runApp)
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      orientation = GameOrientation.values[prefs.getInt('orientation') ?? orientation.index];
      selectedCarIndex = prefs.getInt('selectedCarIndex') ?? selectedCarIndex;
      selectedSceneIndex = prefs.getInt('selectedSceneIndex') ?? selectedSceneIndex;
      selectedProfilePicture = prefs.getInt('selectedProfilePicture') ?? selectedProfilePicture; // NUEVO
      playerName = prefs.getString('playerName');
      if (kDebugMode) {
        debugPrint('SettingsService.init: orientation=$orientation, car=$selectedCarIndex, scene=$selectedSceneIndex, profilePic=$selectedProfilePicture');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SettingsService.init error: $e');
    }
  }

  /// Guarda las opciones actuales en SharedPreferences
  static Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('orientation', orientation.index);
      await prefs.setInt('selectedCarIndex', selectedCarIndex);
      await prefs.setInt('selectedSceneIndex', selectedSceneIndex);
      await prefs.setInt('selectedProfilePicture', selectedProfilePicture); // NUEVO
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

  /// Actualiza el nombre del jugador en memoria y lo persiste.
  static Future<void> setPlayerName(String? name) async {
    playerName = (name == null || name.trim().isEmpty) ? null : name.trim();
    await save();
    if (kDebugMode) debugPrint('SettingsService: playerName set to $playerName');
  }
}