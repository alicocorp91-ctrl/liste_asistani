import 'package:flutter/material.dart';
import '../data/storage.dart';

enum AppAccent {
  blue('Mavi', Color(0xFF1E88E5)),
  teal('Turkuaz', Color(0xFF00897B)),
  green('Yeşil', Color(0xFF43A047)),
  purple('Mor', Color(0xFF7E57C2)),
  orange('Turuncu', Color(0xFFFB8C00)),
  pink('Pembe', Color(0xFFD81B60)),
  indigo('Çivit', Color(0xFF3949AB)),
  brown('Kahve', Color(0xFF6D4C41));

  const AppAccent(this.label, this.seed);
  final String label;
  final Color seed;
}

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage) {
    _accent = AppAccent.values[(_storage.getInt(Storage.keyTheme) ?? 0)
        .clamp(0, AppAccent.values.length - 1)];
    _mode = ThemeMode.values[
        (_storage.getInt(Storage.keyBrightness) ?? ThemeMode.system.index)
            .clamp(0, ThemeMode.values.length - 1)];
  }

  final Storage _storage;
  late AppAccent _accent;
  late ThemeMode _mode;

  AppAccent get accent => _accent;
  ThemeMode get themeMode => _mode;

  Future<void> setAccent(AppAccent a) async {
    _accent = a;
    notifyListeners();
    await _storage.setInt(Storage.keyTheme, a.index);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    await _storage.setInt(Storage.keyBrightness, m.index);
  }

  ThemeData theme(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: _accent.seed, brightness: b);
    final base =
        ThemeData(colorScheme: scheme, useMaterial3: true, brightness: b);
    return base.copyWith(
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: scheme.surfaceContainerLow,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      listTileTheme: const ListTileThemeData(dense: true),
    );
  }
}
