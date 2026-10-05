import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/theme.dart';
import '../core/voice_parser.dart';

/// Bu platformda sesle ekleme düğmesi gösterilsin mi?
bool get voiceInputSupported =>
    kIsWeb ||
    Platform.isAndroid ||
    Platform.isIOS ||
    Platform.isMacOS ||
    Platform.isWindows;

/// Sesle kalem ekleme sayfası. Dinler, canlı metni gösterir, kalemleri
/// ayrıştırıp onaylatır. Sonuç: eklenecek [VoiceEntry] listesi (iptalde null).
Future<List<VoiceEntry>?> showVoiceSheet(BuildContext context,
    {required Color color}) {
  return showModalBottomSheet<List<VoiceEntry>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _VoiceSheet(color: color),
  );
}

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet({required this.color});
  final Color color;

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet>
    with SingleTickerProviderStateMixin {
  final _speech = SpeechToText();
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  bool _ready = false;
  bool _listening = false;
  String _error = '';
  String _text = '';
  double _level = 0;
  List<VoiceEntry> _entries = const [];
  final Set<VoiceEntry> _removed = {};
  String? _localeId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final ok = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: false,
      );
      if (!mounted) return;
      if (!ok) {
        setState(() => _error =
            'Konuşma tanıma kullanılamıyor. Mikrofon iznini ve cihazın konuşma servisini kontrol et.');
        return;
      }
      // Türkçe varsa onu seç
      try {
        final locales = await _speech.locales();
        final tr = locales.where((l) =>
            l.localeId.toLowerCase().startsWith('tr'));
        if (tr.isNotEmpty) _localeId = tr.first.localeId;
      } catch (_) {}
      setState(() => _ready = true);
      await _start();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Konuşma tanıma başlatılamadı: $e');
      }
    }
  }

  Future<void> _start() async {
    if (!_ready) return;
    setState(() {
      _error = '';
      _listening = true;
    });
    try {
      await _speech.listen(
        onResult: _onResult,
        onSoundLevelChange: (l) {
          if (mounted) setState(() => _level = l);
        },
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          listenFor: const Duration(seconds: 40),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _listening = false;
          _error = 'Dinleme başlatılamadı: $e';
        });
      }
    }
  }

  Future<void> _stop() async {
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  void _onResult(SpeechRecognitionResult r) {
    if (!mounted) return;
    setState(() {
      _text = r.recognizedWords;
      _entries = VoiceParser.parse(_text);
      if (r.finalResult) _listening = false;
    });
  }

  void _onStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      setState(() => _listening = false);
    }
  }

  void _onError(SpeechRecognitionError e) {
    if (!mounted) return;
    final msg = switch (e.errorMsg) {
      'error_no_match' => 'Anlaşılamadı, tekrar dener misin?',
      'error_speech_timeout' => 'Ses algılanmadı.',
      'error_permission' ||
      'error_audio' =>
        'Mikrofon izni gerekli. Ayarlar → Uygulamalar → Liste Asistanı → İzinler.',
      'error_network' => 'Konuşma tanıma için internet gerekiyor.',
      _ => 'Hata: ${e.errorMsg}',
    };
    setState(() {
      _listening = false;
      if (_text.isEmpty) _error = msg;
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = widget.color;
    final kept = _entries.where((e) => !_removed.contains(e)).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sesle ekle', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Örnek: "zeytin, iki ekmek, bir kilo domates"',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            // Mikrofon
            Center(
              child: GestureDetector(
                onTap: _listening ? _stop : _start,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) {
                    final lvl = (_level.clamp(-2, 10) + 2) / 12;
                    final scale = _listening
                        ? 1 + 0.08 * _pulse.value + 0.25 * lvl
                        : 1.0;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_listening)
                          Transform.scale(
                            scale: scale * 1.35,
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: c.withValues(alpha: 0.12)),
                            ),
                          ),
                        Transform.scale(scale: scale, child: child),
                      ],
                    );
                  },
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _listening ? c.gradient : null,
                      color: _listening ? null : scheme.surfaceContainerHighest,
                      boxShadow: _listening
                          ? [
                              BoxShadow(
                                  color: c.withValues(alpha: .4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8))
                            ]
                          : null,
                    ),
                    child: Icon(
                        _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        size: 40,
                        color: _listening ? Colors.white : scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                !_ready && _error.isEmpty
                    ? 'Hazırlanıyor…'
                    : _listening
                        ? 'Dinliyorum… (durdurmak için dokun)'
                        : (_text.isEmpty
                            ? 'Konuşmak için mikrofona dokun'
                            : 'Tekrar söylemek için mikrofona dokun'),
                style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),
            // Canlı metin
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _error.isNotEmpty
                    ? _error
                    : (_text.isEmpty ? '…' : '"$_text"'),
                style: TextStyle(
                    fontSize: 15,
                    fontStyle: _text.isEmpty ? FontStyle.italic : null,
                    color: _error.isNotEmpty
                        ? scheme.error
                        : (_text.isEmpty
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface)),
              ),
            ),
            if (_entries.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Eklenecekler (${kept.length})',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in _entries)
                    InputChip(
                      label: Text(e.label),
                      selected: !_removed.contains(e),
                      showCheckmark: false,
                      avatar: Icon(
                          _removed.contains(e)
                              ? Icons.add_rounded
                              : Icons.check_rounded,
                          size: 16),
                      onPressed: () => setState(() => _removed.contains(e)
                          ? _removed.remove(e)
                          : _removed.add(e)),
                      onDeleted: _removed.contains(e)
                          ? null
                          : () => setState(() => _removed.add(e)),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Vazgeç')),
                const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: c, foregroundColor: Colors.white),
                  onPressed: kept.isEmpty
                      ? null
                      : () {
                          _speech.cancel();
                          Navigator.pop(context, kept);
                        },
                  icon: const Icon(Icons.playlist_add_check_rounded),
                  label: Text(kept.isEmpty
                      ? 'Ekle'
                      : 'Ekle (${math.min(kept.length, 99)})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
