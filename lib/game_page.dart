import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/draggable_car.dart';

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
