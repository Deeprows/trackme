import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings s = AppSettings();

  @override
  void initState() {
    super.initState();
    SettingsService.load().then((v) => mounted ? setState(() => s = v) : null);
  }

  void _update(void Function() change) {
    setState(change);
    SettingsService.save(s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).t('settings'))),
      body: ListView(children: [
        ListTile(
          leading: const Icon(Icons.language_rounded),
          title: Text(S.of(context).t('lang')),
          trailing: DropdownButton<String>(
            value: s.language,
            items: [
              DropdownMenuItem(value: 'system', child: Text(S.of(context).t('sysdef'))),
              const DropdownMenuItem(value: 'en', child: Text('English')),
              const DropdownMenuItem(value: 'ar', child: Text('العربية')),
              const DropdownMenuItem(value: 'es', child: Text('Español')),
            ],
            onChanged: (v) {
              _update(() => s.language = v ?? 'system');
              appLocale.value = s.language == 'system' ? null : Locale(s.language);
            },
          ),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Save location history'),
          subtitle: const Text('Stored on this phone only. Off by default.'),
          value: s.saveHistory,
          onChanged: (v) => _update(() => s.saveHistory = v),
        ),
        ListTile(
          title: const Text('Keep history for'),
          trailing: DropdownButton<int>(
            value: s.retentionDays,
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 day')),
              DropdownMenuItem(value: 7, child: Text('7 days')),
              DropdownMenuItem(value: 30, child: Text('30 days')),
            ],
            onChanged: (v) => _update(() => s.retentionDays = v ?? 7),
          ),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Approximate location in live links'),
          subtitle: const Text('Viewers see an area of about 1 km, not your exact spot.'),
          value: s.approximate,
          onChanged: (v) => _update(() => s.approximate = v),
        ),
        SwitchListTile(
          title: const Text('Hide street address in live links'),
          value: s.hideAddress,
          onChanged: (v) => _update(() => s.hideAddress = v),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_forever_rounded),
          title: const Text('Delete all data on this phone'),
          subtitle: const Text('History, contacts and settings.'),
          onTap: () async {
            await HistoryService().clear();
            await (await SharedPreferences.getInstance()).clear();
            if (!mounted) return;
            appLocale.value = null;
            setState(() => s = AppSettings());
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Deleted')));
          },
        ),
      ]),
    );
  }
}
