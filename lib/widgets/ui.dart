import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../core/app_icons.dart';
import '../core/theme.dart';

/// Yerleşik şablonlar için illüstrasyon dosyaları
const _artIds = {
  'seyahat',
  'market',
  'piknik',
  'mangal',
  'kamp',
  'plaj',
  'tasinma'
};

String? artAssetFor(String? templateId) {
  if (templateId == null) return null;
  return _artIds.contains(templateId) ? 'assets/art/$templateId.jpg' : null;
}

/// Şablon görseli: yerleşiklerde illüstrasyon, özel tiplerde gradyanlı ikon.
class TemplateArt extends StatelessWidget {
  const TemplateArt({
    super.key,
    required this.templateId,
    required this.icon,
    required this.color,
    this.size = 64,
    this.radius,
    this.fit = BoxFit.cover,
  });
  final String? templateId;
  final String icon;
  final Color color;
  final double size;
  final double? radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * 0.3;
    final asset = artAssetFor(templateId);
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: SizedBox(
        width: size,
        height: size,
        child: asset != null
            ? Image.asset(asset,
                fit: fit,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => _iconArt())
            : _iconArt(),
      ),
    );
  }

  Widget _iconArt() => DecoratedBox(
        decoration: BoxDecoration(gradient: color.gradient),
        child: Stack(
          children: [
            Positioned(
              right: -size * 0.18,
              bottom: -size * 0.18,
              child: Container(
                width: size * 0.7,
                height: size * 0.7,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.14)),
              ),
            ),
            Center(
              child: Icon(AppIcons.get(icon),
                  color: Colors.white, size: size * 0.5),
            ),
          ],
        ),
      );
}

/// Hafif renk tonlu, yumuşak köşeli kart
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.tint,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.radius = AppTheme.radiusCard,
    this.elevated = false,
  });
  final Widget child;
  final Color? tint;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = tint;
    final bg = t == null
        ? scheme.surfaceContainerLow
        : Color.alphaBlend(t.withValues(alpha: isDark ? 0.16 : 0.09),
            isDark ? scheme.surfaceContainerLow : Colors.white);
    return Padding(
      padding: margin,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
                color: (t ?? scheme.outlineVariant)
                    .withValues(alpha: isDark ? 0.28 : 0.22)),
            boxShadow: elevated && !isDark
                ? [
                    BoxShadow(
                        color: (t ?? scheme.shadow).withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8))
                  ]
                : null,
          ),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(radius),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Küçük bilgi rozeti (ikon + metin)
class Pill extends StatelessWidget {
  const Pill(
      {super.key,
      required this.label,
      this.icon,
      required this.color,
      this.filled = false,
      this.onTap});
  final String label;
  final IconData? icon;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, color: fg, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(20), child: child);
  }
}

/// Sıçrayan animasyonlu onay kutusu (yuvarlak veya köşeli)
class AnimatedCheck extends StatelessWidget {
  const AnimatedCheck(
      {super.key,
      required this.checked,
      required this.color,
      this.size = 26,
      this.round = true});
  final bool checked;
  final Color color;
  final double size;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: checked ? color.gradient : null,
        color: checked ? null : Colors.transparent,
        border: Border.all(
            color: checked ? Colors.transparent : scheme.outline, width: 2),
        borderRadius: BorderRadius.circular(round ? size : size * 0.3),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: checked ? 0.35 : 0),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: AnimatedScale(
        scale: checked ? 1 : 0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.elasticOut,
        child:
            Icon(Icons.check_rounded, size: size * 0.66, color: Colors.white),
      ),
    );
  }
}

/// Liste elemanları için kademeli giriş animasyonu
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn(
      {super.key,
      required this.child,
      this.index = 0,
      this.delayPerItem = const Duration(milliseconds: 40),
      this.duration = const Duration(milliseconds: 380)});
  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    final delay = widget.delayPerItem * math.min(widget.index, 12);
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _a,
        builder: (_, child) => Opacity(
          opacity: _a.value,
          child: Transform.translate(
              offset: Offset(0, 18 * (1 - _a.value)), child: child),
        ),
        child: widget.child,
      );
}

/// Gradyanlı birincil buton
class GradientButton extends StatelessWidget {
  const GradientButton(
      {super.key,
      required this.label,
      required this.color,
      this.icon,
      this.onPressed,
      this.height = 54});
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.5,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: color.gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bölüm başlığı (büyük, kalın)
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.padding});
  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Row(
          children: [
            Expanded(
                child:
                    Text(text, style: Theme.of(context).textTheme.titleMedium)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// Tamamlanma kutlaması: kısa süreli konfeti yağmuru
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.colors, this.onDone});
  final List<Color> colors;
  final VoidCallback? onDone;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600))
    ..forward().whenComplete(() => widget.onDone?.call());
  late final List<_Particle> _parts;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _parts = List.generate(90, (i) {
      return _Particle(
        x: rnd.nextDouble(),
        vy: 0.55 + rnd.nextDouble() * 0.6,
        drift: (rnd.nextDouble() - 0.5) * 0.35,
        size: 6 + rnd.nextDouble() * 7,
        rot: rnd.nextDouble() * math.pi * 2,
        spin: (rnd.nextDouble() - 0.5) * 10,
        color: widget.colors[i % widget.colors.length],
        delay: rnd.nextDouble() * 0.35,
        round: rnd.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            painter: _ConfettiPainter(_parts, _c.value),
            size: Size.infinite,
          ),
        ),
      );
}

class _Particle {
  _Particle(
      {required this.x,
      required this.vy,
      required this.drift,
      required this.size,
      required this.rot,
      required this.spin,
      required this.color,
      required this.delay,
      required this.round});
  final double x, vy, drift, size, rot, spin, delay;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.parts, this.t);
  final List<_Particle> parts;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in parts) {
      final lt = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      final y = -20 + (size.height + 40) * lt * p.vy;
      final x =
          size.width * (p.x + p.drift * lt) + math.sin(lt * 9 + p.rot) * 14;
      final fade = lt > 0.75 ? (1 - (lt - 0.75) / 0.25) : 1.0;
      paint.color = p.color.withValues(alpha: fade.clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + p.spin * lt);
      final r = Rect.fromCenter(
          center: Offset.zero, width: p.size, height: p.size * 0.6);
      if (p.round) {
        canvas.drawOval(r, paint);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(1.5)), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

/// Gradyanlı başlık arka planı (detay/oluşturma ekranları)
class HeroBackdrop extends StatelessWidget {
  const HeroBackdrop(
      {super.key,
      required this.color,
      required this.child,
      this.templateId,
      this.icon,
      this.artOpacity = 0.22});
  final Color color;
  final Widget child;
  final String? templateId;
  final String? icon;
  final double artOpacity;

  @override
  Widget build(BuildContext context) {
    final asset = artAssetFor(templateId);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: color.gradient),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          Positioned(
            left: -50,
            bottom: -70,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          if (asset != null)
            Positioned(
              right: -10,
              bottom: -20,
              child: Opacity(
                opacity: artOpacity,
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, Colors.white],
                    stops: [0.0, 0.45],
                  ).createShader(r),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(asset,
                      width: 190, height: 190, fit: BoxFit.cover),
                ),
              ),
            )
          else if (icon != null)
            Positioned(
              right: -14,
              bottom: -24,
              child: Icon(AppIcons.get(icon),
                  size: 170, color: Colors.white.withValues(alpha: 0.12)),
            ),
          child,
        ],
      ),
    );
  }
}

/// Kategori kalemlerini saran kart; satırlar ince çizgiyle ayrılır.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children, this.tint});
  final List<Widget> children;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Material(
        color: isDark ? scheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color:
                    scheme.outlineVariant.withValues(alpha: isDark ? .35 : .5)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                      height: 1,
                      indent: 50,
                      color: scheme.outlineVariant.withValues(alpha: .35)),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Yumuşak gradyanlı, renk lekeli sayfa arka planı.
/// Scaffold'ı `AppBackground(child: Scaffold(backgroundColor: Colors.transparent))`
/// şeklinde sarmak yeterli.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.accent});
  final Widget child;

  /// Lekelerin rengi; verilmezse temanın birincil rengi kullanılır.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final a = accent ?? scheme.primary;
    final b = a.shiftHue(40);
    final c = a.shiftHue(-50);
    final base = isDark ? scheme.surface : const Color(0xFFF6F7FB);
    final top = isDark
        ? Color.alphaBlend(a.withValues(alpha: .16), base)
        : Color.alphaBlend(a.withValues(alpha: .15), Colors.white);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, base],
          stops: const [0, .55],
        ),
      ),
      child: Stack(
        children: [
          _Blob(
              color: a,
              size: 420,
              alignment: const Alignment(-1.3, -1.0),
              opacity: isDark ? .30 : .42),
          _Blob(
              color: b,
              size: 360,
              alignment: const Alignment(1.4, -0.5),
              opacity: isDark ? .22 : .34),
          _Blob(
              color: c,
              size: 340,
              alignment: const Alignment(-1.3, 1.25),
              opacity: isDark ? .20 : .30),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob(
      {required this.color,
      required this.size,
      required this.alignment,
      required this.opacity});
  final Color color;
  final double size;
  final Alignment alignment;
  final double opacity;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: Align(
            alignment: alignment,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  color.withValues(alpha: opacity),
                  color.withValues(alpha: 0),
                ]),
              ),
            ),
          ),
        ),
      );
}
