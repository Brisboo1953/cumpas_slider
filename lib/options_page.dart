import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'profile_page.dart';

class OptionsPage extends StatefulWidget {
  const OptionsPage({super.key});

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  // Asegúrate de que GameOrientation está definido en services/settings_service.dart
  GameOrientation _orientation = SettingsService.orientation;
  int _selectedCar = SettingsService.selectedCarIndex;
  int _selectedScene = SettingsService.selectedSceneIndex;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Opciones"),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
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

                // ORIENTACIÓN
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
                                style: ElevatedButton.styleFrom(
                                  // Eliminado: transitionDuration para evitar el error de compilación.
                                  backgroundColor: _orientation == GameOrientation.vertical ? Colors.teal : Colors.white12,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _onOrientationChanged(GameOrientation.vertical),
                                child: const Text('Vertical'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  // Eliminado: transitionDuration para evitar el error de compilación.
                                  backgroundColor: _orientation == GameOrientation.horizontal ? Colors.teal : Colors.white12,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

                // SELECCIÓN DE CARRO
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
                          height: 150,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: SettingsService.availableCars.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, idx) {
                              final asset = SettingsService.getCarAsset(idx, _orientation);
                              final selected = idx == _selectedCar;
                              final carName = SettingsService.availableCars[idx]['name'] as String?;

                              // Utilizamos un factor de escala si es necesario, pero manteniendo tu lógica original
                              final double scaleFactor = idx == 1 ? 2.5 : 1.0;

                              return GestureDetector(
                                onTap: () => _onSelectCar(idx),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250), // Duración rápida para fluidez
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
                                      Expanded(
                                        child: Center(
                                          child: Transform.scale(
                                            scale: scaleFactor,
                                            child: Image.network(
                                              asset,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(carName ?? 'Vehículo', style: const TextStyle(color: Colors.white)),
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

                // ESCENARIOS
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
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: SettingsService.availableScenes.length,
                          itemBuilder: (ctx, i) {
                            final asset = SettingsService.availableScenes[i];
                            final selected = i == _selectedScene;

                            return GestureDetector(
                              onTap: () => _onSelectScene(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220), // Duración rápida para fluidez
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: selected ? Colors.lightGreenAccent : Colors.transparent, width: selected ? 3 : 1),
                                  boxShadow: selected
                                      ? [BoxShadow(color: const Color.fromRGBO(204,255,144,0.15), blurRadius: 12, spreadRadius: 2)]
                                      : [],
                                  image: DecorationImage(
                                    image: NetworkImage(asset),
                                    fit: BoxFit.cover,
                                  ),
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

                // PERFIL
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.indigoAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

                // GUARDAR / RESET
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          await SettingsService.save();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opciones guardadas')));
                        },
                        child: const Text('Guardar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opciones restablecidas')));
                        },
                        child: const Text('Restablecer'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}