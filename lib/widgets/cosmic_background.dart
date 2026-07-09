import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animated cosmic background with gradient + floating particles.
class CosmicBackground extends StatefulWidget {
  final Widget child;
  final bool showParticles;

  const CosmicBackground({
    super.key,
    required this.child,
    this.showParticles = true,
  });

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    final rng = Random();
    _particles = List.generate(30, (_) => _Particle(rng));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: widget.showParticles
          ? AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticlePainter(_particles, _controller.value),
                  child: widget.child,
                );
              },
            )
          : widget.child,
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double opacity;

  _Particle(Random rng)
    : x = rng.nextDouble(),
      y = rng.nextDouble(),
      radius = rng.nextDouble() * 2.0 + 0.5,
      speed = rng.nextDouble() * 0.5 + 0.2,
      opacity = rng.nextDouble() * 0.4 + 0.1;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final yOffset = (p.y + progress * p.speed) % 1.0;
      final paint = Paint()
        ..color = AppColors.primary.withValues(alpha: p.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 2);

      canvas.drawCircle(
        Offset(p.x * size.width, yOffset * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
