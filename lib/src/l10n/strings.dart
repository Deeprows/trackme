import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// null = follow the phone's language.
final ValueNotifier<Locale?> appLocale = ValueNotifier(null);

/// Lightweight translations: English, Arabic (RTL is automatic), Spanish.
/// Add a key to all three maps, then use S.of(context).t('key').
class S {
  final String code;
  const S(this.code);

  static const supported = [Locale('en'), Locale('ar'), Locale('es')];
  static const delegate = _SDelegate();
  static S of(BuildContext c) => Localizations.of<S>(c, S) ?? const S('en');

  String t(String k) => _m[code]?[k] ?? _m['en']![k] ?? k;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();
  @override
  bool isSupported(Locale l) => const ['en', 'ar', 'es'].contains(l.languageCode);
  @override
  Future<S> load(Locale l) => SynchronousFuture(S(l.languageCode));
  @override
  bool shouldReload(_SDelegate old) => false;
}

const _m = <String, Map<String, String>>{
  'en': {
    'tagline': 'Know where you are.\nShare when you choose.',
    'hero_on': 'Private location sharing is enabled.',
    'hero_demo': 'Demo mode — configure Firebase for shared sessions.',
    'where': 'Where am I?',
    'cur': 'Current location',
    'share_exact': 'Share exact location',
    'share_live': 'Share live location (link)',
    'copy': 'Copy address & link',
    'acc': 'Accuracy: about {m} m',
    'find': 'Find a place',
    'nearby': 'Nearby places',
    'trip': 'Share a trip',
    'family': 'Family & friends',
    'checkin': 'Check in',
    'sos': 'SOS',
    'history': 'Location history',
    'saved': 'Saved places',
    'details': 'Details & directions',
    'share': 'Share',
    'settings': 'Privacy & settings',
    'lang': 'Language',
    'sysdef': 'Phone default',
    'live_title': 'Live sharing until {t}',
    'stop': 'Stop',
    'share_link': 'Share link',
    'ob1_t': 'You decide when to share',
    'ob1_b': 'Nothing is shared until you tap a button. Stop any time and the link stops working.',
    'ob2_t': 'Private links that expire',
    'ob2_b': 'Live links use a long random code and end after the time you choose, up to 24 hours. Only people you send the link to can open it.',
    'ob3_t': 'Your data stays on your phone',
    'ob3_b': 'Contacts, saved places and history are stored on this device. History is off by default and deletes itself.',
    'ob4_t': 'Built for safety',
    'ob4_b': 'Star emergency contacts for SOS, send a one-tap check-in, and hide your address or share an approximate area in Privacy settings.',
    'next': 'Next',
    'skip': 'Skip',
    'start': 'Get started',
  },
  'ar': {
    'tagline': 'اعرف أين أنت.\nشارك متى شئت.',
    'hero_on': 'مشاركة الموقع الخاصة مفعّلة.',
    'hero_demo': 'وضع تجريبي — فعّل Firebase للمشاركة.',
    'where': 'أين أنا؟',
    'cur': 'موقعي الحالي',
    'share_exact': 'شارك موقعي بدقة',
    'share_live': 'شارك موقعي مباشرة (رابط)',
    'copy': 'نسخ العنوان والرابط',
    'acc': 'الدقة: حوالي {m} م',
    'find': 'ابحث عن مكان',
    'nearby': 'أماكن قريبة',
    'trip': 'شارك رحلتي',
    'family': 'العائلة والأصدقاء',
    'checkin': 'تسجيل سلامة',
    'sos': 'طوارئ',
    'history': 'سجل المواقع',
    'saved': 'أماكن محفوظة',
    'details': 'التفاصيل والاتجاهات',
    'share': 'مشاركة',
    'settings': 'الخصوصية والإعدادات',
    'lang': 'اللغة',
    'sysdef': 'لغة الهاتف',
    'live_title': 'مشاركة مباشرة حتى {t}',
    'stop': 'إيقاف',
    'share_link': 'مشاركة الرابط',
    'ob1_t': 'أنت تقرر متى تشارك',
    'ob1_b': 'لا يُشارَك شيء حتى تضغط على الزر. أوقف المشاركة في أي وقت ويتوقف الرابط عن العمل.',
    'ob2_t': 'روابط خاصة تنتهي تلقائيًا',
    'ob2_b': 'تستخدم الروابط المباشرة رمزًا عشوائيًا طويلًا وتنتهي بعد المدة التي تختارها، بحد أقصى 24 ساعة. لا يفتحها إلا من ترسل لهم الرابط.',
    'ob3_t': 'بياناتك تبقى على هاتفك',
    'ob3_b': 'جهات الاتصال والأماكن المحفوظة والسجل مخزنة على هذا الجهاز. السجل متوقف افتراضيًا ويحذف نفسه تلقائيًا.',
    'ob4_t': 'مصمم للسلامة',
    'ob4_b': 'ضع نجمة على جهات اتصال الطوارئ لاستخدامها في الاستغاثة، وأرسل رسالة اطمئنان بضغطة واحدة، وأخفِ عنوانك أو شارك منطقة تقريبية من إعدادات الخصوصية.',
    'next': 'التالي',
    'skip': 'تخطي',
    'start': 'ابدأ',
  },
  'es': {
    'tagline': 'Sabe dónde estás.\nComparte cuando quieras.',
    'hero_on': 'El uso compartido privado de ubicación está activado.',
    'hero_demo': 'Modo demo: configura Firebase para compartir.',
    'where': '¿Dónde estoy?',
    'cur': 'Ubicación actual',
    'share_exact': 'Compartir ubicación exacta',
    'share_live': 'Compartir ubicación en vivo (enlace)',
    'copy': 'Copiar dirección y enlace',
    'acc': 'Precisión: unos {m} m',
    'find': 'Buscar un lugar',
    'nearby': 'Lugares cercanos',
    'trip': 'Compartir un viaje',
    'family': 'Familia y amigos',
    'checkin': 'Estoy bien',
    'sos': 'SOS',
    'history': 'Historial',
    'saved': 'Lugares guardados',
    'details': 'Detalles e indicaciones',
    'share': 'Compartir',
    'settings': 'Privacidad y ajustes',
    'lang': 'Idioma',
    'sysdef': 'Idioma del teléfono',
    'live_title': 'Compartiendo en vivo hasta {t}',
    'stop': 'Detener',
    'share_link': 'Compartir enlace',
    'ob1_t': 'Tú decides cuándo compartir',
    'ob1_b': 'No se comparte nada hasta que toques un botón. Detén el envío cuando quieras y el enlace deja de funcionar.',
    'ob2_t': 'Enlaces privados que caducan',
    'ob2_b': 'Los enlaces en vivo usan un código aleatorio largo y terminan tras el tiempo que elijas, hasta 24 horas. Solo pueden abrirlos quienes reciban el enlace.',
    'ob3_t': 'Tus datos se quedan en tu teléfono',
    'ob3_b': 'Los contactos, lugares guardados y el historial se guardan en este dispositivo. El historial está desactivado por defecto y se borra solo.',
    'ob4_t': 'Pensada para tu seguridad',
    'ob4_b': 'Marca contactos de emergencia con una estrella para SOS, envía un aviso con un toque y oculta tu dirección o comparte una zona aproximada en Privacidad.',
    'next': 'Siguiente',
    'skip': 'Omitir',
    'start': 'Empezar',
  },
};
