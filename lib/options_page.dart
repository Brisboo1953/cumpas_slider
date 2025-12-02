import 'package:flutter/material.dart';

class OptionsPage extends StatelessWidget {
  const OptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Opciones")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "Aquí irán las opciones de juego:",
              style: TextStyle(fontSize: 22),
            ),
            SizedBox(height: 20),
            Text("• Elegir escenario"),
            Text("• Elegir carrito"),
            Text("• Configuración de perfil"),
          ],
        ),
      ),
    );
  }
}
