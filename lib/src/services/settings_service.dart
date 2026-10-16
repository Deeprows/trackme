import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  bool saveHistory = false; // off by default
  int retentionDays = 7;
  bool approximate = false; // live links show ~1 km area only
  bool hideAddress = false; // live links hide the street address
  String language = 'system'; // system | en | ar | es
}

class SettingsService {
  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings()
      ..saveHistory = p.getBool('s_hist') ?? false
      ..retentionDays = p.getInt('s_days') ?? 7
      ..approximate = p.getBool('s_approx') ?? false
      ..hideAddress = p.getBool('s_hideaddr') ?? false
      ..language = p.getString('s_lang') ?? 'system';
  }

  static Future<void> save(AppSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('s_hist', s.saveHistory);
    await p.setInt('s_days', s.retentionDays);
    await p.setBool('s_approx', s.approximate);
    await p.setBool('s_hideaddr', s.hideAddress);
    await p.setString('s_lang', s.language);
  }

  static Future<bool> isOnboarded() async =>
      (await SharedPreferences.getInstance()).getBool('onboarded') ?? false;

  static Future<void> setOnboarded() async =>
      (await SharedPreferences.getInstance()).setBool('onboarded', true);
}
