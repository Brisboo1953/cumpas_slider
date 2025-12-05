import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'profile_page.dart';

class NewOptionsPage extends StatefulWidget {
  const NewOptionsPage({super.key});

  @override
  State<NewOptionsPage> createState() => _NewOptionsPageState();
}

class _NewOptionsPageState extends State<NewOptionsPage> with TickerProviderStateMixin {
  GameOrientation _orientation = SettingsService.orientation;
  int _selectedCar = SettingsService.selectedCarIndex;
  int _selectedScene = SettingsService.selectedSceneIndex;
  late AnimationController _fadeController;

  void _onOrientationChanged(GameOrientation? value) {
    if (value == null) return;
    setState(() {
      _orientation = value;
      SettingsService.setOrientation(value);
    });
  }

  void _onSelectCar(int index) {
    setState(() {
      _selectedCar = index;
      SettingsService.setSelectedCar(index);
    });
  }

  void _onSelectScene(int index) {
    setState(() {
      _selectedScene = index;
      SettingsService.setSelectedScene(index);
    });
  }

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'OPCIONES',
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
                    "Ajustes",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Personaliza tu experiencia: orientacion, carrito y escenario.",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 18),

                  // Orientación //
                  Card(
                    color: Colors.white10,
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Orientación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(foregroundColor: Colors.white,
                                    backgroundColor: _orientation == GameOrientation.vertical ? const Color.fromARGB(255, 15, 172, 75) : const Color.fromARGB(149, 15, 172, 75)
                                  ),
                                  onPressed: () => _onOrientationChanged(GameOrientation.vertical),
                                  child: const Text('Vertical'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(foregroundColor: Colors.white,
                                    backgroundColor: _orientation == GameOrientation.horizontal ? const Color.fromARGB(255, 15, 172, 75) :  Color.fromARGB(255, 15, 172, 75)
                                  ),
                                  onPressed: () => _onOrientationChanged(GameOrientation.horizontal),
                                  child: const Text('Horizontal'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Selección del carrito //
                  Card(
                    color: Colors.white10,
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selecciona tu carro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: SettingsService.availableCars.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, idx) {
                                final asset = SettingsService.getCarAsset(idx, _orientation);
                                final selected = idx == _selectedCar;
                                return GestureDetector(
                                  onTap: () => _onSelectCar(idx),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    width: selected ? 140 : 110,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: selected ? Colors.amber : Colors.transparent, width: 3),
                                      gradient: selected ? const LinearGradient(colors: [Colors.orange, Colors.deepOrange]) : null,
                                      color: Colors.white10,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Expanded(child: Image.asset(asset, fit: BoxFit.contain)),
                                        const SizedBox(height: 6),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Selección de escenario //
                  Card(
                    color: Colors.white10,
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Escenario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4, 
                              childAspectRatio: 0.9, 
                              crossAxisSpacing: 6, 
                              mainAxisSpacing: 6, 
                            ),
                            itemCount: SettingsService.availableScenes.length,
                            itemBuilder: (ctx, i) {
                              final asset = SettingsService.availableScenes[i];
                              final selected = i == _selectedScene;
                              return GestureDetector(
                                onTap: () => _onSelectScene(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8), 
                                    border: Border.all(
                                      color: selected ? Colors.lightGreenAccent : Colors.transparent,
                                      width: selected ? 2 : 1,
                                    ),
                                    boxShadow: selected
                                        ? [BoxShadow(color: const Color.fromRGBO(204, 255, 144, 0.15), blurRadius: 8, spreadRadius: 1)] 
                                        : [],
                                    image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
                                  ),
                                  child: Stack(
                                    children: [

                                      if (selected)
                                        Positioned(
                                          top: 4, 
                                          right: 4, 
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), 
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(4), 
                                            ),
                                            child: const Text(
                                              'Seleccionado',
                                              style: TextStyle(color: Colors.white, fontSize: 8), 
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Perfil //
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14), 
                            backgroundColor: Colors.indigoAccent,foregroundColor: const Color.fromARGB(255, 255, 255, 255)
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                          },
                          icon: const Icon(Icons.person),
                          label: const Text('Configurar perfil'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Guardar //
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
                            'Guardar Configuración', 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 15, 172, 75),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    // Guarda en preferencias //
                                    await SettingsService.save();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Opciones guardadas'),
                                        backgroundColor: Color.fromARGB(255, 15, 172, 75),
                                      )
                                    );
                                  },
                                  child: const Text('Guardar'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:  Color.fromARGB(255, 15, 172, 75),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    setState(() {
                                      SettingsService.setOrientation(GameOrientation.vertical);
                                      SettingsService.setSelectedCar(0);
                                      SettingsService.setSelectedScene(0);
                                      _orientation = SettingsService.orientation;
                                      _selectedCar = SettingsService.selectedCarIndex;
                                      _selectedScene = SettingsService.selectedSceneIndex;
                                    });
                                    await SettingsService.save();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Configuración restablecida'),
                                        backgroundColor:  Color.fromARGB(255, 15, 172, 75),
                                      )
                                    );
                                  },
                                  child: const Text('Restablecer'),
                                ),
                              ),
                            ],
                          ),
                        ],
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