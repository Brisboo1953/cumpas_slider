import 'package:flutter/material.dart';
import 'dart:math';

class DraggableCar extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;

  final ValueChanged<int>? onScoreChanged;
  // CAMBIO CLAVE: Ahora solo reportamos el desplazamiento horizontal (_x)
  final ValueChanged<double>? onXPositionChanged; 

  const DraggableCar({
    super.key,
    required this.imagePath,
    this.width = 100,
    this.height = 60,
    this.onScoreChanged,
    this.onXPositionChanged, // Usamos la nueva propiedad
  });

  @override
  State<DraggableCar> createState() => _DraggableCarState();
}

class _DraggableCarState extends State<DraggableCar> {
  // Desplazamiento del carro desde el centro (0)
  double _x = 0;
  double maxWidth = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        maxWidth = c.maxWidth;
        double halfCarWidth = widget.width / 2;
        
        // El desplazamiento máximo es la mitad del contenedor menos la mitad del carro
        double minX = -maxWidth / 2 + halfCarWidth;
        double maxX = maxWidth / 2 - halfCarWidth;

        return GestureDetector(
          // Si el usuario presiona en un punto, el carro debe saltar a esa posición.
          onPanStart: (d) {
            setState(() {
              // Calcula la posición absoluta del toque con respecto al centro
              _x = d.localPosition.dx - (maxWidth / 2);
              _x = _x.clamp(minX, maxX); 
            });
            widget.onXPositionChanged?.call(_x); 
          },
          onPanUpdate: (d) {
            setState(() {
              // CAMBIO CLAVE DE INTERACCIÓN: Mover el carro a la posición absoluta del toque.
              _x = d.localPosition.dx - (maxWidth / 2);
              
              // Asegura que el carro no se salga de los límites del contenedor
              _x = _x.clamp(minX, maxX); 
              widget.onScoreChanged?.call(_calcScore());
            });
            // Reportamos el _x en cada actualización, que es una operación muy rápida
            widget.onXPositionChanged?.call(_x); 
          },
          child: SizedBox(
            width: maxWidth,
            height: widget.height + 20, // Altura ajustada
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(_x, 0),
                  child: Container(
                    width: widget.width,
                    height: widget.height,
                    child: Image.asset(widget.imagePath, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Función original para calcular un score (no modificada)
  int _calcScore() {
    double slider = maxWidth - widget.width;
    double percent = (_x + slider / 2) / slider;
    return (percent.clamp(0, 1) * 100).round();
  }

  // La función _reportCarPosition() se ha eliminado para mejorar el rendimiento.
}