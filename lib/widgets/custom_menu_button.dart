import 'package:flutter/material.dart';

class CustomMenuButton extends StatefulWidget {
  final String buttonName;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  final double scale;

  const CustomMenuButton({
    super.key,
    required this.buttonName,
    required this.onTap,
    this.width,
    this.height,
    this.scale = 0.5,
  });

  @override
  State<CustomMenuButton> createState() => _CustomMenuButtonState();
}

class _CustomMenuButtonState extends State<CustomMenuButton> {
  bool _isHovering = false;

  String get _assetPath =>
      'assets/ui/buttons/${widget.buttonName}_${_isHovering ? 'hover' : 'normal'}.png';

  @override
  Widget build(BuildContext context) {
    const double baseSize = 220.0;
    final double finalWidth = (widget.width ?? baseSize) * widget.scale;
    final double finalHeight = (widget.height ?? baseSize) * widget.scale;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.translucent,
        child: Image.asset(
          _assetPath,
          width: finalWidth,
          height: finalHeight,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
