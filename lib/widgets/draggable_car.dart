import 'package:flutter/material.dart';

/// Widget que muestra un coche arrastrable horizontalmente, actuando como slider.
///
/// Permite al usuario mover el coche hacia la izquierda o derecha
/// mediante gestos de arrastre (mouse o toque táctil) y notifica un
/// cambio de puntuación del 0 al 100 basado en su posición.
class DraggableCar extends StatefulWidget {
  /// Ruta de la imagen del coche
  final String imagePath;

  /// Ancho del coche
  final double width;

  /// Alto del coche
  final double height;

  /// Callback llamado cuando la puntuación (0-100) cambia.
  final ValueChanged<int>? onScoreChanged;

  const DraggableCar({
    super.key,
    required this.imagePath,
    this.width = 100,
    this.height = 60,
    this.onScoreChanged,
  });

  @override
  State<DraggableCar> createState() => _DraggableCarState();
}

class _DraggableCarState extends State<DraggableCar> {
  /// Posición horizontal del coche (offset desde el centro)
  double _xPosition = 0.0;

  /// Anchura máxima del contenedor, calculada en LayoutBuilder.
  double? _maxWidth;

  /// Calcula la puntuación (0-100) basándose en la posición horizontal del coche.
  int _calculateScore() {
    if (_maxWidth == null || _maxWidth! <= widget.width) {
      return 0;
    }
    // El rango de movimiento real es:
    // minX = -_maxWidth/2 + carHalfWidth
    // maxX = _maxWidth/2 - carHalfWidth
    // Longitud total del rango de movimiento (sliderLength)
    final sliderLength = _maxWidth! - widget.width;

    // Posición relativa al punto más a la izquierda (minX).
    // La posición actual (_xPosition) está centrada en 0.
    // La posición en el extremo izquierdo del slider (minX) es (widget.width / 2) - (_maxWidth / 2)
    final minX = (widget.width / 2) - (_maxWidth! / 2);

    // Posición normalizada: (posición_actual - minX) / sliderLength
    // _xPosition - minX da la distancia desde el punto de inicio.
    // Para simplificar, ajustamos el rango:
    // 1. Convertimos el rango de movimiento de [minX, maxX] a [0, sliderLength].
    final positionFromStart = _xPosition - minX;

    // 2. Calculamos el porcentaje (0.0 a 1.0).
    final percentage = (positionFromStart / sliderLength).clamp(0.0, 1.0);

    // 3. Lo convertimos a una puntuación de 0 a 100 y redondeamos al entero más cercano.
    return (percentage * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Almacena el ancho máximo del contenedor
        _maxWidth = constraints.maxWidth;

        // Calcula los límites para que el coche no salga de la pantalla
        final carHalfWidth = widget.width / 2;

        // Limita la posición entre los bordes del contenedor
        final minX = -_maxWidth! / 2 + carHalfWidth;
        final maxX = _maxWidth! / 2 - carHalfWidth;

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              // Actualiza la posición basándose en el delta del gesto
              _xPosition += details.delta.dx;

              // Asegura que el coche no salga de los límites
              _xPosition = _xPosition.clamp(minX, maxX);

              // Calcula y notifica la nueva puntuación
              if (widget.onScoreChanged != null) {
                widget.onScoreChanged!(_calculateScore());
              }
            });
          },
          child: Container(
            width: _maxWidth,
            height: widget.height + 20, // Espacio extra para padding
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Transform.translate(
              offset: Offset(_xPosition, 0),
              child: Image.asset(
                widget.imagePath,
                width: widget.width,
                height: widget.height,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget que muestra un coche arrastrable verticalmente, actuando como slider.
///
/// Permite al usuario mover el coche hacia arriba o abajo
/// mediante gestos de arrastre (mouse o toque táctil) y notifica un
/// cambio de puntuación del 0 al 100 basado en su posición.
class DraggableCarHorizontal extends StatefulWidget {
  /// Ruta de la imagen del coche (se asume que es una imagen "horizontal" o
  /// una imagen con el coche girado para el layout vertical).
  final String imagePath;

  /// Ancho del coche
  final double width;

  /// Alto del coche
  final double height;

  /// Callback llamado cuando la puntuación (0-100) cambia.
  final ValueChanged<int>? onScoreChanged;

  const DraggableCarHorizontal({
    super.key,
    required this.imagePath,
    this.width = 60,
    this.height = 100,
    this.onScoreChanged,
  });

  @override
  State<DraggableCarHorizontal> createState() => _DraggableCarHorizontalState();
}

class _DraggableCarHorizontalState extends State<DraggableCarHorizontal> {
  /// Posición vertical del coche (offset desde el centro)
  double _yPosition = 0.0;

  /// Altura máxima del contenedor, calculada en LayoutBuilder.
  double? _maxHeight;

  /// Calcula la puntuación (0-100) basándose en la posición vertical del coche.
  int _calculateScore() {
    if (_maxHeight == null || _maxHeight! <= widget.height) {
      return 0;
    }
    // Longitud total del rango de movimiento (sliderLength)
    final sliderLength = _maxHeight! - widget.height;

    // Posición en el extremo superior del slider (minY)
    final minY = (widget.height / 2) - (_maxHeight! / 2);

    // Posición relativa al punto más alto (minY).
    final positionFromStart = _yPosition - minY;

    // Calculamos el porcentaje (0.0 a 1.0).
    // NOTA: Para un slider vertical, queremos que el 100% sea la posición más alta.
    // Por lo tanto, invertimos el porcentaje: 1.0 - (positionFromStart / sliderLength)
    final percentage = (1.0 - (positionFromStart / sliderLength)).clamp(0.0, 1.0);

    // Lo convertimos a una puntuación de 0 a 100 y redondeamos al entero más cercano.
    return (percentage * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Almacena la altura máxima del contenedor
        _maxHeight = constraints.maxHeight;

        // Calcula los límites para que el coche no salga de la pantalla
        final carHalfHeight = widget.height / 2;

        // Limita la posición entre los bordes
        final minY = -_maxHeight! / 2 + carHalfHeight;
        final maxY = _maxHeight! / 2 - carHalfHeight;

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              // Actualiza la posición basándose en el delta del gesto
              _yPosition += details.delta.dy;

              // Asegura que el coche no salga de los límites
              _yPosition = _yPosition.clamp(minY, maxY);

              // Calcula y notifica la nueva puntuación
              if (widget.onScoreChanged != null) {
                widget.onScoreChanged!(_calculateScore());
              }
            });
          },
          child: Container(
            width: widget.width + 20, // Espacio extra para padding
            height: _maxHeight,
            alignment: Alignment.center,
             decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Transform.translate(
              offset: Offset(0, _yPosition),
              child: Image.asset(
                widget.imagePath,
                width: widget.width,
                height: widget.height,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}