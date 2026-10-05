import 'dart:async';

import 'package:flutter/material.dart';

import '../models/location_snapshot.dart';
import '../models/place_result.dart';
import '../services/place_search_service.dart';

class PlaceSearchScreen extends StatefulWidget {
  final LocationSnapshot? near;
  const PlaceSearchScreen({super.key, this.near});

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final service = PlaceSearchService();
  Timer? _debounce;
  List<PlaceResult> results = [];
  bool loading = false;
  String? error;

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 3) {
      setState(() => results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 700), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await service.search(q,
          nearLat: widget.near?.latitude, nearLng: widget.near?.longitude);
      if (mounted) setState(() => results = r);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: _search,
          decoration: const InputDecoration(
              hintText: 'School, hospital, mall, address…', prefixIcon: Icon(Icons.search_rounded)),
        ),
      ),
      body: Column(children: [
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          Padding(padding: const EdgeInsets.all(16), child: Text(error!, style: TextStyle(color: Colors.red.shade800))),
        Expanded(
          child: ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = results[i];
              return ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(p.address, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.pop(context, p),
              );
            },
          ),
        ),
      ]),
    );
  }
}
