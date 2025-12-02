enum GameOrientation { vertical, horizontal }

class SettingsService {
  // Valor por defecto
  static GameOrientation orientation = GameOrientation.vertical;

  static void setOrientation(GameOrientation o) {
    orientation = o;
  }
}
