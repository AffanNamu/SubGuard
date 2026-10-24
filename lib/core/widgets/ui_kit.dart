import 'package:flutter/material.dart';

import '../../domain/scan.dart';
import '../theme/app_theme.dart';

/// A card with a tinted gradient and a softly glowing border, as in the design
/// reference. [tint] picks the accent; without one it is a plain panel.
class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.tint,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 22,
    this.semanticLabel,
  });

  final Widget child;
  final Color? tint;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = tint;
    final shape = BorderRadius.circular(radius);

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent == null ? scheme.surfaceContainerHigh : accent.withValues(alpha: dark ? 0.24 : 0.14),
            scheme.surfaceContainer,
          ],
        ),
        border: Border.all(
          color: (accent ?? scheme.outline).withValues(alpha: dark ? (accent == null ? 0.35 : 0.6) : 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: (accent ?? Colors.black).withValues(alpha: dark ? 0.16 : 0.08),
            blurRadius: dark ? 20 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: shape,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (semanticLabel == null) return card;
    return Semantics(label: semanticLabel, button: onTap != null, child: card);
  }
}

/// The lime call-to-action. Dark text on a lime gradient.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailing,
    this.expand = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailing;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final text = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF0A1A05),
          fontSize: 17,
          fontWeight: FontWeight.w800,
        );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          constraints: BoxConstraints(minHeight: height, minWidth: expand ? double.infinity : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: Brand.limeGradient),
            boxShadow: [
              BoxShadow(color: Brand.lime.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 6)),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[Icon(icon, color: const Color(0xFF0A1A05), size: 24), const SizedBox(width: 10)],
                    Flexible(child: Text(label, style: text, textAlign: TextAlign.center)),
                    if (trailing != null) ...[const SizedBox(width: 10), Icon(trailing, color: const Color(0xFF0A1A05), size: 22)],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The small outlined pill buttons: Take Photo, Choose Images, Upload Many.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.stacked = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  /// Icon above the label, for three buttons side by side on a narrow phone.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: dark ? Colors.white.withValues(alpha: 0.06) : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outline.withValues(alpha: dark ? 0.55 : 0.5)),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52, minWidth: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: stacked ? 6 : 14, vertical: 10),
              child: stacked
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 24, color: scheme.onSurface),
                        const SizedBox(height: 4),
                        Text(label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 22, color: scheme.onSurface),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(label,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ChipKind { completed, processing, needsReview, queued, failed, partial }

/// A status pill: "Completed", "Processing", "Need review"...
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.kind, required this.label});

  factory StatusChip.forBatch(BatchStatus status) => StatusChip(
        kind: switch (status) {
          BatchStatus.completed => ChipKind.completed,
          BatchStatus.processing => ChipKind.processing,
          BatchStatus.needsReview => ChipKind.needsReview,
          BatchStatus.partial => ChipKind.partial,
          BatchStatus.failed => ChipKind.failed,
          BatchStatus.queued || BatchStatus.empty => ChipKind.queued,
        },
        label: status.label,
      );

  factory StatusChip.forScan(ScanStatus status) => StatusChip(
        kind: switch (status) {
          ScanStatus.queued => ChipKind.queued,
          ScanStatus.processing => ChipKind.processing,
          ScanStatus.needsReview => ChipKind.needsReview,
          ScanStatus.confirmed => ChipKind.completed,
          ScanStatus.failed => ChipKind.failed,
        },
        label: switch (status) {
          ScanStatus.queued => 'Pending',
          ScanStatus.processing => 'Processing…',
          ScanStatus.needsReview => 'Need review',
          ScanStatus.confirmed => 'Completed',
          ScanStatus.failed => 'Failed',
        },
      );

  final ChipKind kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final (color, bg, icon) = switch (kind) {
      ChipKind.completed => (c.success, c.successContainer, Icons.check_circle_rounded),
      ChipKind.processing => (c.info, c.infoContainer, Icons.sync_rounded),
      ChipKind.needsReview => (c.warning, c.warningContainer, Icons.warning_amber_rounded),
      ChipKind.partial => (c.warning, c.warningContainer, Icons.timelapse_rounded),
      ChipKind.failed => (c.danger, c.dangerContainer, Icons.error_outline_rounded),
      ChipKind.queued => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest, Icons.hourglass_empty_rounded),
    };
    return Semantics(
      label: 'Status: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rounded square with a gradient fill and a white icon, as on the home tiles.
class GradientIcon extends StatelessWidget {
  const GradientIcon({super.key, required this.icon, required this.color, this.size = 46});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.3),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.95), HSLColor.fromColor(color).withLightness(0.32).toColor()],
          ),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.55),
      );
}

/// The small round arrow at the corner of a tile.
class ArrowDot extends StatelessWidget {
  const ArrowDot({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
        ),
        child: Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(context).colorScheme.onSurface),
      );
}

/// A big home tile: icon, title, one line of help, arrow.
class HomeTile extends StatelessWidget {
  const HomeTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// A count shown on the icon, such as how many booklets wait for review.
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return GlowCard(
      tint: color,
      onTap: onTap,
      semanticLabel: '$title. $subtitle${badge != null && badge! > 0 ? '. $badge waiting' : ''}',
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GradientIcon(icon: icon, color: color),
              if (badge != null && badge! > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 22),
                    decoration: BoxDecoration(color: context.colors.danger, borderRadius: BorderRadius.circular(11)),
                    child: Text('$badge',
                        textAlign: TextAlign.center,
                        style: text.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 8),
          const Align(alignment: Alignment.bottomRight, child: ArrowDot()),
        ],
      ),
    );
  }
}

/// Two tiles to a row, each row as tall as its tallest tile.
class TileRow extends StatelessWidget {
  const TileRow({super.key, required this.children, this.gap = 12});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(child: children[i]),
            ],
          ],
        ),
      );
}
