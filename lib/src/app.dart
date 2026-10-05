import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/strings.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/settings_service.dart';

class WhereWeAreApp extends StatefulWidget {
  final bool useFirebase;

  const WhereWeAreApp({super.key, required this.useFirebase});

  @override
  State<WhereWeAreApp> createState() => _WhereWeAreAppState();
}

class _WhereWeAreAppState extends State<WhereWeAreApp> {
  bool? onboarded; // null = still loading (splash)

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final s = await SettingsService.load();
    appLocale.value = s.language == 'system' ? null : Locale(s.language);
    final seen = await SettingsService.isOnboarded();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => onboarded = seen);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocale,
      builder: (_, locale, __) => MaterialApp(
        title: 'WhereWeAre',
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: S.supported,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF2563EB),
          scaffoldBackgroundColor: const Color(0xFFF7F8FA),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        home: onboarded == null
            ? const SplashScreen()
            : onboarded!
                ? HomeScreen(useFirebase: widget.useFirebase)
                : OnboardingScreen(onDone: () => setState(() => onboarded = true)),
      ),
    );
  }
}
