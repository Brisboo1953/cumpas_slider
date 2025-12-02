import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';


import 'widgets/draggable_car.dart'; // tu clase DraggableCar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env"); // si lo usas para Supabase

  runApp(const MyGameApp());
}

// ----------------------------------------------------------
// APP PRINCIPAL
// ----------------------------------------------------------
class MyGameApp extends StatelessWidget {
  const MyGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Car Game",
      debugShowCheckedModeBanner: false,
      home: const MainMenuPage(),
    );
  }
}

// ----------------------------------------------------------
// 1) MENÚ PRINCIPAL
// ----------------------------------------------------------
class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("CAR GAME",
                style: TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 60),

            // --- BOTÓN JUGAR ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GamePage()));
              },
              child: const Text("JUGAR", style: TextStyle(fontSize: 22)),
            ),

            const SizedBox(height: 20),

            // --- BOTÓN OPCIONES ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OptionsPage()));
              },
              child: const Text("OPCIONES", style: TextStyle(fontSize: 22)),
            ),

            const SizedBox(height: 20),

            // --- BOTÓN SALIR ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              onPressed: () {
                _confirmExit(context);
              },
              child: const Text("SALIR", style: TextStyle(fontSize: 22)),
            ),
          ],
        ),
      ),
    );
  }

  /// VENTANA DE CONFIRMACIÓN PARA SALIR
  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("¿Salir del juego?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar")),
            TextButton(
                onPressed: () => Navigator.pop(context), // cierra menú → cierra app
                child: const Text("Salir")),
          ],
        );
      },
    );
  }
}

// ----------------------------------------------------------
// 2) PANTALLA DEL JUEGO
// ----------------------------------------------------------
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  double gasoline = 100;
  double consumeRate = 0.25;
  int money = 0;
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    startGasolineTimer();
  }

  void startGasolineTimer() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        gasoline -= consumeRate;
        if (gasoline <= 0) {
          gasoline = 0;
          timer.cancel();
          _gameOver();
        }
      });
    });
  }

  void _gameOver() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¡Se acabó la gasolina!"),
        content: const Text("El juego ha terminado."),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("Volver al menú")),
        ],
      ),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void collectMoney(int amount) {
    setState(() => money += amount);
  }

  void fillGas(int amount) {
    setState(() {
      gasoline += amount;
      if (gasoline > 100) gasoline = 100;
    });
  }

  void onScoreChanged(int score) {
    // score 0–100 viene de tu DraggableCar
    if (score > 80) {
      collectMoney(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Juego"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey.shade900,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Gasolina: ${gasoline.toStringAsFixed(0)}%",
              style: const TextStyle(color: Colors.white, fontSize: 22)),
          Text("Dinero: $money",
              style: const TextStyle(color: Colors.white, fontSize: 22)),

          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DraggableCar(
              imagePath: "assets/cars/orange_car.png",
              width: 120,
              height: 80,
              onScoreChanged: onScoreChanged,
            ),
          ),

          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: () => fillGas(30),
            child: const Text("Recoger Bidón (+30)"),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------
// 3) PANTALLA DE OPCIONES
// ----------------------------------------------------------
class OptionsPage extends StatelessWidget {
  const OptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Opciones")),
      body: const Center(
        child: Text(
          "Aquí irán las opciones del perfil, cambiar carro y escenarios.",
          style: TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
