import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../core/voice_check.dart';
import '../models/user_list.dart';
import '../providers/lists_provider.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import '../widgets/voice_sheet.dart';

/// Alışveriş / adım adım modu: kalan kalemleri tek tek gösterir; kullanıcı
/// ister büyük düğmeye dokunur ister mikrofonu açık tutup "süt aldım" der.
/// Stok listelerinde "aldım" kalemi stoğa yazar + gizler; kontrol
/// listelerinde işaretler. Tüm işlemler için "Geri al" sunulur.
class ShoppingModeScreen extends StatefulWidget {
  const ShoppingModeScreen({super.key, required this.listId});
  final String listId;

  @override
  State<ShoppingModeScreen> createState() => _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends State<ShoppingModeScreen>
    with SingleTickerProviderStateMixin {
  String? _currentId;
  final List<String> _history = [];
  bool _celebrate = false;
  String? _voiceMsg;
  String _heard = '';

  // ── Ses ──
  final _speech = SpeechToText();
  bool _micOn = false;
  bool _speechReady = false;
  String? _localeId;
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    _speech.cancel();
    super.dispose();
  }

  // ── Kuyruk ──────────────────────────────────────────────────────────────
  /// Sırada olanlar: stok listesinde eksikler, kontrol listesinde
  /// işaretlenmemişler — liste görünümündeki sırayla (saatli görevler önce).
  List<ListItem> _queueOf(UserList l) {
    final out = <ListItem>[];
    for (final s in l.sections) {
      for (final c in l.categoriesOf(s.id)) {
        for (final i in l.itemsOfCategory(c.id)) {
          if (l.isInventory ? i.isMissing : !i.isChecked) out.add(i);
        }
      }
    }
    if (!l.isInventory && out.any((i) => i.dueAt != null)) {
      final due = out.where((i) => i.dueAt != null).toList()
        ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
      final rest = out.where((i) => i.dueAt == null).toList();
      return [...due, ...rest];
    }
    return out;
  }

  ListItem _currentOf(List<ListItem> queue) {
    if (_currentId != null) {
      for (final i in queue) {
        if (i.id == _currentId) return i;
      }
    }
    return queue.first;
  }

  String? _nextIdOf(List<ListItem> queue, int idx) =>
      idx >= 0 && idx + 1 < queue.length ? queue[idx + 1].id : null;

  // ── İşaretleme ──────────────────────────────────────────────────────────
  /// Kalemi tamamlandı sayar; geri alma kapanı döndürür.
  Future<Future<void> Function()> _check(UserList l, ListItem item) async {
    final lists = context.read<ListsProvider>();
    final prevStock = item.stockQty;
    final prevChecked = item.isChecked;
    final queueBefore = _queueOf(l);
    final idx = queueBefore.indexWhere((i) => i.id == item.id);
    final wasCurrent = queueBefore.isNotEmpty &&
        _currentOf(queueBefore).id == item.id;

    if (l.isInventory) {
      if (prevStock < item.needQty) {
        await lists.setStock(l.id, item.id, item.needQty);
      }
      if (!prevChecked) await lists.toggleItem(l.id, item.id);
    } else if (!item.isChecked) {
      await lists.toggleItem(l.id, item.id);
    }
    await HapticFeedback.selectionClick();

    if (!mounted) return () async {};
    setState(() {
      if (wasCurrent) _currentId = _nextIdOf(queueBefore, idx);
      _voiceMsg = null;
    });
    await _checkCelebration();
    return () async {
      if (l.isInventory) {
        if (prevStock < item.needQty) {
          await lists.setStock(l.id, item.id, prevStock);
        }
        if (!prevChecked) await lists.toggleItem(l.id, item.id);
      } else {
        await lists.toggleItem(l.id, item.id);
      }
      if (mounted) {
        setState(() {
          _celebrate = false;
          _currentId = item.id;
        });
      }
    };
  }

  Future<void> _checkCelebration() async {
    final l = context.read<ListsProvider>().byId(widget.listId);
    if (l == null) return;
    if (_queueOf(l).isEmpty && l.totalCount > 0 && !_celebrate) {
      if (_micOn) {
        await _speech.stop();
      }
      if (mounted) {
        setState(() {
          _celebrate = true;
          _micOn = false;
        });
      }
    }
  }

  Future<void> _onGotIt() async {
    final l = context.read<ListsProvider>().byId(widget.listId);
    if (l == null) return;
    final queue = _queueOf(l);
    if (queue.isEmpty) return;
    final cur = _currentOf(queue);
    final name = cur.name;
    final undo = await _check(l, cur);
    if (!mounted) return;
    final ms = ScaffoldMessenger.of(context);
    ms.clearSnackBars();
    ms.showSnackBar(SnackBar(
      content: Text(l.isInventory ? '"$name" alındı' : '"$name" tamamlandı'),
      duration: const Duration(milliseconds: 2600),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(label: 'Geri al', onPressed: () async {
        await undo();
      }),
    ));
  }

  void _skip() {
    final l = context.read<ListsProvider>().byId(widget.listId);
    if (l == null) return;
    final queue = _queueOf(l);
    if (queue.isEmpty) return;
    final cur = _currentOf(queue);
    final idx = queue.indexWhere((i) => i.id == cur.id);
    setState(() {
      _history.add(cur.id);
      _currentId = _nextIdOf(queue, idx) ?? queue.first.id;
      _voiceMsg = null;
    });
  }

  void _back() {
    if (_history.isEmpty) return;
    setState(() {
      _currentId = _history.removeLast();
      _voiceMsg = null;
    });
  }

  Future<void> _checkAll(UserList l, List<ListItem> queue) async {
    final lists = context.read<ListsProvider>();
    for (final item in queue) {
      if (l.isInventory) {
        if (item.stockQty < item.needQty) {
          await lists.setStock(l.id, item.id, item.needQty);
        }
        if (!item.isChecked) await lists.toggleItem(l.id, item.id);
      } else if (!item.isChecked) {
        await lists.toggleItem(l.id, item.id);
      }
    }
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _currentId = null);
    await _checkCelebration();
  }

  // ── Ses ────────────────────────────────────────────────────────────────
  Future<void> _toggleMic() async {
    if (_micOn) {
      await _speech.stop();
      if (mounted) setState(() => _micOn = false);
      return;
    }
    if (!_speechReady) {
      try {
        final ok = await _speech.initialize(
          onError: _onError,
          onStatus: _onStatus,
          debugLogging: false,
        );
        if (!ok) {
          _setVoiceMsg(
              'Konuşma tanıma kullanılamıyor. Mikrofon iznini kontrol et.');
          return;
        }
        try {
          final locales = await _speech.locales();
          final tr = locales
              .where((l) => l.localeId.toLowerCase().startsWith('tr'));
          if (tr.isNotEmpty) _localeId = tr.first.localeId;
        } catch (_) {}
        _speechReady = true;
      } catch (_) {
        _setVoiceMsg('Mikrofon başlatılamadı.');
        return;
      }
    }
    if (!mounted) return;
    setState(() => _micOn = true);
    await _startListen();
  }

  Future<void> _startListen() async {
    if (!_micOn || !_speechReady) return;
    try {
      await _speech.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          listenFor: const Duration(seconds: 12),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _micOn = false);
    }
  }

  void _setVoiceMsg(String msg) {
    if (!mounted) return;
    setState(() => _voiceMsg = msg);
  }

  void _onResult(SpeechRecognitionResult r) {
    if (!mounted) return;
    setState(() => _heard = r.recognizedWords);
    if (r.finalResult) _handleUtterance(r.recognizedWords);
  }

  void _onStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      // Sessizlik oturumu kapattı; mikrofon açıksa dinlemeye devam et.
      Future.microtask(() {
        if (mounted && _micOn) _startListen();
      });
    }
  }

  void _onError(SpeechRecognitionError e) {
    if (!mounted) return;
    final soft = e.errorMsg == 'error_no_match' ||
        e.errorMsg == 'error_speech_timeout';
    if (soft && _micOn) {
      // Sessizlik / anlaşılamadı: hata vermeden devam.
      Future.microtask(() {
        if (mounted && _micOn) _startListen();
      });
      return;
    }
    final msg = switch (e.errorMsg) {
      'error_permission' || 'error_audio' =>
        'Mikrofon izni gerekli. Ayarlar → Uygulamalar → Liste Asistanı → İzinler.',
      'error_network' => 'Ses tanıma için internet gerekiyor.',
      _ => 'Ses tanıma hatası: ${e.errorMsg}',
    };
    setState(() {
      _micOn = false;
      _voiceMsg = msg;
    });
  }

  Future<void> _handleUtterance(String text) async {
    if (text.trim().isEmpty) return;
    final l = context.read<ListsProvider>().byId(widget.listId);
    if (l == null) return;
    final queue = _queueOf(l);
    if (queue.isEmpty) {
      if (_micOn) {
        await _speech.stop();
        if (mounted) setState(() => _micOn = false);
      }
      return;
    }

    if (!VoiceCheck.isIntent(text)) {
      _setVoiceMsg('"$text" — söyle: "süt aldım"');
      return;
    }
    if (VoiceCheck.wantsAll(text)) {
      final n = queue.length;
      await _checkAll(l, queue);
      _setVoiceMsg('"$text" → $n kalem tamamlandı');
      return;
    }
    final names = VoiceCheck.match(text, queue.map((i) => i.name));
    if (names.isEmpty) {
      // İsim yoksa sıradaki kalem alındı sayılır ("aldım").
      final cur = _currentOf(queue);
      await _check(l, cur);
      _setVoiceMsg('"$text" → ${cur.name} alındı');
      return;
    }
    final done = <String>[];
    for (final n in names) {
      final item = queue.firstWhere((i) => i.name == n);
      await _check(l, item);
      done.add(n);
    }
    _setVoiceMsg('"$text" → ${done.join(', ')} alındı');
  }

  // ── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lists = context.watch<ListsProvider>();
    final list = lists.byId(widget.listId);
    if (list == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyView(icon: Icons.search_off, title: 'Liste bulunamadı'),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = colorFromHex(list.color);
    final queue = _queueOf(list);
    final total = list.totalCount;
    final done = total - queue.length;
    final title = list.isInventory ? 'Alışveriş modu' : 'Adım adım tamamla';
    final pct = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return AppBackground(
      accent: color,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── Üst çubuk + ilerleme ──
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Kapat',
                      icon: Icon(Icons.close_rounded,
                          color: scheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          Text(list.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: color.withValues(alpha: .25)),
                      ),
                      child: Text('$done/$total',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: color)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => SizedBox(
                    height: 8,
                    child: Stack(
                      children: [
                        Container(
                            decoration: BoxDecoration(
                                color: color.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(6))),
                        FractionallySizedBox(
                          widthFactor: v,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                color,
                                color.lighten(.25),
                              ]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Ses bant ──
              if (_voiceMsg != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: isDark
                          ? scheme.surfaceContainerHigh
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: color.withValues(alpha: .25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.record_voice_over_rounded,
                            size: 16, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_voiceMsg!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700)),
                        ),
                        if (_heard.isNotEmpty)
                          IconButton(
                            tooltip: 'Kapat',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () =>
                                setState(() => _voiceMsg = null),
                          ),
                      ],
                    ),
                  ),
                ),
              // ── Gövde ──
              Expanded(
                child: queue.isEmpty
                    ? _doneView(list, color, done, total, scheme)
                    : _playView(list, queue, color, scheme, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sıradaki kalem kartı + kontroller.
  Widget _playView(UserList list, List<ListItem> queue, Color color,
      ColorScheme scheme, bool isDark) {
    final cur = _currentOf(queue);
    final idx = queue.indexWhere((i) => i.id == cur.id);
    final next = idx >= 0 && idx + 1 < queue.length ? queue[idx + 1] : null;
    final cat = list.categoryById(cur.categoryId);

    Widget tag(IconData icon, String text, Color c) => Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: c.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.withValues(alpha: .20)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 5),
            Text(text,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c)),
          ]),
        );

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                decoration: BoxDecoration(
                  color: isDark ? scheme.surfaceContainerLow : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: color.withValues(alpha: .18)),
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: .16),
                        blurRadius: 30,
                        offset: const Offset(0, 12)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TemplateArt(
                        templateId: list.templateId,
                        icon: list.icon,
                        color: color,
                        size: 76,
                        radius: 22),
                    const SizedBox(height: 14),
                    if (cat != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorFromHex(cat.color, fallback: color)
                              .withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(cat.name,
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .2,
                                color: colorFromHex(cat.color,
                                    fallback: color))),
                      ),
                    const SizedBox(height: 10),
                    Text(cur.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.3,
                                height: 1.12)),
                    if (cur.quantityLabel.isNotEmpty ||
                        list.isInventory ||
                        cur.hasDue ||
                        (cur.note?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          if (cur.quantityLabel.isNotEmpty)
                            tag(Icons.numbers_rounded, cur.quantityLabel,
                                scheme.onSurfaceVariant),
                          if (list.isInventory)
                            tag(
                                Icons.inventory_2_outlined,
                                cur.isMissing
                                    ? 'Stok ${cur.stockLabel}'
                                    : 'Stokta',
                                cur.isMissing
                                    ? scheme.error
                                    : Colors.green.shade700),
                          if (cur.hasDue)
                            tag(Icons.schedule_rounded,
                                dueLabel(cur.dueAt!), color),
                          if (cur.note?.isNotEmpty ?? false)
                            tag(Icons.sticky_note_2_outlined, cur.note!,
                                scheme.onSurfaceVariant),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      next == null ? 'Son kalem!' : 'Sıradaki: ${next.name}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // ── Alt kontroller ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            children: [
              if (voiceInputSupported)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _toggleMic,
                        child: Tooltip(
                          message: 'Sesle işaretle',
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (_, child) => Transform.scale(
                                scale: _micOn
                                    ? 1 + 0.06 * _pulse.value
                                    : 1.0,
                                child: child),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _micOn ? color.gradient : null,
                                color: _micOn
                                    ? null
                                    : scheme.surfaceContainerHighest,
                                boxShadow: _micOn
                                    ? [
                                        BoxShadow(
                                            color: color
                                                .withValues(alpha: .40),
                                            blurRadius: 18,
                                            offset: const Offset(0, 6)),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                  _micOn
                                      ? Icons.mic_rounded
                                      : Icons.mic_none_rounded,
                                  size: 26,
                                  color: _micOn
                                      ? Colors.white
                                      : scheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              _micOn
                                  ? 'Dinliyorum…'
                                  : 'Mikrofonla işaretle',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                          Text('Örnek: "süt aldım"',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _history.isEmpty ? null : _back,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Geri', maxLines: 1),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _skip,
                      icon: const Icon(Icons.skip_next_rounded, size: 16),
                      label: const Text('Atla', maxLines: 1),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          visualDensity: VisualDensity.compact),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _onGotIt,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(list.isInventory ? 'Aldım' : 'Tamamlandı',
                          style:
                              const TextStyle(fontWeight: FontWeight.w800)),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tamamlanma ekranı.
  Widget _doneView(UserList list, Color color, int done, int total,
      ColorScheme scheme) {
    final empty = total == 0;
    return Stack(
      children: [
        if (_celebrate)
          Positioned.fill(
            child: ConfettiBurst(
              colors: [
                color,
                color.lighten(.2),
                Colors.amber,
                Colors.pinkAccent,
                Colors.lightBlueAccent,
                Colors.greenAccent,
              ],
              onDone: () {
                if (mounted) setState(() => _celebrate = false);
              },
            ),
          ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: .12),
                    border: Border.all(color: color.withValues(alpha: .25)),
                  ),
                  child: Icon(
                      empty
                          ? Icons.playlist_add
                          : Icons.celebration_rounded,
                      size: 46,
                      color: color),
                ),
                const SizedBox(height: 18),
                Text(
                    empty
                        ? 'Liste boş'
                        : (list.isInventory ? 'Hepsi tamam!' : 'Bitti!'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (!empty)
                  Text('$done/$total kalem tamamlandı',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant)),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.done_rounded),
                  label: const Text('Bitir',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
