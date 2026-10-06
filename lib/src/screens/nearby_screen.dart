import 'package:flutter/material.dart';

import '../models/location_snapshot.dart';
import '../models/place_result.dart';
import '../services/nearby_service.dart';

class NearbyScreen extends StatefulWidget {
  final LocationSnapshot location;
  const NearbyScreen({super.key, required this.location});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  String cat = NearbyService.categories.keys.first;
  List<PlaceResult> results = [];
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
      results = [];
    });
    try {
      final r = await NearbyService()
          .search(cat, widget.location.latitude, widget.location.longitude);
      if (mounted) setState(() => results = r);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby places (3 km)')),
      body: Column(children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final k in NearbyService.categories.keys)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(k),
                    selected: cat == k,
                    onSelected: (_) {
                      cat = k;
                      _load();
                    },
                  ),
                ),
            ],
          ),
        ),
        if (loading) const LinearProgressIndicator(),
        if (error != null) Padding(padding: const EdgeInsets.all(16), child: Text(error!)),
        if (!loading && error == null && results.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Text('Nothing found within 3 km.')),
        Expanded(
          child: ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = results[i];
              return ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(p.name),
                subtitle: Text('${formatDistance(p.distanceM!)} · ${p.address}'),
                onTap: () => Navigator.pop(context, p),
              );
            },
          ),
        ),
      ]),
    );
  }
}
