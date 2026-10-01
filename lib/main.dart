import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'data/storage.dart';
import 'data/template_repository.dart';
import 'providers/catalog_provider.dart';
import 'providers/lists_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/list_detail_screen.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter hatası: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform hatası: $error\n$stack');
    return true;
  };
  if (kReleaseMode) {
    // Release'de kırmızı hata ekranı yerine sade bir mesaj göster.
    ErrorWidget.builder = (details) => const Material(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child:
                  Text('Bir şeyler yanlış gitti.', textAlign: TextAlign.center),
            ),
          ),
        );
  }

  // Telefon/tablette dikey kilit; masaüstünde anlamsız olduğu için atlanır.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }
  try {
    await initializeDateFormatting('tr_TR');
  } catch (e) {
    debugPrint('Tarih formatı başlatılamadı: $e');
  }

  final storage = await Storage.open();
  final notifications = NotificationService.instance;
  await notifications.init();

  final settings = SettingsProvider(storage);
  final catalog = CatalogProvider(storage, TemplateRepository());
  final lists = ListsProvider(storage, notifications);

  // Bildirime tıklanınca ilgili listeyi aç
  notifications.onTap = (payload) => _openList(payload);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: catalog),
      ChangeNotifierProvider.value(value: lists),
    ],
    child: const ListeAsistaniApp(),
  ));

  // Ağır işleri ilk kare çizildikten sonra başlat
  await Future.wait([catalog.init(), lists.init()]);
  await lists.rescheduleEverything();
  final launchPayload = await notifications.launchPayload();
  if (launchPayload != null) _openList(launchPayload);
}

void _openList(String listId) {
  final nav = navigatorKey.currentState;
  if (nav == null) return;
  nav.push(MaterialPageRoute(builder: (_) => ListDetailScreen(listId: listId)));
}

class ListeAsistaniApp extends StatelessWidget {
  const ListeAsistaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'Liste Asistanı',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: settings.theme(Brightness.light),
      darkTheme: settings.theme(Brightness.dark),
      themeMode: settings.themeMode,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Masaüstünde geniş pencerede telefon düzeni ortalanmış, okunabilir
      // genişlikte gösterilir (Windows/Linux/macOS).
      builder: (context, child) {
        final w = MediaQuery.sizeOf(context).width;
        final isDesktop = !kIsWeb &&
            (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
        if (!isDesktop || w <= 900 || child == null) {
          return child ?? const SizedBox.shrink();
        }
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: child,
            ),
          ),
        );
      },
      home: const HomeScreen(),
    );
  }
}
