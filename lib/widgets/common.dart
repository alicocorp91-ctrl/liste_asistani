import 'package:flutter/material.dart';
import '../core/app_icons.dart';
import '../core/utils.dart';

/// Renkli yuvarlak ikon rozeti
class IconBadge extends StatelessWidget {
  const IconBadge(
      {super.key,
      required this.icon,
      required this.color,
      this.size = 40,
      this.iconSize});
  final String icon;
  final Color color;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(size * 0.3)),
        child: Icon(AppIcons.get(icon),
            color: color, size: iconSize ?? size * 0.55),
      );
}

/// Halka ilerleme göstergesi + yüzde
class ProgressRing extends StatelessWidget {
  const ProgressRing(
      {super.key,
      required this.progress,
      this.size = 56,
      this.color,
      this.label});
  final double progress;
  final double size;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0, 1),
            strokeWidth: size * 0.1,
            backgroundColor: c.withValues(alpha: 0.15),
            color: c,
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Text(
              label ?? '${(progress * 100).round()}%',
              style: TextStyle(
                  fontSize: size * 0.24, fontWeight: FontWeight.bold, color: c),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kendi kendini yenileyen geri sayım rozeti
class CountdownChip extends StatefulWidget {
  const CountdownChip({super.key, required this.start, this.end, this.color});
  final DateTime start;
  final DateTime? end;
  final Color? color;

  @override
  State<CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<CountdownChip> {
  late final Stream<int> _tick =
      Stream.periodic(const Duration(seconds: 30), (i) => i);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _tick,
      builder: (context, _) {
        final text = countdownText(widget.start, end: widget.end);
        final scheme = Theme.of(context).colorScheme;
        final past = text == 'Geçti' || text == 'Tamamlandı';
        final ongoing = text == 'Devam ediyor' || text == 'Bugün';
        final c = past
            ? scheme.outline
            : (ongoing ? Colors.green : (widget.color ?? scheme.primary));
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: c.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ongoing ? Icons.play_circle_outline : Icons.schedule,
                  size: 14, color: c),
              const SizedBox(width: 4),
              Text(text,
                  style: TextStyle(
                      fontSize: 12, color: c, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}

/// Boş durum görünümü
class EmptyView extends StatelessWidget {
  const EmptyView(
      {super.key,
      required this.icon,
      required this.title,
      this.subtitle,
      this.action});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: scheme.outlineVariant),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.outline),
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Kategori başlığı (ikon + ad + sayaç + isteğe bağlı aksiyon)
class CategoryHeader extends StatelessWidget {
  const CategoryHeader({
    super.key,
    required this.name,
    required this.icon,
    required this.colorHex,
    this.count,
    this.total,
    this.trailing,
    this.onTap,
  });
  final String name;
  final String icon;
  final String colorHex;
  final int? count;
  final int? total;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = colorFromHex(colorHex);
    final done = count != null && total != null && total! > 0 && count == total;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
        child: Row(
          children: [
            IconBadge(icon: icon, color: c, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold, color: c)),
            ),
            if (count != null && total != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (done ? Colors.green : c).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$count/$total',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: done ? Colors.green : c)),
              ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Basit onay dialogu
Future<bool> confirm(BuildContext context,
    {required String title,
    required String message,
    String okLabel = 'Sil',
    bool destructive = true}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(okLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Tek satır metin girişi dialogu
Future<String?> promptText(BuildContext context,
    {required String title,
    String? initial,
    String hint = '',
    String okLabel = 'Kaydet',
    TextInputType? keyboard}) async {
  final ctrl = TextEditingController(text: initial);
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: keyboard,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(okLabel)),
      ],
    ),
  );
  final v = r?.trim();
  return (v == null || v.isEmpty) ? null : v;
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
