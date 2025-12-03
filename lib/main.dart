import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importado para SystemNavigator.pop()
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'game_page.dart';
import 'options_page_ui.dart'; // Assuming this is where NewOptionsPage is defined
import 'services/music_service.dart';
import 'services/settings_service.dart';
import 'scoreboard_page.dart';
import 'widgets/custom_menu_button.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Si no existe .env, continúa.
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      debugPrint('✅ Supabase initialized');
    } catch (e) {
      debugPrint('❌ Error inicializando Supabase: $e');
    }
  } else {
    debugPrint(
      '⚠️ SUPABASE_URL or SUPABASE_ANON_KEY not found in .env — Supabase not initialized.',
    );
  }

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
// MENÚ PRINCIPAL
// ----------------------------------------------------------
class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  bool _isMusicPlaying = false;

  // Método para manejar el toggle de la música
  void _toggleMusic() async {
    if (_isMusicPlaying) {
      await MusicService.stop();
    } else {
      await MusicService.playMenu();
    }
    setState(() {
      _isMusicPlaying = !_isMusicPlaying;
    });
  }

  @override
  void initState() {
    super.initState();
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
          // Fondo de pantalla
          Positioned.fill(
            child: Image.asset(
              'assets/images/menu_start.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Capa de color semi-transparente (si es necesaria)
          Positioned.fill(
            child: Container(color: const Color.fromRGBO(255, 255, 255, 0.01)),
          ),

          // TÍTULO
          const Align(
            alignment: Alignment(0, -0.80),
            child: Text(
              "CUMPAS SLIDE GAME",
              style: TextStyle(
                fontSize: 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ==========================================================
          // 1. BOTÓN DE OPCIONES - SUPERIOR IZQUIERDA (Usando IconButton)
          // ==========================================================
          Positioned(
            left: 12,
            top: 40, // Ajustado para dejar espacio con la barra de estado
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewOptionsPage()),
                );
              },
            ),
          ),

          // ==========================================================
          // 2. BOTÓN DE CONFIGURACIÓN (MÚSICA/SONIDO) - SUPERIOR DERECHA (Usando IconButton)
          // ==========================================================
          Positioned(
            right: 12,
            top: 40, // Ajustado para dejar espacio con la barra de estado
            child: IconButton(
              icon: Icon(
                _isMusicPlaying ? Icons.volume_up : Icons.volume_off,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _toggleMusic,
            ),
          ),
          
          // ==========================================================
          // 3. BOTÓN JUGAR - EN MEDIO
          // ==========================================================
          Align(
            alignment: Alignment.center,
            child: CustomMenuButton(
              buttonName: "play",
              onTap: () async {
                final name = await showDialog<String?>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) {
                    String input = '';
                    return AlertDialog(
                      title: const Text('Ingresa tu nombre'),
                      content: TextField(
                        autofocus: true,
                        decoration: const InputDecoration(hintText: 'Nombre'),
                        onChanged: (v) => input = v,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(input),
                          child: const Text('Aceptar'),
                        ),
                      ],
                    );
                  },
                );

                if (name == null || name.trim().isEmpty) return;
                if (!mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GamePage(playerName: name.trim()),
                  ),
                );
              },
            ),
          ),
          
          // ==========================================================
          // 4. BOTÓN PUNTUACIONES - DERECHA EN MEDIO (Corregido)
          // ==========================================================
          Align(
            alignment: const Alignment(0.95, 0),
            child: CustomMenuButton(
              buttonName: "Scoreboard",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScoreboardPage()),
                );
              },
            ),
          ),

          // ==========================================================
          // 5. BOTÓN SALIR - ABAJO EN MEDIO
          // ==========================================================
          Align(
            alignment: const Alignment(0, 0.85),
            child: CustomMenuButton(
              buttonName: "exit",
              onTap: () => _confirmExit(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirmación para salir
  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("¿Salir del juego?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                // Cierra el diálogo antes de intentar salir de la aplicación
                Navigator.pop(ctx); 
                // Cierra la aplicación de manera programática
                // SystemNavigator.pop() intenta cerrar la aplicación.
                SystemNavigator.pop(); 
              },
              child: const Text("Salir"),
            ),
          ],
        );
      },
    );
  }
}

// ----------------------------------------------------------
// PANTALLA DE OPCIONES (placeholder)
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