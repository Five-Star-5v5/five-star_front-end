import 'package:flutter/material.dart';

/// Fond de marque Kobeta : halo amber en haut, halo sage en bas-gauche,
/// et une grille fine par-dessus. Partagé par la page d'accueil et
/// l'onboarding pour que les deux écrans aient la même identité visuelle.
class KobetaBackdrop extends StatelessWidget {
  const KobetaBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BackdropPainter(), size: Size.infinite);
  }
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Halo amber en haut-centre
    final amberGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.7),
        radius: 0.7,
        colors: [
          const Color(0xFFE8923A).withValues(alpha: 0.13),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, amberGlow);

    // Halo vert en bas-gauche
    final greenGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.7, 0.6),
        radius: 0.5,
        colors: [
          const Color(0xFF4CAF82).withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, greenGlow);

    // Grille 32px
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
