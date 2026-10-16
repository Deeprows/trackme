import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/location_snapshot.dart';
import '../models/place_result.dart';

class ShareService {
  static String mapUrl(double lat, double lng) =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

  static String locationMessage(LocationSnapshot l, {String title = 'My current location'}) =>
      '$title\n\n${l.address}\n\nCoordinates:\n${l.latitude}, ${l.longitude}\n\n'
      'Accuracy: about ${l.accuracy.toStringAsFixed(0)} m\n\nOpen map:\n${mapUrl(l.latitude, l.longitude)}';

  Future<void> shareLocation(LocationSnapshot l) => SharePlus.instance.share(
      ShareParams(text: locationMessage(l), subject: 'My current location'));

  Future<void> sharePlace(PlaceResult p) => SharePlus.instance.share(ShareParams(
      text: '${p.name}\n${p.address}\n\nOpen map:\n${mapUrl(p.latitude, p.longitude)}',
      subject: p.name));

  Future<void> call(String phone) => launchUrl(Uri.parse('tel:$phone'));

  Future<void> openDirections(double lat, double lng, {String mode = 'driving'}) => launchUrl(
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=$mode'),
      mode: LaunchMode.externalApplication);

  Future<void> sms(List<String> phones, String body) => launchUrl(
      Uri.parse('sms:${phones.join(',')}?body=${Uri.encodeComponent(body)}'));

  Future<void> whatsapp(String phone, String body) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return launchUrl(
        Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(body)}'),
        mode: LaunchMode.externalApplication);
  }

  Future<void> shareLiveLink(String url, String until) =>
      SharePlus.instance.share(ShareParams(
          text: 'Follow my live location until $until:\n$url',
          subject: 'My live location'));
}
