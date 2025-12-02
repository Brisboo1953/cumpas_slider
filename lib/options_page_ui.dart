import 'package:flutter/material.dart';
import 'services/settings_service.dart';

class NewOptionsPage extends StatefulWidget {
  const NewOptionsPage({super.key});

  @override
  State<NewOptionsPage> createState() => _NewOptionsPageState();
}

class _NewOptionsPageState extends State<NewOptionsPage> {
  GameOrientation _orientation = SettingsService.orientation;

  void _onOrientationChanged(GameOrientation? value) {
    if (value == null) return;
    setState(() {
      _orientation = value;
      SettingsService.setOrientation(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Opciones")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Configuración de Orientación",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            RadioListTile<GameOrientation>(
              title: const Text('Vertical (Portrait)'),
              value: GameOrientation.vertical,
              groupValue: _orientation,
              onChanged: _onOrientationChanged,
            ),
            RadioListTile<GameOrientation>(
              title: const Text('Horizontal (Landscape)'),
              value: GameOrientation.horizontal,
              groupValue: _orientation,
              onChanged: _onOrientationChanged,
            ),
            const SizedBox(height: 24),
            const Text('Otras opciones (próximamente...)'),
          ],
        ),
      ),
    );
  }
}
