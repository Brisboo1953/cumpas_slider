import 'package:flutter/material.dart';

class DraggableCar extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;

  final ValueChanged<int>? onScoreChanged;
  // CAMBIO CLAVE: Ahora solo reportamos el desplazamiento horizontal (_x)
  final ValueChanged<double>? onXPositionChanged; 
  final ValueChanged<double>? onYPositionChanged;
  final bool verticalMovement;

  const DraggableCar({
    super.key,
    required this.imagePath,
    this.width = 100,
    this.height = 60,
    this.onScoreChanged,
    this.onXPositionChanged, // Usamos la nueva propiedad
    this.onYPositionChanged,
    this.verticalMovement = false,
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
        double maxHeight = c.maxHeight;
        if (!maxHeight.isFinite) maxHeight = MediaQuery.of(context).size.height;

        double halfCarWidth = widget.width / 2;
        double halfCarHeight = widget.height / 2;

        // Límites para movimiento horizontal
        // Ajustamos los factores de margen para dar menos libertad a la izquierda
        // y algo más de libertad a la derecha.
        // leftMarginFactor: porcentaje del ancho total que recorta el límite izquierdo
        // rightMarginFactor: porcentaje del ancho total que recorta el límite derecho
        double leftMarginFactor = 0.05; // 5% menos a la izquierda
        double rightMarginFactor = 0.02; // 2% menos a la derecha

        double minX = -maxWidth / 2 + halfCarWidth + (maxWidth * leftMarginFactor);
        double maxX = maxWidth / 2 - halfCarWidth - (maxWidth * rightMarginFactor);

        // Límites para movimiento vertical (relativos al centro)
        double minY = -maxHeight / 2 + halfCarHeight;
        double maxY = maxHeight / 2 - halfCarHeight;

        return GestureDetector(
          onPanStart: (d) {
            // No special action needed on start; we update in onPanUpdate
          },
          onPanUpdate: (d) {
            setState(() {
              if (widget.verticalMovement) {
                double newY = d.localPosition.dy - (maxHeight / 2);
                newY = newY.clamp(minY, maxY);
                // store vertical offset in a temporary field by reusing _x? Better to use a new state var
                // We'll add _y field to the state class dynamically below if not present.
                _y = newY;
                widget.onYPositionChanged?.call(_y);
              } else {
                _x = d.localPosition.dx - (maxWidth / 2);
                _x = _x.clamp(minX, maxX);
                widget.onScoreChanged?.call(_calcScore());
                widget.onXPositionChanged?.call(_x);
              }
            });
          },
            child: SizedBox(
            width: maxWidth,
            height: widget.verticalMovement ? maxHeight : (widget.height + 20),
            child: Stack(
              alignment: widget.verticalMovement ? Alignment.centerLeft : Alignment.center,
              children: [
                Transform.translate(
                  offset: widget.verticalMovement ? Offset(0, _y) : Offset(_x, 0),
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

  // vertical offset stored here
  double _y = 0;

  // Función original para calcular un score (no modificada)
  int _calcScore() {
    double slider = maxWidth - widget.width;
    double percent = (_x + slider / 2) / slider;
    return (percent.clamp(0, 1) * 100).round();
  }

  // La función _reportCarPosition() se ha eliminado para mejorar el rendimiento.
}