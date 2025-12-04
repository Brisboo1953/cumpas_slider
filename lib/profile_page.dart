import 'package:flutter/material.dart';
import 'services/settings_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _playerName;

  @override
  void initState() {
    super.initState();
    _playerName = SettingsService.playerName;
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _playerName ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editar nombre de jugador'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Nombre'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Guardar')),
          ],
        );
      },
    );

    if (result != null) {
      await SettingsService.setPlayerName(result);
      setState(() => _playerName = SettingsService.playerName);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre actualizado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF283048), Color(0xFF859398)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(radius: 48, backgroundColor: Colors.white24, child: const Icon(Icons.person, size: 48, color: Colors.white)),
                      const SizedBox(height: 12),
                      const Text('Jugador', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Edita tu perfil y personaliza tu experiencia.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Cuenta', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Card(
                  color: Colors.white10,
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.white),
                    title: Text(_playerName ?? 'Sin nombre', style: const TextStyle(color: Colors.white)),
                    trailing: TextButton(onPressed: _editName, child: const Text('Editar')),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Preferencias', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Card(
                  color: Colors.white10,
                  child: ListTile(
                    leading: const Icon(Icons.palette, color: Colors.white),
                    title: const Text('Tema del juego', style: TextStyle(color: Colors.white)),
                    trailing: DropdownButton<String>(
                      value: 'Oscuro',
                      items: const [DropdownMenuItem(value: 'Oscuro', child: Text('Oscuro')), DropdownMenuItem(value: 'Claro', child: Text('Claro'))],
                      onChanged: (_) {},
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Text('Guardar y volver'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
