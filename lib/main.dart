import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/helper/material_color_creator.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/ui/rootPage.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static Future<void> setLocale(BuildContext context, Locale newLocale) async {
    final state = context.findAncestorStateOfType<_MyAppState>()!;
    state.changeLanguage(newLocale);
  }

  static Future<void> setAccentColor(
    BuildContext context,
    Color newAccentColor,
  ) async {
    final state = context.findAncestorStateOfType<_MyAppState>()!;
    state.changeAccentColor(newAccentColor);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', '');

  void changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void changeAccentColor(Color newAccentColor) {
    setState(() {
      accent = newAccentColor;
    });
  }

  @override
  void initState() {
    super.initState();
    final codes = <String, String>{
      'English': 'en',
      'Georgian': 'ka',
      'Chinese': 'zh',
      'Dutch': 'nl',
      'German': 'de',
      'Indonesian': 'id',
      'Italian': 'it',
      'Polish': 'pl',
      'Portuguese': 'pt',
      'Spanish': 'es',
      'Turkish': 'tr',
      'Ukrainian': 'uk',
    };
    _locale = Locale(
      codes[Hive.box('settings').get('language', defaultValue: 'English')
          as String]!,
    );
  }

  @override
  void dispose() {
    Hive.close();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        scaffoldBackgroundColor: bgColor,
        canvasColor: bgColor,
        appBarTheme: AppBarTheme(backgroundColor: bgColor),
        colorScheme:
            ColorScheme.fromSwatch(primarySwatch: createMaterialColor(accent)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Ubuntu',
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
        colorScheme:
            ColorScheme.fromSwatch(primarySwatch: createMaterialColor(accent)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Ubuntu',
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ka', ''),
        Locale('zh', ''),
        Locale('nl', ''),
        Locale('fr', ''),
        Locale('de', ''),
        Locale('he', ''),
        Locale('hi', ''),
        Locale('hu', ''),
        Locale('id', ''),
        Locale('it', ''),
        Locale('pl', ''),
        Locale('pt', ''),
        Locale('es', ''),
        Locale('ta', ''),
        Locale('tr', ''),
        Locale('uk', ''),
        Locale('ur', '')
      ],
      locale: _locale,
      home: Musify(),
    );
  }
}

late String version;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('user');
  await Hive.openBox('cache');
  final packageInfo = await PackageInfo.fromPlatform();
  version = packageInfo.version;
  runApp(const MyApp());
}
