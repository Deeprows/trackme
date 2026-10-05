import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/history_service.dart';
import '../services/share_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final store = HistoryService();
  List<HistoryEntry> items = [];

  @override
  void initState() {
    super.initState();
    store.load().then((l) => mounted ? setState(() => items = l) : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location history'), actions: [
        IconButton(
          tooltip: 'Delete all',
          icon: const Icon(Icons.delete_sweep_rounded),
          onPressed: () async {
            await store.clear();
            if (mounted) setState(() => items = []);
          },
        ),
      ]),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                    'No history. It is off by default: turn it on in Privacy & settings, then each "Where am I?" is saved on this phone only.',
                    textAlign: TextAlign.center),
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = items[i];
                final t = e.at.toLocal();
                return ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: Text(e.address, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'),
                  onTap: () => launchUrl(Uri.parse(ShareService.mapUrl(e.lat, e.lng)),
                      mode: LaunchMode.externalApplication),
                );
              },
            ),
    );
  }
}
