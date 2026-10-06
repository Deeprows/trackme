import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TrustedContact {
  final String name;
  final String phone;
  final bool emergency;
  const TrustedContact(this.name, this.phone, {this.emergency = false});

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone, 'emergency': emergency};
  factory TrustedContact.fromJson(Map<String, dynamic> j) => TrustedContact(
      j['name'] as String, j['phone'] as String,
      emergency: j['emergency'] == true);
}

/// Family/friends list stored on the device only.
class ContactsService {
  static const _key = 'trusted_contacts';

  Future<List<TrustedContact>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => TrustedContact.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<TrustedContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(contacts.map((c) => c.toJson()).toList()));
  }
}
