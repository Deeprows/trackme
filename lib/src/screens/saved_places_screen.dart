import 'package:flutter/material.dart';

import '../models/place_result.dart';
import '../services/location_service.dart';
import '../services/saved_places_service.dart';

/// Pops a [PlaceResult] when a saved place is tapped.
class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final store = SavedPlacesService();
  List<SavedPlace> places = [];
  bool busy = false;

  @override
  void initState() {
    super.initState();
    store.load().then((l) => mounted ? setState(() => places = l) : null);
  }

  IconData _icon(String n) {
    final s = n.toLowerCase();
    if (s.contains('home')) return Icons.home_rounded;
    if (s.contains('school') || s.contains('uni')) return Icons.school_rounded;
    if (s.contains('work') || s.contains('office')) return Icons.work_rounded;
    return Icons.place_rounded;
  }

  Future<void> _saveHere() async {
    setState(() => busy = true);
    try {
      final loc = await LocationService().getCurrentLocation();
      if (!mounted) return;
      final name = TextEditingController();
      var alerts = true;
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (ctx, setD) => AlertDialog(
            title: const Text('Save this spot'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final n in ['Home', 'School', 'Work'])
                  ActionChip(label: Text(n), onPressed: () => setD(() => name.text = n)),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Announce arrive/leave'),
                subtitle: const Text('On live links, viewers see "Arrived at…" / "Left…".'),
                value: alerts,
                onChanged: (v) => setD(() => alerts = v),
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
            ],
          ),
        ),
      );
      if (ok == true && name.text.trim().isNotEmpty) {
        final p = SavedPlace(
            name: name.text.trim(),
            address: loc.address,
            lat: loc.latitude,
            lng: loc.longitude,
            alerts: alerts);
        setState(() => places = [...places, p]);
        await store.save(places);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _toggle(int i, bool v) async {
    setState(() => places = [...places]..[i] = places[i].withAlerts(v));
    await store.save(places);
  }

  Future<void> _remove(int i) async {
    setState(() => places = [...places]..removeAt(i));
    await store.save(places);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved places')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy ? null : _saveHere,
        icon: busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add_location_alt_rounded),
        label: const Text('Save current spot'),
      ),
      body: Column(children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
              'Switch a place on to announce arrivals and departures on your live link while you share. Alerts do not run when you are not sharing.'),
        ),
        Expanded(
          child: places.isEmpty
              ? const Center(child: Text('No saved places yet.'))
              : ListView.builder(
                  itemCount: places.length,
                  itemBuilder: (_, i) {
                    final p = places[i];
                    return ListTile(
                      leading: Icon(_icon(p.name)),
                      title: Text(p.name),
                      subtitle: Text(p.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.pop(
                          context,
                          PlaceResult(
                              name: p.name, address: p.address, latitude: p.lat, longitude: p.lng)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Switch(value: p.alerts, onChanged: (v) => _toggle(i, v)),
                        IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => _remove(i)),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
