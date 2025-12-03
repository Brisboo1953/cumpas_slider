import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
// * IMPORTACIÓN CORREGIDA para la estructura lib/widgets/draggable_car.dart *
import 'widgets/draggable_car.dart'; 
import 'services/settings_service.dart';
import 'services/supabase_service.dart';

// Asegúrate de que estas importaciones de servicios estén disponibles si las usas.
// Si no tienes estas clases, puedes borrarlas temporalmente para que compile.
//import 'services/music_service.dart';
//import 'services/settings_service.dart';

// GameOrientation is defined in settings_service.dart

const double _coinSize = 40.0;
// * MODIFICACIÓN: Pacas más grandes (de 60.0 a 80.0) *
const double _pacaSize = 80.0; 
const double _carVerticalOffset = 20.0; // Distancia del carro al borde inferior
const double _BACKGROUND_HEIGHT = 600.0; // Altura original de la imagen del camino
// La altura de la imagen debe ser igual a la constante _BACKGROUND_HEIGHT.

class GamePage extends StatefulWidget {
  final String? playerName;
  const GamePage({super.key, this.playerName});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  // carX guarda el desplazamiento horizontal desde el centro (reportado por DraggableCar)
  double carX = 0; 
  double carY = 0; 
  double carWidth = 100;
  double carHeight = 60;
  
  // Sizes that adapt to orientation
  double coinSize = _coinSize;
  double pacaSizeLocal = _pacaSize;

  List<Offset> coins = [];
  List<Offset> pacas = [];

  int score = 0;
  double gasoline = 100;
  
  // * NUEVO: Estado del juego *
  bool isGameOver = false;

  Timer? objectTimer;
  Timer? moveTimer;
  Timer? gasolineTimer;

  double backgroundOffset = 0;
  // Velocidad inicial del fondo
  double backgroundSpeed = 5; 
  
  // * NUEVO: Variables para el control de Nivel y Dificultad *
  int currentLevel = 1;
  int nextLevelScore = 500; // Puntuación inicial para subir al Nivel 2

  GameOrientation orientation = GameOrientation.vertical;

  @override
  void initState() {
    super.initState();
    // Load orientation from settings and adapt sizes
    orientation = SettingsService.orientation;
    if (orientation == GameOrientation.horizontal) {
      carWidth = 140;
      carHeight = 50;
      coinSize = 28.0;
      pacaSizeLocal = 60.0;
    } else {
      carWidth = 100;
      carHeight = 60;
      coinSize = _coinSize;
      pacaSizeLocal = _pacaSize;
    }
    // Intenta parar la música, ajusta si tus servicios no existen
    // MusicService.stop(); 

    _startGasoline();
    _startObjects();
    _startMovement();
  }
  
  // Detiene todos los temporizadores al final del juego
  void _stopGame() {
    moveTimer?.cancel();
    objectTimer?.cancel();
    gasolineTimer?.cancel();
    moveTimer = null;
    objectTimer = null;
    gasolineTimer = null;
  }

  void _pauseGame() {
    moveTimer?.cancel();
    objectTimer?.cancel();
    gasolineTimer?.cancel();
    moveTimer = null;
    objectTimer = null;
    gasolineTimer = null;
  }

  void _resumeGame() {
    // Evita duplicar timers
    if (moveTimer == null || !(moveTimer?.isActive ?? false)) _startMovement();
    if (objectTimer == null || !(objectTimer?.isActive ?? false)) _startObjects();
    if (gasolineTimer == null || !(gasolineTimer?.isActive ?? false)) _startGasoline();
  }

  // * Lógica para subir de nivel y aumentar la velocidad *
  void _updateLevel() {
    if (score >= nextLevelScore) {
      setState(() {
        currentLevel++;
        backgroundSpeed += 2; // Aumentamos la velocidad de forma más notoria
        
        // Define el siguiente objetivo de puntuación con un incremento fijo (500)
        // Esto hace la progresión más lineal y controlable.
        nextLevelScore += 500; 
      });
      debugPrint("LEVEL UP! Level: $currentLevel, Speed: $backgroundSpeed, Next Score: $nextLevelScore");
    }
  }

  // GASOLINA
  void _startGasoline() {
    gasolineTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (gasoline <= 0) {
        gasoline = 0;
        timer.cancel();
        // Lógica de Game Over
        setState(() {
          isGameOver = true;
          _stopGame(); // Asegura que se detengan todos los movimientos
        });
        
        // DEBUG: Muestra en consola que Game Over se activó
        debugPrint("GAME OVER TRIGGERED. Score: $score");
        
        // Guarda la puntuación si hay un nombre válido
        if (widget.playerName != null && widget.playerName!.trim().isNotEmpty) {
          SupabaseService().insertScore(name: widget.playerName!.trim(), score: score);
        }

        return;
      }
      setState(() => gasoline -= 0.5);
    });
  }

  // GENERA OBJETOS
  void _startObjects() {
    objectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Si el juego ha terminado, no generamos más objetos.
      if (isGameOver) return; 

      _spawnCoins(1);
      if (timer.tick % 3 == 0) _spawnPaca(1);
    });
  }

  void _spawnCoins(int count) {
    final random = Random();
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    for (int i = 0; i < count; i++) {
      if (orientation == GameOrientation.vertical) {
        coins.add(Offset(random.nextDouble() * (w - coinSize), -coinSize));
      } else {
        // spawn to the right off-screen with random Y
        coins.add(Offset(w + coinSize, random.nextDouble() * (h - coinSize)));
      }
    }
  }

  void _spawnPaca(int count) {
    final random = Random();
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    for (int i = 0; i < count; i++) {
      if (orientation == GameOrientation.vertical) {
        pacas.add(Offset(random.nextDouble() * (w - pacaSizeLocal), -pacaSizeLocal));
      } else {
        // spawn to the right off-screen with random Y
        pacas.add(Offset(w + pacaSizeLocal, random.nextDouble() * (h - pacaSizeLocal)));
      }
    }
  }

  // MUEVE OBJETOS Y FONDO
  void _startMovement() {
    moveTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      // Si el juego ha terminado, no movemos nada.
      if (isGameOver) return; 

      final h = MediaQuery.of(context).size.height;

      setState(() {
        backgroundOffset += backgroundSpeed;
        
        // * Reinicio suave del fondo para efecto infinito sin espacios en blanco *
        // En lugar de restar cuando llega a un tile, se mantiene un offset continuo
        // que genera tiles adicionales según sea necesario
        if (orientation == GameOrientation.vertical) {
          // Para vertical: resetear cada 2 alturas de background para evitar acumulación
          if (backgroundOffset >= _BACKGROUND_HEIGHT * 3) {
            backgroundOffset -= _BACKGROUND_HEIGHT * 2;
          }
        } else {
          final screenW = MediaQuery.of(context).size.width;
          // Para horizontal: resetear cada 2 anchos de screen
          if (backgroundOffset >= screenW * 3) {
            backgroundOffset -= screenW * 2;
          }
        }

        // Mueve objetos según orientación
        if (orientation == GameOrientation.vertical) {
          coins = coins
            .map((c) => Offset(c.dx, c.dy + backgroundSpeed * 0.8))
            .where((c) => c.dy < h + 50)
            .toList();

          pacas = pacas
            .map((p) => Offset(p.dx, p.dy + backgroundSpeed * 0.8))
            .where((p) => p.dy < h + 50)
            .toList();
        } else {
          // horizontal: move objects left as background scrolls right->left
          coins = coins
            .map((c) => Offset(c.dx - backgroundSpeed * 0.8, c.dy))
            .where((c) => c.dx > -50)
            .toList();

          pacas = pacas
            .map((p) => Offset(p.dx - backgroundSpeed * 0.8, p.dy))
            .where((p) => p.dx > -50)
            .toList();
        }

        // La verificación de colisión sigue aquí, sincronizada con el juego.
        _checkCollision(); 
      });
    });
  }

  // RECT DEL AUTO - IMPLEMENTACIÓN SIN CAMBIOS, usa la nueva carX
  Rect _carRect() {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    // El padding inferior de SafeArea (usado para la parte segura del teléfono)
    final bottomPadding = MediaQuery.of(context).padding.bottom; 

    if (orientation == GameOrientation.vertical) {
      // Cálculo de la posición X del borde izquierdo (Left)
      final left = (screenW / 2) + carX - (carWidth / 2);

      // Cálculo de la posición Y del borde superior (Top)
      final top = screenH - _carVerticalOffset - carHeight - bottomPadding;

      return Rect.fromLTWH(left, top, carWidth, carHeight);
    } else {
          // Horizontal: el carro se mueve en el eje Y and is rendered inside a
          // left-aligned area with a left padding of 20 and a SizedBox width of
          // `screenW * 0.5`. Compute the left coordinate so the collision rect
          // matches the visual position of the widget.
          const double horizontalLeftPadding = 20.0;
          final left = horizontalLeftPadding;
      final top = (screenH / 2) + carY - (carHeight / 2);
      return Rect.fromLTWH(left, top, carWidth, carHeight);
    }
  }

  void _checkCollision() {
    final car = _carRect();
    // Reduce hitbox slightly so collisions happen a bit later (less false/early hits)
    const double collisionPadding = 8.0;
    final carHit = car.deflate(collisionPadding);
    bool scoreChanged = false;

    // Colisión con Monedas
    coins.removeWhere((c) {
      final r = Rect.fromLTWH(c.dx, c.dy, coinSize, coinSize).deflate(4.0);
      if (carHit.overlaps(r)) {
        // Monedas incrementan solo la puntuación
        score += 10;
        scoreChanged = true;
        return true;
      }
      return false;
    });

    // Colisión con Pacas
    pacas.removeWhere((p) {
      final r = Rect.fromLTWH(p.dx, p.dy, pacaSizeLocal, pacaSizeLocal).deflate(6.0);
      if (carHit.overlaps(r)) {
        // Pacas aumentan la gasolina (reabastecimiento)
        gasoline = min(100, gasoline + 30);
        scoreChanged = true;
        return true;
      }
      return false;
    });
    
    // LLAMADA PARA REVISAR EL NIVEL si la puntuación cambió
    if (scoreChanged) {
      _updateLevel();
    }
  }

  @override
  void dispose() {
    _stopGame();
    super.dispose();
  }
  
  // WIDGET: Ventana de Game Over
  Widget _buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        // Fondo más oscuro para asegurar visibilidad
        color: Colors.black87, 
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                // Sombra más visible
                BoxShadow(blurRadius: 15, color: Colors.black, offset: Offset(0, 8)) 
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "¡Game Over!",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Puntuación Final: $score",
                  style: const TextStyle(fontSize: 24, color: Colors.black87),
                ),
                // * Muestra el nivel final *
                Text(
                  "Nivel Alcanzado: $currentLevel",
                  style: const TextStyle(fontSize: 24, color: Colors.blueAccent),
                ),
                const SizedBox(height: 30),
                // Botón de salir (cierra la página o navega hacia atrás)
                ElevatedButton.icon(
                  onPressed: () {
                    // Cierra la página de juego y regresa a la pantalla anterior
                    Navigator.pop(context); 
                  },
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text("Salir", style: TextStyle(fontSize: 20)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // FONDO (USANDO TRES IMÁGENES PARA DESPLAZAMIENTO FLUIDO)
            Positioned.fill(
              child: Builder(builder: (context) {
                final sceneAsset = SettingsService.availableScenes[SettingsService.selectedSceneIndex];
                final screenW = MediaQuery.of(context).size.width;
                final screenH = MediaQuery.of(context).size.height;
                if (orientation == GameOrientation.vertical) {
                  // Tile the background using the actual screen height so there
                  // are no sudden gaps. We compute a base Y that moves as
                  // backgroundOffset increases and then draw 3 tiles to cover
                  // the viewport.
                  final baseY = (backgroundOffset % screenH) - screenH;
                  return Stack(
                    children: List.generate(3, (i) {
                      final top = baseY + i * screenH;
                      return Positioned(
                        top: top,
                        left: 0,
                        right: 0,
                        height: screenH,
                        child: Image.asset(sceneAsset, height: screenH, fit: BoxFit.cover),
                      );
                    }),
                  );
                } else {
                  // Horizontal scrolling: use screen width to tile horizontally.
                  final baseX = -(backgroundOffset % screenW);
                  return Stack(
                    children: List.generate(3, (i) {
                      final left = baseX + i * screenW;
                      return Positioned(
                        left: left,
                        top: 0,
                        width: screenW,
                        bottom: 0,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: SizedBox(
                            width: screenW,
                            height: screenH,
                            child: Image.asset(sceneAsset, fit: BoxFit.cover),
                          ),
                        ),
                      );
                    }),
                  );
                }
              }),
            ),

            // OBJETOS (Monedas y Pacas)
            ...coins.map((c) => Positioned(
                  left: c.dx,
                  top: c.dy,
                  child: Image.asset("assets/coin.png", width: coinSize),
                )),
            ...pacas.map((p) => Positioned(
                  left: p.dx,
                  top: p.dy,
                  // Usa tamaño adaptativo
                  child: Image.asset("assets/paca.png", width: pacaSizeLocal),
                )),

            // OBJETOS DEL JUEGO se renderizan antes de la UI

            // Draw the DraggableCar (below the HUD) so the HUD overlays on top.
            if (orientation == GameOrientation.vertical)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: _carVerticalOffset),
                  child: DraggableCar(
                    imagePath: SettingsService.getCarAsset(SettingsService.selectedCarIndex, SettingsService.orientation),
                    width: carWidth,
                    height: carHeight,
                    verticalMovement: false,
                    onXPositionChanged: (newX) {
                      if (isGameOver) return;
                      setState(() {
                        carX = newX;
                      });
                    },
                    onYPositionChanged: (newY) {
                      if (isGameOver) return;
                      setState(() {
                        carY = newY;
                      });
                    },
                  ),
                ),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: MediaQuery.of(context).size.height,
                    child: DraggableCar(
                      imagePath: SettingsService.getCarAsset(SettingsService.selectedCarIndex, SettingsService.orientation),
                      width: carWidth,
                      height: carHeight,
                      verticalMovement: true,
                      onXPositionChanged: (newX) {
                        if (isGameOver) return;
                        setState(() {
                          carX = newX;
                        });
                      },
                      onYPositionChanged: (newY) {
                        if (isGameOver) return;
                        setState(() {
                          carY = newY;
                        });
                      },
                    ),
                  ),
                ),
              ),

            // SCORE Y GASOLINA (UI)
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Mejor alineación
                children: [
                  Text(
                    "Score: $score",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  // * Muestra el nivel actual *
                  Text(
                    "Nivel: $currentLevel",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 200,
                    height: 20,
                    decoration: BoxDecoration( // Agregué decoración para visibilidad
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect( // Recorta la barra de color
                      borderRadius: BorderRadius.circular(10),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft, // Asegura que crezca de izquierda a derecha
                        widthFactor: gasoline / 100,
                        child: Container(color: gasoline > 20 ? Colors.green : Colors.red),
                      ),
                    ),
                  )
                ],
              ),
            ),
            // PAUSE BUTTON (top-right)
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.pause_circle_filled, size: 36, color: Colors.white),
                onPressed: () async {
                  // Pause game and show confirmation
                  _pauseGame();
                  final wantExit = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => AlertDialog(
                      title: const Text('¿Salir?'),
                      content: const Text('¿Seguro que deseas salir? Perderás tu progreso.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Continuar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Salir', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (!mounted) return;
                  if (wantExit == true) {
                    // No guardar la puntuación al salir desde pausa
                    Navigator.of(context).pop();
                  } else {
                    // Reanudar
                    _resumeGame();
                  }
                },
              ),
            ),
            
            // GAME OVER CONDICIONAL: Debe ir al final para superponerse a todo
            if (isGameOver) _buildGameOverOverlay(),
          ],
        ),
      ),
    );
  }
}