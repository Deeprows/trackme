import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter/services.dart';

import '../models/location_snapshot.dart';
import '../models/place_result.dart';
import '../l10n/strings.dart';
import '../services/contacts_service.dart';
import '../services/live_share_service.dart';
import 'contacts_screen.dart';
import '../services/history_service.dart';
import '../services/saved_places_service.dart';
import '../services/settings_service.dart';
import 'saved_places_screen.dart';
import 'history_screen.dart';
import 'nearby_screen.dart';
import 'place_details_screen.dart';
import 'place_search_screen.dart';
import 'settings_screen.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/share_service.dart';

class HomeScreen extends StatefulWidget {
  final bool useFirebase;

  const HomeScreen({super.key, required this.useFirebase});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final locationService = LocationService();
  final shareService = ShareService();
  final liveService = LiveShareService();

  LocationSnapshot? currentLocation;
  PlaceResult? selectedPlace;
  AppSettings settings = AppSettings();
  List<SavedPlace> saved = [];
  GoogleMapController? mapController;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    SettingsService.load().then((v) => mounted ? setState(() => settings = v) : null);
    SavedPlacesService().load().then((v) => mounted ? setState(() => saved = v) : null);
  }

  @override
  void dispose() {
    liveService.stop();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _until() => TimeOfDay.fromDateTime(liveService.expiresAt!.toLocal()).format(context);

  Future<void> startLive({PlaceResult? destination}) async {
    if (!widget.useFirebase) {
      _snack('Live sharing needs Firebase: run with --dart-define=USE_FIREBASE=true');
      return;
    }
    if (LiveShareService.baseUrl.isEmpty) {
      _snack('Set --dart-define=SHARE_BASE_URL=https://YOUR-PROJECT.web.app');
      return;
    }
    if (currentLocation == null) await locateMe();
    final loc = currentLocation;
    if (loc == null || !mounted) return;
    final d = await showModalBottomSheet<Duration>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(title: Text('Share live location for…', style: TextStyle(fontWeight: FontWeight.w800))),
          for (final o in const [
            ('15 minutes', Duration(minutes: 15)),
            ('1 hour', Duration(hours: 1)),
            ('8 hours', Duration(hours: 8)),
          ])
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(o.$1),
              onTap: () => Navigator.pop(context, o.$2),
            ),
        ]),
      ),
    );
    if (d == null) return;
    try {
      await liveService.start(loc, d,
          destination: destination,
          watch: saved.where((s) => s.alerts).toList(),
          onEvent: (t) {
            if (mounted) _snack('Alert sent: $t');
          },
          approximate: settings.approximate,
          hideAddress: settings.hideAddress,
          onArrived: () {
            if (mounted) _snack("You've arrived. The link closes in 2 minutes.");
          },
          onEnded: () {
        if (mounted) setState(() {});
      });
      if (!mounted) return;
      setState(() {});
      await shareService.shareLiveLink(liveService.link, _until());
    } catch (e) {
      if (mounted) _snack('Could not start live sharing: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> stopLive() async {
    await liveService.stop();
    if (mounted) setState(() {});
  }

  Widget _liveCard() {
    return Card(
      elevation: 0,
      color: Colors.green.shade50,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.sensors_rounded, color: Colors.green.shade800),
            const SizedBox(width: 8),
            Text(S.of(context).t('live_title').replaceAll('{t}', _until()),
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.green.shade900)),
          ]),
          const SizedBox(height: 4),
          const Text('Sharing continues if you leave the app. Anyone with the link can see where you are.'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: FilledButton.icon(
                    onPressed: () => shareService.shareLiveLink(liveService.link, _until()),
                    icon: const Icon(Icons.link_rounded),
                    label: Text(S.of(context).t('share_link')))),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: stopLive, child: Text(S.of(context).t('stop'))),
          ]),
        ]),
      ),
    );
  }

  Future<void> locateMe() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final location = await locationService.getCurrentLocation();
      if (!mounted) return;

      setState(() => currentLocation = location);
      if (settings.saveHistory) {
        HistoryService().add(location, settings.retentionDays);
      }

      await mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location.latitude, location.longitude),
          16,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> share() async {
    final location = currentLocation;
    if (location == null) {
      await locateMe();
      if (!mounted) return;
    }

    final value = currentLocation;
    if (value != null) {
      await shareService.shareLocation(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = currentLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WhereWeAre',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Privacy & settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.shield_outlined),
          ),
          IconButton(
            tooltip: 'Saved places',
            onPressed: _openSaved,
            icon: const Icon(Icons.bookmarks_outlined),
          ),
          IconButton(
            tooltip: 'Search places',
            onPressed: () => _showPlaceSearch(context),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: locateMe,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _heroCard(),
              const SizedBox(height: 14),
              SizedBox(
                height: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(30.0444, 31.2357),
                      zoom: 10,
                    ),
                    myLocationEnabled: location != null,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    onMapCreated: (controller) => mapController = controller,
                    markers: {
                      if (selectedPlace != null)
                        Marker(
                          markerId: const MarkerId('place'),
                          position: LatLng(selectedPlace!.latitude, selectedPlace!.longitude),
                          infoWindow: InfoWindow(title: selectedPlace!.name),
                        ),
                      if (location != null)
                            Marker(
                              markerId: const MarkerId('me'),
                              position: LatLng(
                                location.latitude,
                                location.longitude,
                              ),
                              infoWindow: InfoWindow(
                                title: 'My location',
                                snippet: location.address,
                              ),
                            ),
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (liveService.active) _liveCard(),
              if (selectedPlace != null) _placeCard(selectedPlace!),
              if (location != null) _locationCard(location),
              if (error != null) ...[
                const SizedBox(height: 12),
                _errorCard(error!),
              ],
              const SizedBox(height: 14),
              _featureGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_rounded, color: Colors.white, size: 38),
          const SizedBox(height: 12),
          Text(
            S.of(context).t('tagline'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.useFirebase
                ? S.of(context).t('hero_on')
                : S.of(context).t('hero_demo'),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1D4ED8),
                  ),
                  onPressed: loading ? null : locateMe,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: Text(S.of(context).t('where')),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
                onPressed: share,
                icon: const Icon(Icons.share_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _locationCard(LocationSnapshot location) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place_rounded),
                SizedBox(width: 8),
                Text(
                  S.of(context).t('cur'),
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              location.address,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              S.of(context).t('acc').replaceAll('{m}', location.accuracy.toStringAsFixed(0)),
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: share,
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(S.of(context).t('share_exact')),
              ),
            ),
            const SizedBox(height: 8),
            if (!liveService.active)
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: startLive,
                  icon: const Icon(Icons.sensors_rounded),
                  label: Text(S.of(context).t('share_live')),
                ),
              ),
            if (!liveService.active) const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text: ShareService.locationMessage(location)));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location copied')));
                },
                icon: const Icon(Icons.copy_rounded),
                label: Text(S.of(context).t('copy')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorCard(String message) {
    return Card(
      elevation: 0,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message.replaceFirst('Exception: ', ''),
          style: TextStyle(color: Colors.red.shade900),
        ),
      ),
    );
  }

  Widget _featureGrid(BuildContext context) {
    final List<(IconData, String, VoidCallback)> items = [
      (Icons.search_rounded, S.of(context).t('find'), () => _showPlaceSearch(context)),
      (Icons.local_hospital_rounded, S.of(context).t('nearby'), _openNearby),
      (Icons.route_rounded, S.of(context).t('trip'), _startTrip),
      (Icons.groups_rounded, S.of(context).t('family'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactsScreen(location: currentLocation)))),
      (Icons.check_circle_outline_rounded, S.of(context).t('checkin'), _checkIn),
      (Icons.emergency_rounded, S.of(context).t('sos'), () => _showSos(context)),
      (Icons.history_rounded, S.of(context).t('history'), _openHistory),
      (Icons.bookmarks_rounded, S.of(context).t('saved'), _openSaved),
    ];


    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (_, index) {
        final item = items[index];
        return Card(
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: item.$3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.$1, size: 30),
                  const SizedBox(height: 10),
                  Text(
                    item.$2,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPlaceSearch(BuildContext context) async {
    final place = await Navigator.push<PlaceResult>(context,
        MaterialPageRoute(builder: (_) => PlaceSearchScreen(near: currentLocation)));
    if (place == null || !mounted) return;
    setState(() => selectedPlace = place);
    await mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(place.latitude, place.longitude), 16));
  }

  Future<void> _selectPlace(PlaceResult place) async {
    setState(() => selectedPlace = place);
    await mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(place.latitude, place.longitude), 16));
  }

  Future<void> _openDetails(PlaceResult p) async {
    final r = await Navigator.push<String>(context,
        MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: p, from: currentLocation)));
    if (r == 'trip' && mounted) await startLive(destination: p);
  }

  Future<void> _startTrip() async {
    final place = await Navigator.push<PlaceResult>(context,
        MaterialPageRoute(builder: (_) => PlaceSearchScreen(near: currentLocation)));
    if (place == null || !mounted) return;
    await _selectPlace(place);
    await startLive(destination: place);
  }

  Future<void> _openNearby() async {
    if (currentLocation == null) await locateMe();
    final loc = currentLocation;
    if (loc == null || !mounted) return;
    final place = await Navigator.push<PlaceResult>(
        context, MaterialPageRoute(builder: (_) => NearbyScreen(location: loc)));
    if (place != null && mounted) await _selectPlace(place);
  }

  Future<void> _checkIn() async {
    final msg = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(
              title: Text('Send a check-in', style: TextStyle(fontWeight: FontWeight.w800))),
          for (final o in const [
            (Icons.check_circle_rounded, "I'm safe"),
            (Icons.flag_rounded, "I've arrived"),
            (Icons.schedule_rounded, 'Running late'),
          ])
            ListTile(
              leading: Icon(o.$1),
              title: Text(o.$2),
              onTap: () => Navigator.pop(context, o.$2),
            ),
        ]),
      ),
    );
    if (msg == null || !mounted) return;
    final contacts = await ContactsService().load();
    if (!mounted) return;
    if (contacts.isEmpty) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ContactsScreen(location: currentLocation)));
      return;
    }
    if (currentLocation == null) await locateMe();
    final loc = currentLocation;
    if (loc == null) return;
    final targets = contacts.where((c) => c.emergency).toList();
    final live = liveService.active ? '\n\nFollow me live:\n${liveService.link}' : '';
    await shareService.sms(
      (targets.isEmpty ? contacts : targets).map((c) => c.phone).toList(),
      '$msg\n\n${ShareService.locationMessage(loc, title: 'My location:')}$live',
    );
  }

  Future<void> _openSaved() async {
    final place = await Navigator.push<PlaceResult>(
        context, MaterialPageRoute(builder: (_) => const SavedPlacesScreen()));
    final l = await SavedPlacesService().load();
    if (mounted) setState(() => saved = l);
    if (place != null && mounted) await _selectPlace(place);
  }

  void _openHistory() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));

  Future<void> _openSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    final v = await SettingsService.load();
    if (mounted) setState(() => settings = v);
  }

  Widget _placeCard(PlaceResult p) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.flag_rounded),
            const SizedBox(width: 8),
            Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800))),
            IconButton(
                onPressed: () => setState(() => selectedPlace = null),
                icon: const Icon(Icons.close_rounded)),
          ]),
          Text(p.address),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: FilledButton.icon(
                    onPressed: () => shareService.sharePlace(p),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: Text(S.of(context).t('share')))),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _openDetails(p),
                    icon: const Icon(Icons.directions_rounded),
                    label: Text(S.of(context).t('details')))),
          ]),
        ]),
      ),
    );
  }

  Future<void> _showSos(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send SOS?'),
        content: const Text(
            'This opens your SMS app with your exact location, addressed to your emergency contacts (starred), or everyone in Family & friends if none are starred. You press send.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Prepare SOS')),
        ],
      ),
    );
    if (ok != true) return;
    final contacts = await ContactsService().load();
    if (!mounted) return;
    if (contacts.isEmpty) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ContactsScreen(location: currentLocation)));
      return;
    }
    if (currentLocation == null) await locateMe();
    final loc = currentLocation;
    if (loc == null) return;
    final targets = contacts.where((c) => c.emergency).toList();
    await shareService.sms((targets.isEmpty ? contacts : targets).map((c) => c.phone).toList(),
        ShareService.locationMessage(loc, title: 'SOS - I need help. My location:'));
  }
}
