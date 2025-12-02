import 'package:flutter/material.dart';

/// Widget que muestra un coche arrastrable horizontalmente.
///
/// Reporta la posición global del centro del coche para el sistema de colisiones.
class DraggableCar extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;

  /// Puntuación (0-100) según posición.
  final ValueChanged<int>? onScoreChanged;

  /// Reporta la posición GLOBAL del centro del coche.
  final ValueChanged<Offset>? onPositionChanged;

  const DraggableCar({
    super.key,
    required this.imagePath,
    this.width = 100,
    this.height = 60,
    this.onScoreChanged,
    this.onPositionChanged,
  });

  @override
  State<DraggableCar> createState() => _DraggableCarState();
}

class _DraggableCarState extends State<DraggableCar> {
  final GlobalKey _carKey = GlobalKey();

  double _xPosition = 0.0;
  double? _maxWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportCarPosition();
    });
  }

  /// Calcula score 0-100 basado en posición horizontal.
  int _calculateScore() {
    if (_maxWidth == null || _maxWidth! <= widget.width) return 0;

    final sliderLength = _maxWidth! - widget.width;
    final minX = (widget.width / 2) - (_maxWidth! / 2);
    final positionFromStart = _xPosition - minX;

    final percent = (positionFromStart / sliderLength).clamp(0.0, 1.0);
    return (percent * 100).round();
  }

  /// Reporta posición global del centro del coche.
  void _reportCarPosition() {
    if (widget.onPositionChanged == null) return;

    final RenderBox? box =
        _carKey.currentContext?.findRenderObject() as RenderBox?;

    if (box == null) return;

    final position = box.localToGlobal(Offset.zero);

    final containerCenterX = position.dx + box.size.width / 2;
    final containerCenterY = position.dy + box.size.height / 2;

    final globalCarX = containerCenterX + _xPosition;
    final globalCarY = containerCenterY;

    widget.onPositionChanged!(Offset(globalCarX, globalCarY));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _maxWidth = constraints.maxWidth;

      final half = widget.width / 2;
      final minX = -_maxWidth! / 2 + half;
      final maxX = _maxWidth! / 2 - half;

      return GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xPosition += details.delta.dx;
            _xPosition = _xPosition.clamp(minX, maxX);

            widget.onScoreChanged?.call(_calculateScore());
            _reportCarPosition();
          });
        },
        child: Container(
          key: _carKey,
          width: _maxWidth,
          height: widget.height + 20,
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
    });
  }
}

/// Slider vertical estilo "ascensor".
class DraggableCarHorizontal extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
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
  double _yPosition = 0.0;
  double? _maxHeight;

  int _calculateScore() {
    if (_maxHeight == null || _maxHeight! <= widget.height) return 0;

    final sliderLength = _maxHeight! - widget.height;
    final minY = (widget.height / 2) - (_maxHeight! / 2);
    final positionFromStart = _yPosition - minY;

    final percent = (1.0 - (positionFromStart / sliderLength)).clamp(0.0, 1.0);
    return (percent * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _maxHeight = constraints.maxHeight;

      final half = widget.height / 2;
      final minY = -_maxHeight! / 2 + half;
      final maxY = _maxHeight! / 2 - half;

      return GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _yPosition += details.delta.dy;
            _yPosition = _yPosition.clamp(minY, maxY);

            widget.onScoreChanged?.call(_calculateScore());
          });
        },
        child: Container(
          width: widget.width + 20,
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
    });
  }
}
