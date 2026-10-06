import 'package:flutter/material.dart';

import '../models/location_snapshot.dart';
import '../services/contacts_service.dart';
import '../services/share_service.dart';

/// Family & friends list. Send your location to one person by SMS or WhatsApp.
class ContactsScreen extends StatefulWidget {
  final LocationSnapshot? location;
  const ContactsScreen({super.key, this.location});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final store = ContactsService();
  final share = ShareService();
  List<TrustedContact> contacts = [];

  @override
  void initState() {
    super.initState();
    store.load().then((c) => mounted ? setState(() => contacts = c) : null);
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add family or friend'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 10),
          TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (with country code)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty && phone.text.trim().isNotEmpty) {
      setState(() => contacts = [...contacts, TrustedContact(name.text.trim(), phone.text.trim())]);
      await store.save(contacts);
    }
  }

  Future<void> _remove(int i) async {
    setState(() => contacts = [...contacts]..removeAt(i));
    await store.save(contacts);
  }

  Future<void> _toggle(int i) async {
    final c = contacts[i];
    setState(() => contacts = [...contacts]..[i] = TrustedContact(c.name, c.phone, emergency: !c.emergency));
    await store.save(contacts);
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    final msg = loc == null ? null : ShareService.locationMessage(loc);
    return Scaffold(
      appBar: AppBar(title: const Text('Family & friends  ★ = emergency')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _add, icon: const Icon(Icons.person_add_rounded), label: const Text('Add')),
      body: contacts.isEmpty
          ? const Center(child: Text('No contacts yet. Add people you trust.'))
          : ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (_, i) {
                final c = contacts[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(c.name[0].toUpperCase())),
                  title: Text(c.name),
                  subtitle: Text(c.phone),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        tooltip: 'Emergency contact (used by SOS)',
                        icon: Icon(c.emergency ? Icons.star_rounded : Icons.star_border_rounded,
                            color: c.emergency ? Colors.orange : null),
                        onPressed: () => _toggle(i)),
                    IconButton(tooltip: 'Call', icon: const Icon(Icons.call_rounded), onPressed: () => share.call(c.phone)),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'sms' && msg != null) share.sms([c.phone], msg);
                        if (v == 'wa' && msg != null) share.whatsapp(c.phone, msg);
                        if (v == 'rm') _remove(i);
                      },
                      itemBuilder: (_) => [
                        if (msg != null) const PopupMenuItem(value: 'sms', child: Text('Send location by SMS')),
                        if (msg != null) const PopupMenuItem(value: 'wa', child: Text('Send location by WhatsApp')),
                        const PopupMenuItem(value: 'rm', child: Text('Remove')),
                      ],
                    ),
                  ]),
                );
              },
            ),
    );
  }
}
