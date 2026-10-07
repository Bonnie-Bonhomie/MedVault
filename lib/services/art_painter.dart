import 'dart:math' as math;
import 'package:flutter/material.dart';


const kBg = Color(0xFF0A2A20);
const kSurface = Color(0xFF113829);
const kSurface2 = Color(0xFF1B4D3A);
const kAccent = Color(0xFF8FD9AE);
const kAmber = Color(0xFFF2B84B);
const kText = Color(0xFFEAF3EC);
const kMuted = Color(0xFF9DB9A8);

enum ArtKind { shelf, scan, alert }

/// Vector illustrations drawn in code, so the app needs no image assets.
/// Swap for Image.asset(...) if you have real photography.
class FloatingArt extends StatefulWidget {
  final ArtKind kind;
  const FloatingArt(this.kind, {super.key});
  @override
  State<FloatingArt> createState() => _FloatingArtState();
}

class _FloatingArtState extends State<FloatingArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(seconds: 4))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => CustomPaint(
        painter: _ArtPainter(widget.kind, _c.value), size: Size.infinite),
  );
}

class _ArtPainter extends CustomPainter {
  final ArtKind kind;
  final double t;
  _ArtPainter(this.kind, this.t);

  void _bottle(Canvas c, Offset o, double w, double h) {
    RRect box(Offset ctr, double bw, double bh, double r) => RRect.fromRectAndRadius(
        Rect.fromCenter(center: ctr, width: bw, height: bh), Radius.circular(r));
    c.drawRRect(box(o, w, h, w * .18), Paint()..color = const Color(0xFFE7A94A));
    c.drawRRect(box(o.translate(0, -h / 2), w * .92, h * .18, 8),
        Paint()..color = kText);
    final lab = o.translate(0, h * .08);
    c.drawRRect(box(lab, w * .8, h * .42, 8), Paint()..color = kText);
    final p = Paint()..color = const Color(0xFF1F6B4A);
    c.drawRect(Rect.fromCenter(center: lab, width: w * .36, height: w * .1), p);
    c.drawRect(Rect.fromCenter(center: lab, width: w * .1, height: w * .36), p);
  }

  void _capsule(Canvas c, Offset o, double ang, double w, double h, Color a, Color b) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(ang);
    c.clipRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        Radius.circular(h / 2)));
    c.drawRect(Rect.fromLTWH(-w / 2, -h / 2, w / 2, h), Paint()..color = a);
    c.drawRect(Rect.fromLTWH(0, -h / 2, w / 2, h), Paint()..color = b);
    c.restore();
  }

  @override
  void paint(Canvas c, Size s) {
    final m = s.center(Offset.zero);
    final r = s.shortestSide / 2;
    final bob = math.sin(t * 2 * math.pi) * r * .05;
    c.drawCircle(
        m,
        r * .95,
        Paint()
          ..shader = RadialGradient(colors: [kAccent.withOpacity(.35), Colors.transparent])
              .createShader(Rect.fromCircle(center: m, radius: r)));

    switch (kind) {
      case ArtKind.shelf:
        _bottle(c, m.translate(-r * .25, bob), r * .55, r * 1.0);
        _capsule(c, m.translate(r * .5, r * .35 - bob), -.6, r * .6, r * .24, kAccent, kText);
        _capsule(c, m.translate(r * .42, -r * .3 + bob), .5, r * .5, r * .2, kAmber, kText);
        break;
      case ArtKind.scan:
        final box = Rect.fromCenter(center: m.translate(0, bob), width: r * 1.35, height: r * 1.0);
        c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(18)),
            Paint()..color = kText);
        final bar = Paint()..color = kBg;
        for (var i = 0; i < 14; i++) {
          final x = box.left + box.width * .12 + i * box.width * .056;
          c.drawRect(Rect.fromLTWH(x, box.top + box.height * .22, i.isEven ? 5 : 2.5, box.height * .56), bar);
        }
        final y = box.top + box.height * (.15 + .7 * (.5 + .5 * math.sin(t * 2 * math.pi)));
        c.drawRect(Rect.fromLTWH(box.left + 8, y - 1.5, box.width - 16, 3), Paint()..color = kAmber);
        break;
      case ArtKind.alert:
        _bottle(c, m.translate(-r * .15, bob), r * .55, r * 1.0);
        final b = m.translate(r * .42, -r * .38 - bob);
        final pulse = 1 + .08 * math.sin(t * 4 * math.pi);
        c.drawCircle(b, r * .26 * pulse, Paint()..color = kAmber);
        c.drawRect(Rect.fromCenter(center: b.translate(0, -r * .04), width: 6, height: r * .22), Paint()..color = kBg);
        c.drawCircle(b.translate(0, r * .12), 4, Paint()..color = kBg);
        break;
    }
  }

  @override
  bool shouldRepaint(_ArtPainter o) => o.t != t;
}
