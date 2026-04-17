// Shared UI kit that mirrors Presso_Mobile_Wireframes.html.
//
// Every public widget here maps 1:1 to a CSS class in the wireframe:
//   .card            -> PressoCard
//   .stat-card       -> StatCard
//   .chip            -> PressoChip
//   .tab-row         -> PressoTabRow
//   .btn-primary     -> BtnPrimary
//   .btn-outline     -> BtnOutline
//   .btn-green       -> BtnGreen
//   .order-step      -> OrderStepItem
//   .tracker         -> Tracker
//   .note-warn       -> NoteWarn
//   .sec-title       -> SectionTitle
//
// Keeping the vocabulary aligned with the wireframe makes it obvious
// which widget to reach for when porting a screen.

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// ── Colors (static, light-only — matches the wireframe) ────────────────────
class PressoTokens {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textHint = Color(0xFF94A3B8);

  static const primary = Color(0xFF0891B2);
  static const primaryDark = Color(0xFF0E7490);
  static const green = Color(0xFF059669);
  static const greenDark = Color(0xFF047857);
  static const amber = Color(0xFFD97706);
  static const red = Color(0xFFDC2626);
  static const purple = Color(0xFF7C3AED);
  static const purpleDark = Color(0xFF6D28D9);
  static const blue = Color(0xFF3B82F6);
}

// ── Section title (sec-title) ───────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String text;
  final EdgeInsets padding;
  const SectionTitle(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 8),
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: PressoTokens.textHint,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      );
}

// ── Card (.card) ────────────────────────────────────────────────────────────
class PressoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Color? background;
  final BorderSide? border;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const PressoCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(14, 0, 14, 10),
    this.padding = const EdgeInsets.all(14),
    this.background,
    this.border,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: background ?? PressoTokens.surface,
        borderRadius: borderRadius,
        border: Border.fromBorderSide(
          border ?? const BorderSide(color: PressoTokens.border, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0,0,0,.04)
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: card,
    );
  }
}

// ── Chip (.chip / .chip-teal / ...) ─────────────────────────────────────────
enum PressoChipColor { teal, green, amber, red, purple, blue, grey }

class PressoChip extends StatelessWidget {
  final String label;
  final PressoChipColor color;
  final IconData? icon;
  const PressoChip({
    super.key,
    required this.label,
    this.color = PressoChipColor.teal,
    this.icon,
  });

  (Color, Color) get _pair {
    switch (color) {
      case PressoChipColor.teal:
        return (PressoTokens.primary.withValues(alpha: .10), PressoTokens.primary);
      case PressoChipColor.green:
        return (PressoTokens.green.withValues(alpha: .10), PressoTokens.green);
      case PressoChipColor.amber:
        return (PressoTokens.amber.withValues(alpha: .10), PressoTokens.amber);
      case PressoChipColor.red:
        return (PressoTokens.red.withValues(alpha: .10), PressoTokens.red);
      case PressoChipColor.purple:
        return (PressoTokens.purple.withValues(alpha: .10), PressoTokens.purple);
      case PressoChipColor.blue:
        return (PressoTokens.blue.withValues(alpha: .10), PressoTokens.blue);
      case PressoChipColor.grey:
        return (const Color(0xFFF1F5F9), PressoTokens.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _pair;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card (.stat-card) ──────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: PressoTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PressoTokens.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: valueColor ?? PressoTokens.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: PressoTokens.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
}

class StatsRow extends StatelessWidget {
  final List<StatCard> cards;
  const StatsRow({super.key, required this.cards});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: cards[i]),
            ],
          ],
        ),
      );
}

// ── Tab row (.tab-row) ──────────────────────────────────────────────────────
class PressoTabRow extends StatelessWidget {
  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onTap;
  const PressoTabRow({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: PressoTokens.border),
          color: const Color(0xFFF8FAFC),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Row(
            children: [
              for (int i = 0; i < labels.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: i == activeIndex
                            ? PressoTokens.primary
                            : Colors.transparent,
                      ),
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: i == activeIndex
                              ? Colors.white
                              : PressoTokens.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

// ── Buttons (.btn-primary / .btn-outline / .btn-green / .btn-purple) ────────
class BtnPrimary extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const BtnPrimary({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [PressoTokens.primary, PressoTokens.primaryDark],
          ),
          boxShadow: [
            BoxShadow(
              color: PressoTokens.primary.withValues(alpha: .25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class BtnGreen extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const BtnGreen({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [PressoTokens.green, PressoTokens.greenDark],
          ),
          boxShadow: [
            BoxShadow(
              color: PressoTokens.green.withValues(alpha: .25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class BtnOutline extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  const BtnOutline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color = PressoTokens.primary,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon ?? Icons.arrow_forward, size: 16, color: color),
          label: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.transparent,
          ),
        ),
      );
}

// ── Order step + Tracker (.order-step / .tracker) ───────────────────────────
enum PressoStepState { pending, active, done }

class OrderStepItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final PressoStepState state;
  const OrderStepItem({
    super.key,
    required this.title,
    this.subtitle,
    this.state = PressoStepState.pending,
  });

  @override
  Widget build(BuildContext context) {
    final (fill, border, glow) = switch (state) {
      PressoStepState.done => (PressoTokens.green, PressoTokens.green, null),
      PressoStepState.active => (PressoTokens.primary, PressoTokens.primary,
          PressoTokens.primary.withValues(alpha: .2)),
      PressoStepState.pending => (Colors.white, PressoTokens.border, null),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: border, width: 2),
              boxShadow: glow == null
                  ? null
                  : [
                      BoxShadow(color: glow, spreadRadius: 3, blurRadius: 0),
                    ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PressoTokens.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: PressoTokens.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Tracker extends StatelessWidget {
  final List<OrderStepItem> steps;
  const Tracker({super.key, required this.steps});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned(
            left: 5,
            top: 10,
            bottom: 10,
            child: Container(width: 2, color: PressoTokens.border),
          ),
          Column(children: steps),
        ],
      );
}

// ── Note-warn (.note-warn) ──────────────────────────────────────────────────
class NoteWarn extends StatelessWidget {
  final String title;
  final String body;
  const NoteWarn({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PressoTokens.red.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: PressoTokens.red,
            width: 1,
            style: BorderStyle.solid, // Flutter has no dashed; solid is closest
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: PressoTokens.red,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              body,
              style: const TextStyle(
                fontSize: 10,
                color: PressoTokens.red,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
}

// ── Mini timeline (inline, for history cards) ───────────────────────────────
class MiniTimeline extends StatelessWidget {
  final int currentIndex; // 0..steps-1 (the active step)
  final int totalSteps;
  final List<String> labels;
  const MiniTimeline({
    super.key,
    required this.currentIndex,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = currentIndex == totalSteps - 1
        ? PressoTokens.green
        : PressoTokens.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (int i = 0; i < totalSteps; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i <= currentIndex
                        ? activeColor
                        : PressoTokens.border,
                  ),
                ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= currentIndex ? activeColor : PressoTokens.border,
                  boxShadow: i == currentIndex
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: .3),
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in labels)
              Text(
                l,
                style: const TextStyle(
                  fontSize: 9,
                  color: PressoTokens.textHint,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── AppBar (.ab) ────────────────────────────────────────────────────────────
// Returns a PreferredSize whose child is constrained to PhoneColumn width so
// headers align with the body on iPads/tablets instead of stretching edge to
// edge.
PreferredSizeWidget pressoAppBar({
  required String title,
  List<Widget>? actions,
  bool showBack = false,
  VoidCallback? onBack,
}) =>
    PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: PhoneColumn(
            background: Colors.white,
            child: SizedBox(
              height: kToolbarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    if (showBack)
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: PressoTokens.textSecondary),
                        onPressed: onBack,
                      )
                    else
                      const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: PressoTokens.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (actions != null) ...actions,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

// ── Responsive breakpoints ──────────────────────────────────────────────────
// Phone:  < 600   – single column, phone-shaped
// Tablet: 600-1023 – roomy single column (up to 720) OR 2-col grids
// Wide:   >= 1024 – capped at 960 so line-length stays readable
class PressoBreakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  static bool isPhone(BuildContext c) =>
      MediaQuery.of(c).size.width < tablet;
  static bool isTablet(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    return w >= tablet && w < desktop;
  }
  static bool isDesktop(BuildContext c) =>
      MediaQuery.of(c).size.width >= desktop;

  /// Maximum content width for the main phone-column body.
  /// Phones use a tight 440px column; tablets/desktops use up to 960 so the
  /// operations app actually makes use of the available width.
  static double bodyMaxWidth(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    if (w < tablet) return 440;
    if (w < desktop) return 760;
    return 960;
  }

  /// Number of job-card columns at a given width.
  static int cardColumns(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    if (w < tablet) return 1;
    if (w < desktop) return 2;
    return 3;
  }
}

// ── Phone-column constraint ─────────────────────────────────────────────────
// On phones, acts as a no-op wrapper (content already fills the screen).
// On tablets/desktops, the GLOBAL responsive wrapper in MaterialApp.builder
// has already capped the whole app to a readable column, so PhoneColumn is
// a pass-through there too — having it cap further would double-constrain
// the layout to a narrow 440 column inside an already-capped 760 frame.
// It's still used throughout the codebase as a background wrapper, so we
// keep the ColoredBox for consistent background colors on each screen.
class PhoneColumn extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final Color background;
  const PhoneColumn({
    super.key,
    required this.child,
    this.maxWidth,
    this.background = PressoTokens.bg,
  });

  @override
  Widget build(BuildContext context) {
    // Simple background wrapper — no width cap. Width is handled globally
    // by the MaterialApp.builder responsive frame.
    return ColoredBox(color: background, child: child);
  }
}

// ── Helper: translate legacy AppColors usage if touched indirectly ─────────
Color pressoChipBgFor(String status) {
  switch (status) {
    case 'Pending':
    case 'Confirmed':
      return PressoChipColor.teal == PressoChipColor.teal
          ? PressoTokens.primary.withValues(alpha: .10)
          : Colors.transparent;
    default:
      return AppColors.surfaceLight;
  }
}
