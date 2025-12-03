import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
                    leading: const Icon(Icons.email, color: Colors.white),
                    title: const Text('correo@ejemplo.com', style: TextStyle(color: Colors.white)),
                    trailing: TextButton(onPressed: () {}, child: const Text('Editar')),
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
