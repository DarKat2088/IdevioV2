import 'dart:math';
import 'package:flutter/material.dart';

class CosmicAnimatedBackground extends StatefulWidget {
    final ThemeMode themeMode;
    final bool enabled;

    const CosmicAnimatedBackground({super.key, required this.themeMode, this.enabled = true});

    @override
    State<CosmicAnimatedBackground> createState() => _CosmicAnimatedBackgroundState();
  }

  class _CosmicAnimatedBackgroundState extends State<CosmicAnimatedBackground>
      with SingleTickerProviderStateMixin {
    late final AnimationController _controller;

    final List<_Star> stars = List.generate(
      100,
      (index) => _Star(
        offset: Offset(Random().nextDouble(), Random().nextDouble()),
        size: Random().nextDouble() * 2 + 1,
      ),
    );

    @override
    void initState() {
      super.initState();

      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 30),
      );

      if (widget.enabled) _controller.repeat();
    }

    @override
    void didUpdateWidget(covariant CosmicAnimatedBackground oldWidget) {
      super.didUpdateWidget(oldWidget);
      if (widget.enabled && !_controller.isAnimating) {
        _controller.repeat();
      } else if (!widget.enabled && _controller.isAnimating) {
        _controller.stop();
      }
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    Color _getThemeStartColor() =>
        widget.themeMode == ThemeMode.light ? Color(0xFFFFE0B2) : Color(0xFF0D1B2A);
    Color _getThemeMiddleColor() =>
        widget.themeMode == ThemeMode.light ? Color(0xFFFFB74D) : Color(0xFF1B263B);
    Color _getThemeEndColor() =>
        widget.themeMode == ThemeMode.light ? Color(0xFFFF8A65) : Color(0xFF415A77);

    @override
    Widget build(BuildContext context) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double shift = _controller.value;
          return CustomPaint(
            painter: _CosmicPainter(
              shift: shift,
              stars: stars,
              startColor: _getThemeStartColor(),
              middleColor: _getThemeMiddleColor(),
              endColor: _getThemeEndColor(),
            ),
            child: Container(),
          );
        },
      );
    }
  }

  class _CosmicPainter extends CustomPainter {
    final double shift;
    final List<_Star> stars;
    final Color startColor;
    final Color middleColor;
    final Color endColor;

    _CosmicPainter({
      required this.shift,
      required this.stars,
      required this.startColor,
      required this.middleColor,
      required this.endColor,
    });

    @override
    void paint(Canvas canvas, Size size) {
      final rect = Offset.zero & size;
      final gradient = LinearGradient(
        begin: Alignment(-1 + shift * 2, -1),
        end: Alignment(1 - shift * 2, 1),
        colors: [startColor, middleColor, endColor],
        stops: const [0.0, 0.5, 1.0],
      );
      final paint = Paint()..shader = gradient.createShader(rect);
      canvas.drawRect(rect, paint);

      final starPaint = Paint()..color = Colors.white.withOpacity(0.8);
      for (final star in stars) {
        final pos = Offset(star.offset.dx * size.width, star.offset.dy * size.height);
        canvas.drawCircle(pos, star.size, starPaint);
      }
    }

    @override
    bool shouldRepaint(covariant _CosmicPainter oldDelegate) => true;
  }

  class _Star {
    Offset offset;
    double size;
    _Star({required this.offset, required this.size});
  }
