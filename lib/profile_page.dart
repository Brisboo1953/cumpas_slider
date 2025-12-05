import 'package:flutter/material.dart';
import 'services/settings_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  String? _playerName;
  int _selectedProfilePicture = 0; // Índice de la foto de perfil seleccionada
  late AnimationController _fadeController;
  
  // Lista de imágenes de perfil disponibles (debes crear estas imágenes en assets/profile_pictures/)
  static const List<String> profilePictures = [
    'assets/profile/pic1.png',
    'assets/profile/pic2.png',
    'assets/profile/pic3.png',
    'assets/profile/pic4.png',
    'assets/profile/pic5.png',
  ];

  @override
  void initState() {
    super.initState();
    _playerName = SettingsService.playerName;
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _playerName ?? '');
    final result = await showDialog<String?>(
      context: context,
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
                    'Editar nombre',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Ingresa tu nombre',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
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
                          'Cancelar',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 15, 172, 75),
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
                          'Guardar',
                          style: TextStyle(fontSize: 20),
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
    );

    if (result != null) {
      await SettingsService.setPlayerName(result);
      setState(() => _playerName = SettingsService.playerName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre actualizado'),
          backgroundColor: Color.fromARGB(255, 15, 172, 75),
        )
      );
    }
  }

  void _selectProfilePicture(int index) {
    setState(() {
      _selectedProfilePicture = index;
      // Aquí podrías guardar la selección en SettingsService si quieres persistencia
      // SettingsService.setSelectedProfilePicture(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'PERFIL',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, letterSpacing: 3, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(23, 181, 78, 241),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 73, 182, 255),
              Color.fromARGB(255, 0, 153, 255),
              Color.fromARGB(202, 41, 0, 58),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeController,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tu Perfil",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Personaliza tu información y foto de perfil.",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 18),

                  // Información del perfil - CENTRADO
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: Card(
                        color: Colors.white10,
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.transparent,
                                child: ClipOval(
                                  child: Image.asset(
                                    profilePictures[_selectedProfilePicture],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: Colors.white24,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          size: 70,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _playerName ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Este nombre aparecerá en el marcador',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 15, 172, 75),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                                ),
                                onPressed: _editName,
                                icon: const Icon(Icons.edit),
                                label: const Text('Editar nombre', style: TextStyle(fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Selección de foto de perfil - MÁS PEQUEÑAS
                  Card(
                    color: Colors.white10,
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Foto de perfil',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Selecciona una imagen para tu perfil',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.9,
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 6,
                                  mainAxisSpacing: 6,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: profilePictures.length,
                                itemBuilder: (context, index) {
                                  final isSelected = index == _selectedProfilePicture;
                                  return GestureDetector(
                                    onTap: () => _selectProfilePicture(index),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 50, // Tamaño reducido
                                      height: 50, // Tamaño reducido
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? Colors.amber : Colors.transparent,
                                          width: isSelected ? 2 : 0,
                                        ),
                                        color: Colors.white10,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          profilePictures[index],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.white24,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                  size: 20, // Ícono más pequeño
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              'Selecciona una imagen haciendo clic en ella',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón para volver
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: Card(
                        color: Colors.white10,
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'Guardar cambios',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 15, 172, 75),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Volver a opciones',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}