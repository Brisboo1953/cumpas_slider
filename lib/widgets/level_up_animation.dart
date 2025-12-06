import 'package:flutter/material.dart';

/// Widget que muestra una animación de "Level Up" con fade, escala y rotación
/// Se autodestruye después de 1.5 segundos
class LevelUpAnimationWidget extends StatefulWidget {
  final VoidCallback? onComplete;

  const LevelUpAnimationWidget({super.key, this.onComplete});

  @override
  State<LevelUpAnimationWidget> createState() => _LevelUpAnimationWidgetState();
}

class _LevelUpAnimationWidgetState extends State<LevelUpAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador principal con duración de 1.5 segundos
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // FADE: Aparece rápido (0-0.2), se mantiene (0.2-0.7), desaparece gradual (0.7-1.0)
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    // ESCALA: Crece rápido a 150% (0-0.3), luego vuelve a 100% (0.3-1.0)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_controller);

    // ROTACIÓN: Una vuelta completa (360 grados = 2π radianes)
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0, // 1.0 = 360 grados en RotationTransition
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Iniciar animación
    _controller.forward().then((_) {
      // Llamar callback cuando termine
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: RotationTransition(
          turns: _rotationAnimation,
          child: Image.asset(
            'assets/images/level_up.png',
            width: 300,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
