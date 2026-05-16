import 'package:flutter/material.dart';
import 'package:stock_module/modules/presentation/design/iw_design.dart';

/// Marca InOutWare desenhada vetorialmente.
class IwBrandMark extends StatelessWidget {
  const IwBrandMark({
    super.key,
    this.size = 22,
    this.color = Colors.white,
    this.outArrowColor = IwColors.accentOrange,
  });

  final double size;
  final Color color;
  final Color outArrowColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _IwBrandMarkPainter(color: color, outArrow: outArrowColor),
    );
  }
}

class _IwBrandMarkPainter extends CustomPainter {
  _IwBrandMarkPainter({required this.color, required this.outArrow});
  final Color color;
  final Color outArrow;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120.0;
    canvas.scale(scale, scale);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final warehouse = Path()
      ..moveTo(40, 22)
      ..lineTo(80, 22)
      ..arcToPoint(const Offset(98, 40), radius: const Radius.circular(18))
      ..lineTo(98, 64)
      ..moveTo(98, 88)
      ..lineTo(98, 80)
      ..arcToPoint(const Offset(80, 98), radius: const Radius.circular(18))
      ..lineTo(40, 98)
      ..arcToPoint(const Offset(22, 80), radius: const Radius.circular(18))
      ..lineTo(22, 56)
      ..moveTo(22, 32)
      ..lineTo(22, 40)
      ..arcToPoint(const Offset(40, 22), radius: const Radius.circular(18));
    canvas.drawPath(warehouse, stroke);

    final fillIn = Paint()..color = color;
    canvas.drawPath(
      Path()
        ..moveTo(0, 36)
        ..lineTo(38, 36)
        ..lineTo(38, 28)
        ..lineTo(56, 44)
        ..lineTo(38, 60)
        ..lineTo(38, 52)
        ..lineTo(0, 52)
        ..close(),
      fillIn,
    );

    final fillOut = Paint()..color = outArrow;
    canvas.drawPath(
      Path()
        ..moveTo(64, 76)
        ..lineTo(102, 76)
        ..lineTo(102, 68)
        ..lineTo(120, 84)
        ..lineTo(102, 100)
        ..lineTo(102, 92)
        ..lineTo(64, 92)
        ..close(),
      fillOut,
    );
  }

  @override
  bool shouldRepaint(covariant _IwBrandMarkPainter old) =>
      old.color != color || old.outArrow != outArrow;
}

class IwBrandLogo extends StatelessWidget {
  const IwBrandLogo({super.key, this.size = 34, this.background = IwColors.primaryDeep});
  final double size;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: IwBrandMark(size: size * 0.65),
    );
  }
}

class IwWordmark extends StatelessWidget {
  const IwWordmark({super.key, this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: IwColors.onSurface,
          letterSpacing: -0.08,
        ),
        children: const [
          TextSpan(text: 'In'),
          TextSpan(
            text: 'Out',
            style: TextStyle(
              color: IwColors.accentOrange,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: 'Ware'),
        ],
      ),
    );
  }
}

class IwSyncPill extends StatelessWidget {
  const IwSyncPill({super.key, this.synced = true, this.label});
  final bool synced;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final bg = synced
        ? Color.alphaBlend(IwColors.success.withValues(alpha: 0.12), IwColors.surface)
        : Color.alphaBlend(IwColors.warning.withValues(alpha: 0.14), IwColors.surface);
    final fg = synced ? IwColors.onSuccessContainer : IwColors.onWarningContainer;
    final dot = synced ? IwColors.success : IwColors.warning;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label ?? (synced ? 'Sincronizado' : 'Offline'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg),
          ),
        ],
      ),
    );
  }
}

class IwAvatar extends StatelessWidget {
  const IwAvatar({super.key, required this.initials, this.size = 32});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [IwColors.primary, IwColors.primaryDeep],
        ),
        border: Border.all(color: IwColors.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: (size * 0.38).roundToDouble(),
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class IwBreadcrumb extends StatelessWidget {
  const IwBreadcrumb({super.key, this.icon, required this.label, this.sub});
  final IconData? icon;
  final String label;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: IwColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: IwColors.primary),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: IwColors.onSurface,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(width: 6),
            const Text('/', style: TextStyle(color: IwColors.outline)),
            const SizedBox(width: 6),
            Text(
              sub!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: IwColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class IwBrandRibbon extends StatelessWidget {
  const IwBrandRibbon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            IwColors.primaryDeep,
            IwColors.primary,
            IwColors.accentOrange,
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}
