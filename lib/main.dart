import 'package:flutter/material.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';
//import 'dart:async';

// Importa la GamePage correcta desde su propio archivo
import 'game_page.dart'; 
import 'options_page_ui.dart';
import 'services/music_service.dart';
import 'services/settings_service.dart';

// Ya no necesitamos importar DraggableCar aquí, ya que GamePage la importa.
// import 'widgets/draggable_car.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Asegúrate de que dotenv.load se ejecuta antes de runApp si necesitas variables de entorno
  // await dotenv.load(fileName: ".env"); 

  // Asegura que SettingsService esté inicializado antes de arrancar la app
  await SettingsService.init();
  runApp(const MyGameApp());
}

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
class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  bool _isMusicPlaying = false;

  @override
  void initState() {
    super.initState();
    // Do not autoplay music — many browsers block autoplay. User can enable via button.
  }

  @override
  void dispose() {
    MusicService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: Stack(
        children: [
          // Fondo de pantalla del menú principal
          Positioned.fill(
            child: Image.asset(
              'assets/images/menu_start.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Capa semitransparente para mejorar contraste de botones
          Positioned.fill(
            child: Container(color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.01)),
          ),
          // Título separado y colocado más arriba que los botones
          Align(
            alignment: const Alignment(0, -0.80),
            child: Text("CUMPAS SLIDE GAME",
                style: TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),

          // Zona de botones (se queda en la posición original)
          Align(
            alignment: const Alignment(0, 0.40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
            // --- BOTÓN JUGAR (Ahora usa la GamePage IMPORTADA) ---
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
                    MaterialPageRoute(builder: (_) => const NewOptionsPage()));
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
          // Botón para activar/desactivar música (top-right)
          Positioned(
            right: 12,
            top: 12,
            child: IconButton(
              icon: Icon(_isMusicPlaying ? Icons.volume_up : Icons.volume_off, color: Colors.white),
              onPressed: () async {
                if (_isMusicPlaying) {
                  await MusicService.stop();
                  setState(() {
                    _isMusicPlaying = false;
                  });
                } else {
                  await MusicService.playMenu();
                  setState(() {
                    _isMusicPlaying = true;
                  });
                }
              },
            ),
          ),
        ],
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
                // Esto solo cierra el diálogo en un entorno normal
                onPressed: () => Navigator.pop(context), 
                child: const Text("Salir")),
          ],
        );
      },
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
// NOTA: La clase GamePage ha sido eliminada de aquí y movida a game_page.dart