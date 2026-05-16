import 'package:flutter/material.dart';
import 'package:stock_module/modules/presentation/design/iw_design.dart';

enum IwValidityTone { ok, warn, muted }

class IwValidityPill extends StatelessWidget {
  const IwValidityPill({super.key, required this.tone, required this.label});
  final IwValidityTone tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final IconData icon;
    switch (tone) {
      case IwValidityTone.ok:
        bg = Color.alphaBlend(
            IwColors.success.withValues(alpha: 0.14), IwColors.surface);
        fg = IwColors.onSuccessContainer;
        icon = Icons.event_available_outlined;
        break;
      case IwValidityTone.warn:
        bg = Color.alphaBlend(
            IwColors.warning.withValues(alpha: 0.18), IwColors.surface);
        fg = IwColors.onWarningContainer;
        icon = Icons.schedule_outlined;
        break;
      case IwValidityTone.muted:
        bg = IwColors.surfaceContainer;
        fg = IwColors.onSurfaceVariant;
        icon = Icons.all_inclusive;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: tone == IwValidityTone.ok
                ? IwColors.success
                : tone == IwValidityTone.warn
                    ? IwColors.warning
                    : fg,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

enum IwStockState { ok, warn, crit }

class IwQtyBar extends StatelessWidget {
  const IwQtyBar({
    super.key,
    required this.qty,
    required this.max,
    required this.unit,
    this.state = IwStockState.ok,
    this.barWidth = 80,
    this.alignment = CrossAxisAlignment.end,
  });

  final num qty;
  final num max;
  final String unit;
  final IwStockState state;
  final double barWidth;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final pct = max <= 0 ? 0.0 : (qty / max).clamp(0.0, 1.0).toDouble();
    final fill = switch (state) {
      IwStockState.warn => IwColors.warning,
      IwStockState.crit => IwColors.error,
      IwStockState.ok => IwColors.success,
    };
    return Column(
      crossAxisAlignment: alignment,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: IwColors.onSurface,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            children: [
              TextSpan(text: _fmtQty(qty)),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: IwColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: barWidth,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(color: IwColors.surfaceContainerHigh),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(color: fill),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _fmtQty(num qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
