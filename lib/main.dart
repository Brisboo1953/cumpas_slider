import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'game_page.dart'; 
import 'options_page_ui.dart';
import 'services/music_service.dart';
import 'services/settings_service.dart';
import 'scoreboard_page.dart';
import 'widgets/custom_menu_button.dart';
import 'package:flutter/foundation.dart';


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
  bool _isMusicHovering = false;
  bool _isTitleHovering = false;

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
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Image.asset(
                'assets/images/menu_start.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned.fill(
            child: Container(color: const Color.fromRGBO(255, 255, 255, 0.01)),
          ),

          Align(
            alignment: const Alignment(0, -0.70),
            child: MouseRegion(
              onEnter: (_) => setState(() => _isTitleHovering = true),
              onExit: (_) => setState(() => _isTitleHovering = false),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: _isTitleHovering ? 0.66 : 0.6),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: AnimatedOpacity(
                      opacity: _isTitleHovering ? 0.98 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      child: child,
                    ),
                  );
                },
                child: Image.asset(
                  'assets/images/menu_title.png',
                  width: MediaQuery.of(context).size.width * 0.4,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Custom layout: play centered (bigger), exit under play (smaller),
          // options top-left, scoreboard bottom-right.
          Positioned.fill(
            child: Stack(
              children: [
                // Center play + exit below
                Align(
                  alignment: Alignment(0, 0.30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Play button, slightly larger
                      CustomMenuButton(
                        buttonName: 'play',
                        width: 120,
                        height: 120,
                        scale: 1.0,
                        onTap: () async {
                          // If we already have a stored player name, use it.
                          String? stored = SettingsService.playerName;
                          String? name = stored;

                          if (stored == null || stored.trim().isEmpty) {
                            // Ask for name and persist it for the session (and across launches)
                            final entered = await showDialog<String?>(
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

                            if (entered == null || entered.trim().isEmpty) return;
                            name = entered.trim();
                            await SettingsService.setPlayerName(name);
                          }

                          if (!mounted || name == null || name.trim().isEmpty) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GamePage(playerName: name!.trim()),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Exit button, smaller, under play
                      CustomMenuButton(
                        buttonName: 'exit',
                        width: 90,
                        height: 90,
                        scale: 1.0,
                        onTap: () => _confirmExit(context),
                      ),
                    ],
                  ),
                ),

                // Options top-left
                Positioned(
                  left: 16,
                  top: 16,
                  child: CustomMenuButton(
                    buttonName: 'options',
                    width: 90,
                    height: 90,
                    scale: 1.0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NewOptionsPage()),
                      );
                    },
                  ),
                ),

                // Scoreboard bottom-right
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: CustomMenuButton(
                    buttonName: 'scoreboard',
                    width: 90,
                    height: 90,
                    scale: 1.0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScoreboardPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Music toggle button (uses image assets). Positioned top-right, same size as other corner buttons.
          Positioned(
            right: 16,
            top: 16,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isMusicHovering = true),
              onExit: (_) => setState(() => _isMusicHovering = false),
              child: GestureDetector(
                onTap: () async {
                  if (_isMusicPlaying) {
                    await MusicService.stop();
                    setState(() => _isMusicPlaying = false);
                  } else {
                    await MusicService.playMenu();
                    setState(() => _isMusicPlaying = true);
                  }
                },
                child: Image.asset(
                  // choose asset based on hover and play state
                  _isMusicHovering
                      ? 'assets/ui/buttons/music_hover.png'
                      : (_isMusicPlaying
                          ? 'assets/ui/buttons/music_normal.png'
                          : 'assets/ui/buttons/music_off.png'),
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirmación para salir 
  void _confirmExit(BuildContext context) {
  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 15,
                  color: Colors.black87,
                  offset: Offset(0, 8),
                )
              ],
            ),
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "¿Salir del juego?",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  kIsWeb 
                    ? "Volverás al menú principal."
                    : "Se cerrará la aplicación.",
                  style: const TextStyle(fontSize: 20, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Cancelar",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        kIsWeb ? "Volver" : "Salir",
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  ).then((wantExit) {
    if (wantExit == true) {
      if (kIsWeb) {
        // En web: simplemente cerrar el diálogo y quedarse en el menú
        Navigator.of(context).pop();
      } else {
        // En móvil: cerrar la aplicación
        Navigator.of(context).pop(); // Cierra el diálogo
        // Para cerrar la app completamente
        SystemNavigator.pop();
      }
    }
  });
}}
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