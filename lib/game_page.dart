import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'services/music_service.dart';

// Constantes de juego
const double _coinSize = 40.0;
const double _pacaSize = 60.0;
// NOTE: object speed is now a stateful variable inside _GamePageState so it can increase

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final GlobalKey _carKey = GlobalKey();

  // --- VARIABLES DEL CARRO Y LÍMITES ---
  double carX = 0; // Posición horizontal del carro (relativa al centro)
  double carY = 0; // Posición vertical del carro (relativa al centro) — usado en orientación horizontal
  double carWidth = 100;
  double carHeight = 60;
  // Máximos desplazamientos calculados para ambos ejes
  double maxCarOffsetX = 0;
  double maxCarOffsetY = 0;
  // Variable auxiliar (mantener por compatibilidad con código previo)
  double maxCarOffset = 0;

  // Orientación actual del juego (se lee desde SettingsService)
  GameOrientation orientation = GameOrientation.vertical;

  // Estado de pausa
  bool isPaused = false;

  // --- VARIABLES DE OBJETOS Y PUNTUACIÓN ---
  List<Offset> coins = [];
  List<Offset> pacas = [];
  int score = 0;
  Timer? objectMovementTimer;
  Timer? objectGeneratorTimer;

  // --- LÓGICA DE GASOLINA ---
  double gasoline = 100.0;
  final double consumeRate = 0.5; // Consumo por tick
  Timer? gasolineTimer;

  // --- VELOCIDAD DEL COCHE (aumenta con el tiempo) ---
  double carSpeedMultiplier = 1.0;
  final double carSpeedIncrement = 0.05; // incremento por tick
  final double carSpeedMax = 3.0; // multiplicador máximo
  Timer? carSpeedTimer;

  // --- DIFICULTAD / VELOCIDADES (background y objetos) ---
  double objectSpeed = 4.0; // velocidad con la que caen/desplazan objetos
  // backgroundSpeed ya existe: double backgroundSpeed = 4;
  Timer? difficultyTimer;
  final double speedIncrement = 0.5; // incremento por tick para background y objetos
  final double speedMax = 12.0; // tope razonable

  // -------- BACKGROUND ANIMADO --------
  double backgroundOffset = 0;
  final double imageHeight = 600;
  double backgroundSpeed = 4; // Velocidad de movimiento del fondo

  Timer? backgroundTimer;

  @override
  void initState() {
    super.initState();
    // Stop menu music when entering the game
    MusicService.stop();
    _startGasolineTimer();
    _startBackgroundAnimation();
    _startObjectGenerator();
    _startObjectMovement(); // Inicia el movimiento de objetos
    _startCarSpeedTimer(); // Inicia incremento de velocidad del coche
    _startDifficultyTimer(); // Inicia incremento de background y objetos
  }

  void _startCarSpeedTimer() {
    // Aumenta gradualmente el multiplicador de velocidad hasta el máximo
    carSpeedTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (gasoline <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        carSpeedMultiplier = (carSpeedMultiplier + carSpeedIncrement).clamp(1.0, carSpeedMax);
      });
      if (carSpeedMultiplier >= carSpeedMax) {
        timer.cancel();
      }
    });
  }

  void _startDifficultyTimer() {
    // Aumenta gradualmente la velocidad del fondo y de los objetos
    difficultyTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (gasoline <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        backgroundSpeed = (backgroundSpeed + speedIncrement).clamp(0, speedMax);
        objectSpeed = (objectSpeed + speedIncrement).clamp(0, speedMax);
      });
      if (backgroundSpeed >= speedMax && objectSpeed >= speedMax) {
        timer.cancel();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lee la orientación seleccionada en las opciones
    orientation = SettingsService.orientation;

    // Calcula los desplazamientos máximos para X e Y según tamaño de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double margin = 16.0;
    final computedX = (screenWidth / 2) - (carWidth / 2) - margin;
    final computedY = (screenHeight / 2) - (carHeight / 2) - margin;
    maxCarOffsetX = computedX > 0 ? computedX : 0;
    maxCarOffsetY = computedY > 0 ? computedY : 0;
    maxCarOffset = orientation == GameOrientation.vertical ? maxCarOffsetX : maxCarOffsetY;
  }

  // ---------- ANIMACIÓN DEL FONDO ----------
  void _startBackgroundAnimation() {
    backgroundTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (gasoline <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        backgroundOffset += backgroundSpeed;

        // Determina la 'longitud' principal del fondo según la orientación:
        // - vertical: altura de la imagen usada para el bucle
        // - horizontal: ancho de la pantalla (desplazamiento horizontal)
        final primarySize = orientation == GameOrientation.vertical
            ? imageHeight
            : MediaQuery.of(context).size.width;

        // Bucle para que el fondo se repita infinitamente
        if (backgroundOffset >= primarySize) {
          backgroundOffset = 0;
        }
      });
    });
  }

  // ---------- LÓGICA DE GASOLINA ----------
  void _startGasolineTimer() {
    gasolineTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (gasoline <= 0) {
        gasoline = 0;
        _gameOver();
        timer.cancel();
        return;
      }
      setState(() {
        gasoline -= consumeRate;
      });
    });
  }

  // ---------- GENERADOR DE OBJETOS ----------
  void _startObjectGenerator() {
    // Genera una moneda cada 1 segundo y una paca cada 3 segundos
    objectGeneratorTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (gasoline <= 0) {
        timer.cancel();
        return;
      }
      _spawnCoins(1); // Genera 1 moneda
      if (timer.tick % 3 == 0) {
        _spawnPaca(1); // Genera 1 paca cada 3 segundos
      }
      setState(() {});
    });
  }


  // ---------- MOVIMIENTO DE OBJETOS Y COLISIÓN ----------
  void _startObjectMovement() {
    // Mueve los objetos hacia abajo y comprueba colisiones
    objectMovementTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (gasoline <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        // Mueve coins y pacas según la orientación seleccionada
        if (orientation == GameOrientation.vertical) {
          // Objetos caen verticalmente
          coins = coins.map((c) => Offset(c.dx, c.dy + objectSpeed)).toList();
          pacas = pacas.map((p) => Offset(p.dx, p.dy + objectSpeed)).toList();

          // Elimina objetos que salieron de la pantalla (altura > alto de pantalla + margen)
          final screenHeight = MediaQuery.of(context).size.height;
          coins.removeWhere((c) => c.dy > screenHeight + 50);
          pacas.removeWhere((p) => p.dy > screenHeight + 50);
        } else {
          // Orientación horizontal: objetos se desplazan a lo largo del eje X
          coins = coins.map((c) => Offset(c.dx + objectSpeed, c.dy)).toList();
          pacas = pacas.map((p) => Offset(p.dx + objectSpeed, p.dy)).toList();

          // Elimina objetos que salieron de la pantalla (ancho > ancho de pantalla + margen)
          final screenWidth = MediaQuery.of(context).size.width;
          coins.removeWhere((c) => c.dx > screenWidth + 50);
          pacas.removeWhere((p) => p.dx > screenWidth + 50);
        }

        _checkCollisions();
      });
    });
  }



  // CREA COINS con posición X aleatoria en el ancho total
  void _spawnCoins(int count) {
    final random = Random();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    for (int i = 0; i < count; i++) {
      if (orientation == GameOrientation.vertical) {
        // Genera una posición X aleatoria. Se resta el tamaño para que no se salga
        double randomX = random.nextDouble() * (screenWidth - _coinSize);
        // Inicia arriba de la pantalla (posición Y negativa)
        coins.add(Offset(randomX, -_coinSize));
      } else {
        // En modo horizontal generamos en Y aleatorio y empiezan desde la izquierda
        double randomY = random.nextDouble() * (screenHeight - _coinSize);
        coins.add(Offset(-_coinSize, randomY));
      }
    }
  }

  // CREA PACA con posición X aleatoria en el ancho total
  void _spawnPaca(int count) {
    final random = Random();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    for (int i = 0; i < count; i++) {
      if (orientation == GameOrientation.vertical) {
        double randomX = random.nextDouble() * (screenWidth - _pacaSize);
        pacas.add(Offset(randomX, -_pacaSize));
      } else {
        double randomY = random.nextDouble() * (screenHeight - _pacaSize);
        pacas.add(Offset(-_pacaSize, randomY));
      }
    }
  }

  // Rect global del auto. Obtenemos su posición real en la pantalla.
  Rect _getCarRect() {
    final renderBox = _carKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Rect.zero;

    // Obtiene la posición global del rincón superior izquierdo del coche
    final pos = renderBox.localToGlobal(Offset.zero);

    return Rect.fromLTWH(pos.dx, pos.dy, carWidth, carHeight);
  }

  bool _collision(Rect a, Rect b) => a.overlaps(b);

  void _checkCollisions() {
    final carRect = _getCarRect();

    // MONEDAS
    coins.removeWhere((coin) {
      final coinRect = Rect.fromLTWH(coin.dx, coin.dy, _coinSize, _coinSize);
      if (_collision(carRect, coinRect)) {
        score += 10;
        gasoline += 5; // Aumenta un poco la gasolina al recoger moneda
        if (gasoline > 100) gasoline = 100;
        return true;
      }
      return false;
    });

    // PACA
    pacas.removeWhere((paca) {
      final pacaRect = Rect.fromLTWH(paca.dx, paca.dy, _pacaSize, _pacaSize);
      if (_collision(carRect, pacaRect)) {
        score += 50;
        gasoline += 25; // Aumenta más la gasolina al recoger paca
        if (gasoline > 100) gasoline = 100;
        return true;
      }
      return false;
    });

    // No es necesario llamar setState() aquí si ya se llama en el timer
    // setState(() {});
  }
  
  void _gameOver() {
    // Cancelar todos los timers
    backgroundTimer?.cancel();
    objectMovementTimer?.cancel();
    objectGeneratorTimer?.cancel();
    gasolineTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (ctx) => AlertDialog(
        title: const Text("¡Juego Terminado!"),
        content: Text("Te has quedado sin gasolina. Conseguiste $score puntos."),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(ctx); 
                // Aquí podrías añadir Navigator.pop(context) si esto fuera la página del juego
                // y quisieras volver a un menú anterior.
              },
              child: const Text("Volver a Jugar / OK")),
        ],
      ),
    );
  }

  // -------- PAUSA / REANUDAR --------
  void _stopAllTimers() {
    backgroundTimer?.cancel();
    objectMovementTimer?.cancel();
    objectGeneratorTimer?.cancel();
    gasolineTimer?.cancel();
    carSpeedTimer?.cancel();
  }

  void _startAllTimers() {
    if (gasoline <= 0) return;
    _startGasolineTimer();
    _startBackgroundAnimation();
    _startObjectGenerator();
    _startObjectMovement();
    _startCarSpeedTimer();
  }

  Future<void> _showPauseMenu() async {
    // Pausa inmediatamente
    _stopAllTimers();
    setState(() {
      isPaused = true;
    });

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Juego en Pausa'),
        content: const Text('¿Deseas continuar o salir al menú principal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('resume'),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('exit'),
            child: const Text('Salir al Menú'),
          ),
        ],
      ),
    );

    if (result == 'resume') {
      setState(() {
        isPaused = false;
      });
      _startAllTimers();
      return;
    }

    if (result == 'exit') {
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar salida'),
          content: const Text('Se perderá el progreso actual. ¿Seguro que deseas salir?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Salir')),
          ],
        ),
      );

      if (confirm == true) {
        // Asegura que todo esté parado y vuelve al menú
        _stopAllTimers();
        Navigator.pop(context); // Sale de GamePage al menú anterior
      } else {
        // Si cancela la salida, reanuda el juego
        setState(() {
          isPaused = false;
        });
        _startAllTimers();
      }
    }
  }

  @override
  void dispose() {
    backgroundTimer?.cancel();
    objectMovementTimer?.cancel();
    objectGeneratorTimer?.cancel();
    gasolineTimer?.cancel();
    carSpeedTimer?.cancel();
    difficultyTimer?.cancel();
    super.dispose();
  }

  // ********* WIDGET: FONDO INFINITO *********
  Widget _buildAnimatedBackground() {
    // Si la orientación es vertical, usamos el desplazamiento vertical original.
    if (orientation == GameOrientation.vertical) {
      return Stack(
        children: [
          // Primera imagen (posición de bucle)
          Positioned(
            top: backgroundOffset - imageHeight,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/camino.png",
              height: imageHeight,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Segunda imagen (posición actual)
          Positioned(
            top: backgroundOffset,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/camino.png",
              height: imageHeight,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      );
    }

    // En orientación horizontal, desplazamos el fondo a lo largo del eje X.
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        Positioned(
          left: backgroundOffset - screenWidth,
          top: 0,
          bottom: 0,
          child: Image.asset(
            "assets/camino.png",
            width: screenWidth,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          left: backgroundOffset,
          top: 0,
          bottom: 0,
          child: Image.asset(
            "assets/camino.png",
            width: screenWidth,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  // ********* WIDGET: BARRA DE GASOLINA *********
  Widget _buildGasolineBar() {
    return Container(
      width: 200,
      height: 25,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Stack(
        children: [
          // Barra de progreso (Gasolina)
          FractionallySizedBox(
            widthFactor: gasoline / 100.0,
            child: Container(
              decoration: BoxDecoration(
                color: gasoline > 20 ? Colors.green : Colors.red, // Rojo si es bajo
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          // Texto
          Center(
            child: Text(
              "Gasolina: ${gasoline.toStringAsFixed(0)}%",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ********* WIDGET: COCHE CON GESTURE DETECTOR *********
  Widget _buildCar() {
    // Cambia la alineación y el control según la orientación seleccionada
    if (orientation == GameOrientation.vertical) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              // Aplicamos multiplicador de velocidad al desplazamiento del gesto
              carX += details.delta.dx * carSpeedMultiplier;
              // Limita el movimiento del coche dentro de un rango
              carX = carX.clamp(-maxCarOffsetX, maxCarOffsetX);
            });
          },
          child: Transform.translate(
            // Mueve el carro horizontalmente según carX
            offset: Offset(carX, -20),
            child: Container(
              key: _carKey,
              width: carWidth,
              height: carHeight,
              child: Image.asset(
                "assets/cars/orange_car.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );
    } else {
      return Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              // Aplicamos multiplicador de velocidad al desplazamiento vertical
              carY += details.delta.dy * carSpeedMultiplier;
              // Limita el movimiento vertical del coche dentro de un rango
              carY = carY.clamp(-maxCarOffsetY, maxCarOffsetY);
            });
          },
          child: Transform.translate(
            // Mueve el carro verticalmente según carY, acercado -20 px al borde derecho
            offset: Offset(-20, carY),
            child: Container(
              key: _carKey,
              width: carHeight, // rota virtualmente: usamos dimensiones intercambiadas
              height: carWidth,
              child: Image.asset(
                "assets/cars/orange_car_h.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1. FONDO ANIMADO
            _buildAnimatedBackground(),

            // 2. MONEDAS (Posición absoluta basada en coordenadas de la lista)
            ...coins.map((c) {
              return Positioned(
                left: c.dx,
                top: c.dy,
                child: Image.asset(
                  "assets/coin.png",
                  width: _coinSize,
                  height: _coinSize,
                ),
              );
            }),

            // 3. PACA (Posición absoluta basada en coordenadas de la lista)
            ...pacas.map((p) {
              return Positioned(
                left: p.dx,
                top: p.dy,
                child: Image.asset(
                  "assets/paca.png",
                  width: _pacaSize,
                  height: _pacaSize,
                ),
              );
            }),

            // 4. CARRO
            _buildCar(),

            // 5. INTERFAZ DE USUARIO (Score y Gasolina)
            Positioned(
              left: 20,
              top: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gasolina
                  _buildGasolineBar(),
                  const SizedBox(height: 10),
                  // Score
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Score: $score",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Indicador de velocidad del coche
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Velocidad: x${carSpeedMultiplier.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
            ,
            // Botón de pausa en esquina superior derecha, pintado al final (sobre todo)
            Positioned(
              right: 10,
              top: 10,
              child: IconButton(
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                onPressed: _showPauseMenu,
              ),
            )
          ],
        ),
      ),
    );
  }
}