import 'package:flutter/material.dart';

class AnimatedRainbowText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final ThemeMode themeMode;

  const AnimatedRainbowText({
    Key? key,
    required this.text,
    this.style,
    required this.themeMode,
  }) : super(key: key);

  @override
  _AnimatedRainbowTextState createState() => _AnimatedRainbowTextState();
}

class _AnimatedRainbowTextState extends State<AnimatedRainbowText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.themeMode == ThemeMode.light
        ? [
            Colors.red.shade300,
            Colors.orange.shade300,
            Colors.yellow.shade600,
            Colors.green.shade400,
            Colors.blue.shade300,
            Colors.purple.shade300,
          ]
        : [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.purple,
          ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double shift = _controller.value * 2;
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: colors,
              begin: Alignment(-1 + shift, -1),
              end: Alignment(1 + shift, 1),
              tileMode: TileMode.mirror,
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
          },
          blendMode: BlendMode.srcIn,
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: widget.style ??
                TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.themeMode == ThemeMode.light
                      ? Colors.indigo[900]
                      : Colors.white,
                ),
          ),
        );
      },
    );
  }
}
