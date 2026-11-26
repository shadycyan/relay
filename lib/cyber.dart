import 'package:flutter/material.dart';
import 'theme.dart';

Path cutPath(Size s, double c,
    {bool tl = false, bool tr = false, bool bl = false, bool br = false}) {
  final p = Path();
  p.moveTo(tl ? c : 0, 0);
  p.lineTo(tr ? s.width - c : s.width, 0);
  if (tr) p.lineTo(s.width, c);
  p.lineTo(s.width, br ? s.height - c : s.height);
  if (br) p.lineTo(s.width - c, s.height);
  p.lineTo(bl ? c : 0, s.height);
  if (bl) p.lineTo(0, s.height - c);
  p.lineTo(0, tl ? c : 0);
  p.close();
  return p;
}

class _CutPainter extends CustomPainter {
  final Color fill;
  final Color? border;
  final double cut, bw;
  final bool tl, tr, bl, br, glow;
  _CutPainter(this.fill, this.border, this.cut, this.bw, this.tl, this.tr, this.bl,
      this.br, this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    final p = cutPath(size, cut, tl: tl, tr: tr, bl: bl, br: br);
    if (glow && border != null) {
      canvas.drawPath(
          p,
          Paint()
            ..color = border!.withValues(alpha: .35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = bw + 3
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    canvas.drawPath(p, Paint()..color = fill);
    if (border != null) {
      canvas.drawPath(
          p,
          Paint()
            ..color = border!
            ..style = PaintingStyle.stroke
            ..strokeWidth = bw);
    }
  }

  @override
  bool shouldRepaint(_CutPainter o) =>
      o.fill != fill || o.border != border || o.cut != cut || o.glow != glow ||
      o.tl != tl || o.tr != tr || o.bl != bl || o.br != br;
}

/// panel with chamfered corners. the whole cp2077 ui language in one widget.
class CyberPanel extends StatelessWidget {
  final Widget child;
  final Color fill;
  final Color? border;
  final double cut, borderWidth;
  final bool tl, tr, bl, br, glow;
  final EdgeInsets padding;
  const CyberPanel({
    super.key,
    required this.child,
    this.fill = C.panel,
    this.border,
    this.cut = 12,
    this.borderWidth = 1.2,
    this.tl = false,
    this.tr = false,
    this.bl = false,
    this.br = true,
    this.glow = false,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _CutPainter(fill, border, cut, borderWidth, tl, tr, bl, br, glow),
        child: Padding(padding: padding, child: child),
      );
}

class CyberButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const CyberButton(
      {super.key, required this.label, required this.onTap, this.color = C.yellow});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: CyberPanel(
          fill: color,
          cut: 9,
          tl: true,
          br: true,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(label, style: hud(16, color: Colors.black, w: FontWeight.w700, ls: 2)),
        ),
      );
}

class Avatar extends StatelessWidget {
  final String label;
  final double size;
  const Avatar({super.key, required this.label, this.size = 46});

  String get _initials {
    final t = label.trim();
    if (t.isEmpty || RegExp(r'^[+\d]').hasMatch(t)) return '#';
    final w = t.split(RegExp(r'\s+'));
    return (w.first[0] + (w.length > 1 ? w[1][0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CyberPanel(
          fill: C.panel2,
          border: C.cyan.withValues(alpha: .7),
          cut: 8,
          tl: true,
          br: true,
          padding: EdgeInsets.zero,
          child: Center(child: Text(_initials, style: hud(size * .38, color: C.cyan))),
        ),
      );
}

class HudTag extends StatelessWidget {
  final String text;
  final Color color;
  const HudTag(this.text, {super.key, this.color = C.cyan});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: .6))),
        child: Text(text, style: hud(11, color: color, ls: 1.5)),
      );
}

class CyberBackground extends StatelessWidget {
  final Widget child;
  const CyberBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const RepaintBoundary(child: CustomPaint(painter: _BgPainter())),
        child,
      ]);
}

class _BgPainter extends CustomPainter {
  const _BgPainter();
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = C.bg);
    canvas.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.1,
                  colors: [C.yellow.withValues(alpha: .07), Colors.transparent])
              .createShader(Offset.zero & s));
    canvas.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = RadialGradient(
                  center: Alignment.bottomRight,
                  radius: 1.0,
                  colors: [C.cyan.withValues(alpha: .07), Colors.transparent])
              .createShader(Offset.zero & s));
    final grid = Paint()
      ..color = C.cyan.withValues(alpha: .035)
      ..strokeWidth = 1;
    for (double x = 0; x < s.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, s.height), grid);
    }
    for (double y = 0; y < s.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(s.width, y), grid);
    }
    final scan = Paint()..color = Colors.black.withValues(alpha: .25);
    for (double y = 0; y < s.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, s.width, 1), scan);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
