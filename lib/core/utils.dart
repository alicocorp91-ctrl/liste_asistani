import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// "#RRGGBB" -> Color. Geçersizse gri.
Color colorFromHex(String? hex, {Color fallback = Colors.grey}) {
  if (hex == null) return fallback;
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? fallback : Color(v);
}

String colorToHex(Color c) {
  final r = (c.r * 255).round().clamp(0, 255);
  final g = (c.g * 255).round().clamp(0, 255);
  final b = (c.b * 255).round().clamp(0, 255);
  return '#${r.toRadixString(16).padLeft(2, '0')}'
          '${g.toRadixString(16).padLeft(2, '0')}'
          '${b.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}

final DateFormat _dfLong = DateFormat('d MMMM yyyy', 'tr_TR');
final DateFormat _dfShort = DateFormat('d MMM', 'tr_TR');
final DateFormat _dfDateTime = DateFormat('d MMM yyyy HH:mm', 'tr_TR');
final DateFormat _dfWeekday = DateFormat('EEEE', 'tr_TR');
final DateFormat _dfTime = DateFormat('HH:mm', 'tr_TR');

String fmtDate(DateTime d) => _dfLong.format(d);
String fmtDateShort(DateTime d) => _dfShort.format(d);
String fmtDateTime(DateTime d) => _dfDateTime.format(d);
String fmtWeekday(DateTime d) => _dfWeekday.format(d);
String fmtTime(DateTime d) => _dfTime.format(d);

/// Saatli görev etiketi: "Gecikti · 4 Eki" / "Bugün 14:30" / "Yarın 09:00"
/// / "5 Eki 15:00"
String dueLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = day.difference(today).inDays;
  if (diff < 0) return 'Gecikti · ${_dfShort.format(d)}';
  if (diff == 0) return 'Bugün ${_dfTime.format(d)}';
  if (diff == 1) return 'Yarın ${_dfTime.format(d)}';
  return '${_dfShort.format(d)} ${_dfTime.format(d)}';
}

/// Görev etiketi rengi: tamamlandı → gri, gecikmiş → kırmızı,
/// bugün → turuncu, otherwise vurgu rengi.
Color dueColor(DateTime d,
    {required bool checked, required ColorScheme scheme}) {
  if (checked) return scheme.outline;
  final now = DateTime.now();
  if (d.isBefore(now)) return scheme.error;
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return const Color(0xFFEF6C00);
  }
  return scheme.primary;
}

/// "12 Eyl – 19 Eyl 2026" tarzı aralık metni
String fmtRange(DateTime? start, DateTime? end) {
  if (start == null) return '';
  if (end == null) return fmtDate(start);
  if (start.year == end.year) {
    return '${_dfShort.format(start)} – ${_dfLong.format(end)}';
  }
  return '${fmtDate(start)} – ${fmtDate(end)}';
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Güvenli tarih parse
DateTime? parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}

/// Deterministik 31-bit FNV-1a hash (bildirim ID'leri için — Dart hashCode
/// platformlar arası garanti değildir).
int stableHash(String s) {
  var h = 0x811C9DC5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h & 0x7FFFFFFF;
}

/// Geri sayım metni
String countdownText(DateTime target, {DateTime? end}) {
  final now = DateTime.now();
  if (end != null) {
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    if (now.isAfter(endOfDay)) return 'Tamamlandı';
    if (!now.isBefore(target)) return 'Devam ediyor';
  } else if (!now.isBefore(target)) {
    final endOfDay =
        DateTime(target.year, target.month, target.day, 23, 59, 59);
    if (now.isAfter(endOfDay)) return 'Geçti';
    return 'Bugün';
  }
  final diff = target.difference(now);
  if (diff.inDays >= 1) {
    final h = diff.inHours % 24;
    return h > 0
        ? '${diff.inDays} gün $h saat kaldı'
        : '${diff.inDays} gün kaldı';
  }
  if (diff.inHours >= 1) {
    return '${diff.inHours} saat ${diff.inMinutes % 60} dk kaldı';
  }
  return '${math.max(diff.inMinutes, 1)} dk kaldı';
}

extension IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

/// Türkçe kurallarına göre büyük harf (i → İ, ı → I).
/// Dart'ın toUpperCase() metodu "Valiz" → "VALIZ" üretir; bu düzeltir.
String upperTr(String s) =>
    s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

/// Türkçe kurallarına göre küçük harf (İ → i, I → ı).
String lowerTr(String s) =>
    s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

/// Türkçe büyük/küçük harf duyarsız arama için sadeleştirme
String normalizeTr(String s) => lowerTr(s)
    .replaceAll('ı', 'i')
    .replaceAll('İ', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c');
