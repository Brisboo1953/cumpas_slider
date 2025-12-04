import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'widgets/draggable_car.dart'; 
import 'services/settings_service.dart';
import 'services/supabase_service.dart';
import 'services/sfx_service.dart';

// Definiciones de constantes para objetos
const double _coinSize = 40.0;
const double _pacaSize = 80.0; 
const double _snakeSize = 60.0; 
const double _snakeGasolinePenalty = 20.0; 
const double _carVerticalOffset = 20.0; 
const double _BACKGROUND_HEIGHT = 600.0; 

class GamePage extends StatefulWidget {
  final String? playerName;
  const GamePage({super.key, this.playerName});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  // Posición y tamaño del auto
  double carX = 0; 
  double carY = 0; 
  double carWidth = 100;
  double carHeight = 60;
  
  // Tamaños adaptativos a la orientación
  double coinSize = _coinSize;
  double pacaSizeLocal = _pacaSize;
  double snakeSizeLocal = _snakeSize; 

  // Listas de objetos en el juego
  List<Offset> coins = [];
  List<Offset> pacas = [];
  List<Offset> snakes = []; 

  // Estado del juego
  int score = 0;
  double gasoline = 100;
  bool isGameOver = false;
  bool isPaused = false; // Nuevo estado para pausa

  // Temporizadores
  Timer? objectTimer;
  Timer? moveTimer;
  Timer? gasolineTimer;

  // Movimiento
  double backgroundOffset = 0;
  double backgroundSpeed = 5; 
  
  // Nivel de dificultad
  int currentLevel = 1;
  int nextLevelScore = 500; 

  // La orientación ahora usa el tipo GameOrientation de SettingsService.
  GameOrientation orientation = GameOrientation.vertical;

  @override
  void initState() {
    super.initState();
    
    // Obteniendo la orientación desde SettingsService para inicializar el estado
    orientation = SettingsService.orientation;
    
    // Detectar si el carro seleccionado es "moro" (índice 1)
    final isMoroCar = SettingsService.selectedCarIndex == 1;
    
    if (orientation == GameOrientation.horizontal) {
      // Tamaños más grandes para el caballo moro en modo horizontal
      carWidth = isMoroCar ? 220 : 140;
      carHeight = isMoroCar ? 100 : 50;
      coinSize = 28.0;
      pacaSizeLocal = 60.0;
      snakeSizeLocal = 45.0; 
    } else {
      // Tamaños más grandes para el caballo moro en modo vertical
      carWidth = isMoroCar ? 160 : 100;
      carHeight = isMoroCar ? 130 : 60;
      coinSize = _coinSize;
      pacaSizeLocal = _pacaSize;
      snakeSizeLocal = _snakeSize; 
    }

    _startGasoline();
    _startObjects();
    _startMovement();

    // Si el carro seleccionado es el orange_car (índice 0), reproducir sonido de arranque una vez
    final isOrangeCar = SettingsService.selectedCarIndex == 0;
    if (isOrangeCar) {
      try {
        SfxService.playCarEngine();
      } catch (_) {}
    } else if (isMoroCar) {
      try {
        SfxService.playHorseNeigh();
      } catch (_) {}
    }
  }
  
  void _stopGame() {
    moveTimer?.cancel();
    objectTimer?.cancel();
    gasolineTimer?.cancel();
    moveTimer = null;
    objectTimer = null;
    gasolineTimer = null;
  }

  void _pauseGame() {
    setState(() {
      isPaused = true;
    });
    moveTimer?.cancel();
    objectTimer?.cancel();
    gasolineTimer?.cancel();
    moveTimer = null;
    objectTimer = null;
    gasolineTimer = null;
  }

  void _resumeGame() {
    setState(() {
      isPaused = false;
    });
    if (moveTimer == null || !(moveTimer?.isActive ?? false)) _startMovement();
    if (objectTimer == null || !(objectTimer?.isActive ?? false)) _startObjects();
    if (gasolineTimer == null || !(gasolineTimer?.isActive ?? false)) _startGasoline();
  }

  void _updateLevel() {
    if (score >= nextLevelScore) {
      setState(() {
        currentLevel++;
        backgroundSpeed += 2; 
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
        
        setState(() {
          isGameOver = true;
          _stopGame(); 
        });
        
        debugPrint("GAME OVER TRIGGERED. Score: $score");
        
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
      if (isGameOver) return; 

      _spawnCoins(1);
      if (timer.tick % 3 == 0) _spawnPaca(1);
      if (timer.tick % 4 == 0) _spawnSnake(1); 
    });
  }

  void _spawnCoins(int count) {
    final random = Random();
    final w = MediaQuery.of(context).size.width;

    for (int i = 0; i < count; i++) {
      if (orientation == GameOrientation.vertical) {
        coins.add(Offset(random.nextDouble() * (w - coinSize), -coinSize));
      } else {
        coins.add(Offset(w + coinSize, random.nextDouble() * (MediaQuery.of(context).size.height - coinSize)));
      }
    }
  }

  void _spawnPaca(int count) {
    final random = Random();
    final w = MediaQuery.of(context).size.width;

    for (int i = 0; i < count; i++) {
      if (orientation == GameOrientation.vertical) {
        pacas.add(Offset(random.nextDouble() * (w - pacaSizeLocal), -pacaSizeLocal));
      } else {
        pacas.add(Offset(w + pacaSizeLocal, random.nextDouble() * (MediaQuery.of(context).size.height - pacaSizeLocal)));
      }
    }
  }
  
  // FUNCIÓN PARA GENERAR SERPIENTES
  void _spawnSnake(int count) {
    final random = Random();
    final w = MediaQuery.of(context).size.width;

    for (int i = 0; i < count; i++) {
      if (orientation == GameOrientation.vertical) {
        snakes.add(Offset(random.nextDouble() * (w - snakeSizeLocal), -snakeSizeLocal));
      } else {
        snakes.add(Offset(w + snakeSizeLocal, random.nextDouble() * (MediaQuery.of(context).size.height - snakeSizeLocal)));
      }
    }
  }

  // MUEVE OBJETOS Y FONDO
  void _startMovement() {
    moveTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (isGameOver || isPaused) return; 

      final h = MediaQuery.of(context).size.height;
      final w = MediaQuery.of(context).size.width;

      setState(() {
        backgroundOffset += backgroundSpeed;
        
        // Lógica de desplazamiento del fondo mejorada para evitar el "corte" en modo vertical
        if (orientation == GameOrientation.vertical) {
          // Usamos la altura de la pantalla (h) para calcular el ciclo de repetición.
          if (backgroundOffset >= h * 3) {
            backgroundOffset -= h * 2;
          }
        } else {
          // Lógica para horizontal (que ya usaba el ancho de pantalla)
          if (backgroundOffset >= w * 3) {
            backgroundOffset -= w * 2;
          }
        }

        // Mueve objetos según orientación
        if (orientation == GameOrientation.vertical) {
          // Mover objetos con la misma velocidad del fondo para sincronía visual
          coins = coins
            .map((c) => Offset(c.dx, c.dy + backgroundSpeed))
            .where((c) => c.dy < h + 50)
            .toList();

          pacas = pacas
            .map((p) => Offset(p.dx, p.dy + backgroundSpeed))
            .where((p) => p.dy < h + 50)
            .toList();
            
          snakes = snakes 
            .map((s) => Offset(s.dx, s.dy + backgroundSpeed))
            .where((s) => s.dy < h + 50)
            .toList();
            
        } else {
          // horizontal: move objects left as background scrolls right->left
          coins = coins
            .map((c) => Offset(c.dx - backgroundSpeed, c.dy))
            .where((c) => c.dx > -50)
            .toList();

          pacas = pacas
            .map((p) => Offset(p.dx - backgroundSpeed, p.dy))
            .where((p) => p.dx > -50)
            .toList();
            
          snakes = snakes 
            .map((s) => Offset(s.dx - backgroundSpeed, s.dy))
            .where((s) => s.dx > -50)
            .toList();
        }

        _checkCollision(); 
      });
    });
  }

  // RECT DEL AUTO
  Rect _carRect() {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    final bottomPadding = MediaQuery.of(context).padding.bottom; 

    if (orientation == GameOrientation.vertical) {
      final left = (screenW / 2) + carX - (carWidth / 2);
      final top = screenH - _carVerticalOffset - carHeight - bottomPadding;
      return Rect.fromLTWH(left, top, carWidth, carHeight);
    } else {
      const double horizontalLeftPadding = 20.0;
      final left = horizontalLeftPadding;
      final top = (screenH / 2) + carY - (carHeight / 2);
      return Rect.fromLTWH(left, top, carWidth, carHeight);
    }
  }

  void _checkCollision() {
    final car = _carRect();
    const double collisionPadding = 8.0;
    final carHit = car.deflate(collisionPadding);
    bool scoreChanged = false;
    bool gasolineChanged = false;

    // Colisión con Monedas
    coins.removeWhere((c) {
      final r = Rect.fromLTWH(c.dx, c.dy, coinSize, coinSize).deflate(4.0);
      if (carHit.overlaps(r)) {
        score += 10;
        // Reproducir efecto de sonido al recoger moneda
        try {
          SfxService.playCoin();
        } catch (_) {}
        scoreChanged = true;
        return true;
      }
      return false;
    });

    // Colisión con Pacas
    pacas.removeWhere((p) {
      final r = Rect.fromLTWH(p.dx, p.dy, pacaSizeLocal, pacaSizeLocal).deflate(6.0);
      if (carHit.overlaps(r)) {
        gasoline = min(100, gasoline + 30);
        gasolineChanged = true;
        // Reproducir efecto de sonido al recoger paca
        try {
          SfxService.playPaca();
        } catch (_) {}
        return true;
      }
      return false;
    });
    
    // COLISIÓN CON SERPIENTES (Obstáculo que quita gasolina)
    snakes.removeWhere((s) {
      final r = Rect.fromLTWH(s.dx, s.dy, snakeSizeLocal, snakeSizeLocal).deflate(6.0);
      if (carHit.overlaps(r)) {
        gasoline = max(0, gasoline - _snakeGasolinePenalty);
        gasolineChanged = true;
        // Reproducir efecto de sonido al tocar serpiente
        try {
          SfxService.playSnakeHiss();
        } catch (_) {}
        // No incrementa la puntuación
        return true;
      }
      return false;
    });
    
    // LLAMADA PARA REVISAR EL NIVEL
    if (scoreChanged) {
      _updateLevel();
    }
    
    // Forzar la actualización del estado si algo cambió
    if (scoreChanged || gasolineChanged) {
      setState(() {});
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
        color: Colors.black87, 
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
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
                Text(
                  "Nivel Alcanzado: $currentLevel",
                  style: const TextStyle(fontSize: 24, color: Colors.blueAccent),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
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

  // WIDGET: Ventana de Pausa
  Widget _buildPauseOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(blurRadius: 15, color: Colors.black, offset: Offset(0, 8))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Juego en Pausa",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "Puntuación Actual: $score",
                  style: const TextStyle(fontSize: 24, color: Colors.black87),
                ),
                Text(
                  "Nivel Actual: $currentLevel",
                  style: const TextStyle(fontSize: 24, color: Colors.blueAccent),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _resumeGame();
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Continuar", style: TextStyle(fontSize: 20)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
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
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text("Salir", style: TextStyle(fontSize: 20)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget personalizado para el botón de pausa
  Widget _buildPauseButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: _PauseButton(
        onTap: () {
          if (isGameOver) return;
          if (isPaused) {
            _resumeGame();
          } else {
            _pauseGame();
          }
        },
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
                  // backgroundOffset % screenH asegura que el desplazamiento se sincronice con la altura de la pantalla
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

            // OBJETOS (Monedas, Pacas y Serpientes)
            ...coins.map((c) => Positioned(
                left: c.dx,
                top: c.dy,
                child: Image.asset("assets/coin.png", width: coinSize),
              )),
            ...pacas.map((p) => Positioned(
                left: p.dx,
                top: p.dy,
                child: Image.asset("assets/paca.png", width: pacaSizeLocal),
              )),
            ...snakes.map((s) => Positioned(
                left: s.dx,
                top: s.dy,
                child: Image.asset("assets/snake.png", width: snakeSizeLocal),
              )),
            

            // Draw the DraggableCar
            if (orientation == GameOrientation.vertical)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: _carVerticalOffset),
                  child: DraggableCar(
                    imagePath: SettingsService.getCarAsset(SettingsService.selectedCarIndex, orientation),
                    width: carWidth,
                    height: carHeight,
                    verticalMovement: false,
                    onXPositionChanged: (newX) {
                      if (isGameOver || isPaused) return;
                      setState(() {
                        carX = newX;
                      });
                    },
                    onYPositionChanged: (newY) {
                      if (isGameOver || isPaused) return;
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
                      imagePath: SettingsService.getCarAsset(SettingsService.selectedCarIndex, orientation),
                      width: carWidth,
                      height: carHeight,
                      verticalMovement: true,
                      onXPositionChanged: (newX) {
                        if (isGameOver || isPaused) return;
                        setState(() {
                          carX = newX;
                        });
                      },
                      onYPositionChanged: (newY) {
                        if (isGameOver || isPaused) return;
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
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(
                    "Score: $score",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
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
                    decoration: BoxDecoration( 
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect( 
                      borderRadius: BorderRadius.circular(10),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft, 
                        widthFactor: gasoline / 100,
                        child: Container(color: gasoline > 20 ? Colors.green : Colors.red),
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            // BOTÓN DE PAUSA PERSONALIZADO
            _buildPauseButton(),
            
            // OVERLAY DE PAUSA (si el juego está pausado)
            if (isPaused && !isGameOver) _buildPauseOverlay(),
            
            // GAME OVER CONDICIONAL
            if (isGameOver) _buildGameOverOverlay(),
          ],
        ),
      ),
    );
  }
}

// Widget personalizado para el botón de pausa
class _PauseButton extends StatefulWidget {
  final VoidCallback onTap;
  
  const _PauseButton({required this.onTap});

  @override
  State<_PauseButton> createState() => __PauseButtonState();
}

class __PauseButtonState extends State<_PauseButton> {
  bool _isHovering = false;

  String get _assetPath =>
      'assets/ui/buttons/pause_${_isHovering ? 'hover' : 'normal'}.png';

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.translucent,
        child: Image.asset(
          _assetPath,
          width: 70,
          height: 70,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}