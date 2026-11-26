import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';

/// Lightweight English/Arabic localisation.
///
/// Screens keep their English strings. [Text] below is a drop-in replacement
/// for Flutter's Text that looks the string up in [_ar] when the app language
/// is Arabic, so every label, dialog and message is translated in one place.
/// Dynamic messages (numbers inside sentences) are handled by [_rules].
bool isArabicContext(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

String tr(BuildContext context, String s) =>
    isArabicContext(context) ? translateToArabic(s) : s;

extension TrString on String {
  String tr(BuildContext context) =>
      isArabicContext(context) ? translateToArabic(this) : this;
}

/// Drop-in Text that translates its string for Arabic.
class Text extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  const Text(this.data,
      {super.key,
      this.style,
      this.textAlign,
      this.maxLines,
      this.overflow,
      this.softWrap});

  @override
  Widget build(BuildContext context) {
    return m.Text(
      tr(context, data),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}

String _ago(String n, String unit) {
  switch (unit) {
    case 's':
      return 'منذ $n ثانية';
    case 'm':
      return 'منذ $n دقيقة';
    default:
      return 'منذ $n ساعة';
  }
}

String _lvl(String s) => _ar[s] ?? s;

final List<(RegExp, String Function(Match))> _rules = [
  (RegExp(r'^(\d+)(s|m|h) ago$'), (x) => _ago(x[1]!, x[2]!)),
  (
    RegExp(r'^Temperature ([\d.\-]+)°C above (\d+)°C threshold$'),
    (x) => 'الحرارة ${x[1]}°م أعلى من الحد ${x[2]}°م'
  ),
  (
    RegExp(r'^Smoke reading (\d+) above (\d+) threshold$'),
    (x) => 'قراءة الدخان ${x[1]} أعلى من الحد ${x[2]}'
  ),
  (
    RegExp(r'^Gas reading (\d+) above (\d+) threshold$'),
    (x) => 'قراءة الغاز ${x[1]} أعلى من الحد ${x[2]}'
  ),
  (
    RegExp(r'^Risk level changed to (\w+) \((\d+)%\)\. ?(.*)$'),
    (x) =>
        'تغير مستوى الخطر إلى ${_lvl(x[1]!)} (${x[2]}%). ${translateToArabic(x[3]!.trim())}'
  ),
  (RegExp(r'^Risk level: (\w+)$'), (x) => 'مستوى الخطر: ${_lvl(x[1]!)}'),
  (
    RegExp(r'^Failed to connect to (.+)\.$'),
    (x) => 'فشل الاتصال بالجهاز ${x[1]}.'
  ),
  (
    RegExp(r'^Ignored invalid sensor data: (.*)$'),
    (x) => 'تم تجاهل بيانات حساس غير صالحة: ${x[1]}'
  ),
  (RegExp(r'^Bluetooth error: (.*)$'), (x) => 'خطأ في البلوتوث: ${x[1]}'),
  (
    RegExp(r'^Linked to (.*?)( - last data (.*))?$'),
    (x) =>
        'متصل بـ ${x[1]}${x[3] != null ? ' - آخر بيانات ${translateToArabic(x[3]!)}' : ''}'
  ),
  (
    RegExp(
        r'^Opens the phone dialer with (\S+)\. The call is never started automatically\.$'),
    (x) => 'يفتح الاتصال بالرقم ${x[1]}. لا تبدأ المكالمة تلقائيًا أبدًا.'
  ),
  (RegExp(r'^OPEN DIALER \((.*)\)$'), (x) => 'فتح الاتصال (${x[1]})'),
  (RegExp(r'^(\w+) · DEMO$'), (x) => '${_lvl(x[1]!)} · تجريبي'),
  (
    RegExp(r'^Delete the reading from (.*)\? This cannot be undone\.$'),
    (x) => 'حذف القراءة المسجلة في ${x[1]}؟ لا يمكن التراجع.'
  ),
  (
    RegExp(r'^Sensor comparison - latest reading \((.*)\)$'),
    (x) => 'مقارنة الحساسات - آخر قراءة (${x[1]})'
  ),
  (
    RegExp(r'^(.*)°C · smoke (.*) · gas (.*) · flame (YES|no)$'),
    (x) =>
        '${x[1]}°م · دخان ${x[2]} · غاز ${x[3]} · لهب ${x[4] == 'YES' ? 'نعم' : 'لا'}'
  ),
];

String translateToArabic(String s) {
  final direct = _ar[s];
  if (direct != null) return direct;
  for (final r in _rules) {
    final match = r.$1.firstMatch(s);
    if (match != null) return r.$2(match);
  }
  // Long texts are matched by their first 40 characters.
  if (s.length > 40) {
    final head = s.substring(0, 40);
    for (final e in _ar.entries) {
      if (e.key.length > 40 && e.key.startsWith(head)) return e.value;
    }
  }
  return s;
}

const Map<String, String> _ar = {
  // Navigation / titles
  'Home': 'الرئيسية',
  'Analytics': 'التحليلات',
  'History': 'السجل',
  'Settings': 'الإعدادات',
  'ANALYTICS': 'التحليلات',
  'HISTORY': 'السجل',
  'SETTINGS': 'الإعدادات',
  'EMERGENCY': 'الطوارئ',
  'SMART GUARDIAN AI': 'الحارس الذكي',
  'Intelligent Fire Risk Monitoring': 'مراقبة ذكية لخطر الحريق',
  // Risk levels
  'SAFE': 'آمن',
  'MEDIUM': 'متوسط',
  'HIGH': 'مرتفع',
  'CRITICAL': 'حرج',
  'WARNING': 'تحذير',
  'FLAME': 'لهب',
  'CONNECTION': 'اتصال',
  'RISK_LEVEL': 'مستوى الخطر',
  'NORMAL': 'طبيعي',
  'NO DATA': 'لا توجد بيانات',
  'MONITORING': 'قيد المراقبة',
  'DETECTED': 'تم الكشف',
  'CLEAR': 'سليم',
  'YES': 'نعم',
  'NO': 'لا',
  // Dashboard
  'SENSOR MONITORING': 'مراقبة الحساسات',
  'DEVICE CONNECTION': 'اتصال الجهاز',
  'EMERGENCY ASSISTANCE': 'مساعدة الطوارئ',
  'SYSTEM ONLINE': 'النظام يعمل',
  'SYSTEM IDLE': 'النظام خامل',
  'BT LINKED': 'البلوتوث متصل',
  'BT OFF': 'البلوتوث مفصول',
  'No sensor data yet': 'لا توجد بيانات من الحساسات بعد',
  'Connect a FireGuard_ESP32 device or enable Demo Mode in Settings to see the risk engine in action.':
      'وصّل جهاز FireGuard_ESP32 أو فعّل الوضع التجريبي من الإعدادات لمشاهدة محرك الخطر وهو يعمل.',
  'FLAME DETECTED - ACT NOW': 'تم رصد لهب - تصرف الآن',
  'EMERGENCY CONDITION ACTIVE': 'حالة طوارئ نشطة',
  'No active emergency': 'لا توجد حالة طوارئ',
  'Alert log': 'سجل التنبيهات',
  'RISK SCORE': 'درجة الخطر',
  'Temperature': 'درجة الحرارة',
  'Humidity': 'الرطوبة',
  'Smoke': 'الدخان',
  'Flame': 'اللهب',
  'Gas': 'الغاز',
  'Electricity': 'الكهرباء',
  'Temp': 'الحرارة',
  'DEMO MODE - readings on screen are simulated, not from hardware.':
      'الوضع التجريبي - القراءات المعروضة محاكاة وليست من الجهاز.',
  'DEMO': 'تجريبي',
  'REAL': 'حقيقي',
  // Connection panel
  'CONNECTED': 'متصل',
  'CONNECTING': 'جارٍ الاتصال',
  'DISCONNECTED': 'غير متصل',
  'ESP32 Connection': 'اتصال ESP32',
  'Loading paired devices...': 'جارٍ تحميل الأجهزة المقترنة...',
  'No paired devices - pair FireGuard_ESP32 first':
      'لا توجد أجهزة مقترنة - اقرن FireGuard_ESP32 أولًا من إعدادات بلوتوث الهاتف',
  'Select ESP32': 'اختر جهاز ESP32',
  'Refresh devices': 'تحديث الأجهزة',
  'Disconnect': 'قطع الاتصال',
  'Connect': 'اتصال',
  // Analytics
  'Today': 'اليوم',
  '7 Days': '7 أيام',
  '30 Days': '30 يومًا',
  'Temperature over time': 'الحرارة عبر الوقت',
  'Smoke readings over time': 'قراءات الدخان عبر الوقت',
  'Risk score over time': 'درجة الخطر عبر الوقت',
  'Total Readings': 'إجمالي القراءات',
  'Total Alerts': 'إجمالي التنبيهات',
  'Average Risk': 'متوسط الخطر',
  'Highest Risk': 'أعلى خطر',
  'No data for this sensor in range':
      'لا توجد بيانات لهذا الحساس في هذه الفترة',
  'No readings in this range yet': 'لا توجد قراءات في هذه الفترة بعد',
  'Charts appear here once the app records sensor readings. Enable Demo Mode to generate sample data.':
      'تظهر الرسوم هنا عندما يسجل التطبيق قراءات الحساسات. فعّل الوضع التجريبي لإنشاء بيانات تجريبية.',
  // History
  'Readings': 'القراءات',
  'Search by level or source...': 'ابحث بالمستوى أو المصدر...',
  'All': 'الكل',
  'Newest': 'الأحدث',
  'Oldest': 'الأقدم',
  'Export CSV': 'تصدير CSV',
  'No alerts yet': 'لا توجد تنبيهات بعد',
  'Risk-level changes and flame events are logged here with timestamps.':
      'تُسجَّل هنا تغيّرات مستوى الخطر وحالات اللهب مع الوقت.',
  'No records yet': 'لا توجد سجلات بعد',
  'Readings are stored locally as they arrive and stay available after restarting the app.':
      'تُخزَّن القراءات على الجهاز فور وصولها وتبقى متاحة بعد إعادة تشغيل التطبيق.',
  'Delete record?': 'حذف السجل؟',
  'Cancel': 'إلغاء',
  'Delete': 'حذف',
  'Date': 'التاريخ',
  'Time': 'الوقت',
  'Detected': 'تم الكشف',
  'Not detected': 'لم يتم الكشف',
  'Risk score': 'درجة الخطر',
  'Risk level': 'مستوى الخطر',
  'Source': 'المصدر',
  'Simulated (Demo Mode)': 'محاكاة (الوضع التجريبي)',
  'Real hardware': 'جهاز حقيقي',
  // Flame / risk engine explanations
  'Flame detected by sensor': 'تم رصد لهب بواسطة الحساس',
  'All monitored values are within configured thresholds.':
      'كل القيم المراقبة ضمن الحدود المضبوطة.',
  'Flame detected by sensor. Immediate attention required.':
      'تم رصد لهب بواسطة الحساس. يلزم تدخل فوري.',
  'FLAME DETECTED': 'تم رصد لهب',
  'Flame sensor triggered. Check the area now.':
      'تم تفعيل حساس اللهب. تفقّد المكان الآن.',
  // Settings
  'Demo Mode is ON - dashboard values are simulated.':
      'الوضع التجريبي يعمل - القيم المعروضة محاكاة.',
  'User profile': 'الملف الشخصي',
  'Your name': 'اسمك',
  'Language': 'اللغة',
  'Risk thresholds (rule-based engine)': 'حدود الخطر (محرك قائم على القواعد)',
  'Demonstration parameters only - not certified fire-safety thresholds. Real deployments require sensor calibration and validation.':
      'قيم تجريبية فقط وليست حدود سلامة معتمدة. الاستخدام الفعلي يتطلب معايرة الحساسات والتحقق منها.',
  'Temperature threshold': 'حد الحرارة',
  'Smoke threshold': 'حد الدخان',
  'Gas threshold': 'حد الغاز',
  'Notifications & Bluetooth': 'الإشعارات والبلوتوث',
  'Emergency notifications': 'إشعارات الطوارئ',
  'High-priority local alerts for flame and risk-level changes':
      'تنبيهات محلية عالية الأولوية للهب وتغيّر مستوى الخطر',
  'Automatic reconnection': 'إعادة الاتصال تلقائيًا',
  'Try to reconnect to the ESP32 when the link drops':
      'حاول إعادة الاتصال بـ ESP32 عند انقطاع الوصلة',
  'Demo Mode': 'الوضع التجريبي',
  'Enable Demo Mode': 'تفعيل الوضع التجريبي',
  'Simulated readings, clearly marked DEMO everywhere':
      'قراءات محاكاة، مكتوب عليها "تجريبي" في كل مكان',
  'Simulated condition': 'الحالة المحاكاة',
  'Simulated scenario': 'السيناريو المحاكى',
  'Normal conditions': 'ظروف طبيعية',
  'Elevated temperature': 'حرارة مرتفعة',
  'Smoke warning': 'تحذير دخان',
  'Gas warning': 'تحذير غاز',
  'High risk conditions': 'ظروف عالية الخطورة',
  'Emergency simulation': 'محاكاة طوارئ',
  'Test scenario only - no real emergency services are contacted.':
      'سيناريو اختباري فقط - لا يتم الاتصال بأي خدمات طوارئ حقيقية.',
  // Onboarding / reports
  'Welcome to Smart Guardian Egypt': 'مرحبًا بك في الحارس الذكي مصر',
  'Smart safety and environmental monitoring for your buildings, in one place.':
      'مراقبة ذكية للسلامة والبيئة لمبانيك في مكان واحد.',
  'Early fire-risk warning': 'إنذار مبكر بخطر الحريق',
  'Six sensors feed a transparent, rule-based risk engine. Every score comes with a clear explanation - no black boxes.':
      'ستة حساسات تغذي محرك خطر شفاف قائم على قواعد. كل نتيجة تأتي بشرح واضح - بلا صناديق سوداء.',
  'Try it now, connect hardware later': 'جرّبه الآن وصِل الأجهزة لاحقًا',
  'Demo Mode simulates realistic scenarios, always clearly labeled as simulated. ESP32 sensors can feed live data over Bluetooth when you are ready.':
      'الوضع التجريبي يحاكي سيناريوهات واقعية، موسومة دائمًا كمحاكاة. يمكن لحساسات ESP32 تزويد بيانات حية عبر البلوتوث عندما تكون جاهزًا.',
  'Smart Guardian Egypt supplements - never replaces - certified fire alarms and emergency services.':
      'الحارس الذكي مصر يكمل - ولا يغني أبدًا عن - أجهزة إنذار الحريق المعتمدة وخدمات الطوارئ.',
  'Get started': 'ابدأ',
  'Next': 'التالي',
  'Export PDF report': 'تصدير تقرير PDF',
  // Smart Map
  'Map': 'الخريطة',
  'SMART MAP': 'الخريطة الذكية',
  'DEMO LOCATIONS': 'مواقع تجريبية',
  'Device': 'جهاز',
  'devices': 'أجهزة',
  'This site mirrors the live dashboard risk level. Run a Demo Mode scenario to watch it change.':
      'هذا الموقع يعكس مستوى الخطر المباشر في لوحة التحكم. شغّل سيناريو تجريبيًا لتراه يتغير.',
  'DEMO LOCATION - sample site, not a real monitored building. No real emergencies are reported.':
      'موقع تجريبي - موقع افتراضي وليس مبنى حقيقيًا تحت المراقبة. لا يتم الإبلاغ عن أي طوارئ حقيقية.',
  'Emergency assistance': 'مساعدة الطوارئ',
  'Emergency number (default: 180 Egypt fire)':
      'رقم الطوارئ (الافتراضي: 180 مطافي مصر)',
  'WhatsApp SOS message': 'رسالة الاستغاثة على واتساب',
  'Attach location to SOS': 'إرفاق موقعي برسالة الاستغاثة',
  'Only attached after your explicit permission request':
      'لا يُرفق إلا بعد موافقتك على إذن الموقع',
  'Data management': 'إدارة البيانات',
  'Delete all stored readings?': 'حذف كل القراءات المخزنة؟',
  'Clear readings': 'مسح القراءات',
  'Delete the alert log?': 'حذف سجل التنبيهات؟',
  'Clear alerts': 'مسح التنبيهات',
  'This cannot be undone.': 'لا يمكن التراجع عن هذا.',
  'Reset app': 'إعادة ضبط التطبيق',
  'Restore every setting to its default and delete all stored readings and alerts.':
      'استرجاع كل الإعدادات إلى الوضع الافتراضي وحذف كل القراءات والتنبيهات المخزنة.',
  'Reset to defaults': 'استعادة الإعدادات الافتراضية',
  'Reset the whole app?': 'إعادة ضبط التطبيق بالكامل؟',
  'This restores all settings (thresholds, emergency number, SOS message, toggles, Demo Mode) to defaults, disconnects Bluetooth and deletes all readings and alerts. This cannot be undone.':
      'سيتم استرجاع كل الإعدادات (الحدود، رقم الطوارئ، رسالة الاستغاثة، المفاتيح، الوضع التجريبي) إلى الافتراضي، وقطع البلوتوث، وحذف كل القراءات والتنبيهات. لا يمكن التراجع.',
  'Reset': 'إعادة ضبط',
  'App reset to defaults.': 'تمت إعادة ضبط التطبيق.',
  'About Smart Guardian Egypt': 'عن الحارس الذكي مصر',
  'Version 1.1.0\nIntelligence That Protects. Technology That Builds the Future.\nSmart safety and environmental monitoring platform.\n\nThe current risk engine is rule-based with configurable demonstration thresholds. Machine-learning risk classification is planned as a future upgrade and is not active in this version.\n\nThis app is a supplementary monitoring tool. It is not a replacement for certified smoke alarms, certified fire detection systems, or professional emergency services.':
      'الإصدار 1.1.0\nذكاء يحمي. تكنولوجيا تبني المستقبل.\nمنصة ذكية لمراقبة السلامة والبيئة.\n\nمحرك الخطر الحالي قائم على قواعد بحدود تجريبية قابلة للضبط. التصنيف بالتعلم الآلي مخطط كتطوير مستقبلي وغير مفعّل في هذا الإصدار.\n\nهذا التطبيق أداة مراقبة مساعدة، ولا يغني عن أجهزة إنذار الدخان المعتمدة ولا أنظمة كشف الحريق المعتمدة ولا خدمات الطوارئ.',
  // Account / login
  'My account': 'حسابي',
  'MY ACCOUNT': 'حسابي',
  'Signed in as': 'مسجل الدخول باسم',
  'Sign out?': 'تسجيل الخروج؟',
  'You will need to sign in again to use the app.':
      'ستحتاج إلى تسجيل الدخول مرة أخرى لاستخدام التطبيق.',
  'Account': 'الحساب',
  'Sign out': 'تسجيل الخروج',
  'Sign in': 'تسجيل الدخول',
  'Create account': 'إنشاء حساب',
  'Create a new account': 'إنشاء حساب جديد',
  'I already have an account': 'لدي حساب بالفعل',
  'Forgot password?': 'نسيت كلمة المرور؟',
  'Email': 'البريد الإلكتروني',
  'Password': 'كلمة المرور',
  'The email address is not valid.': 'البريد الإلكتروني غير صالح.',
  'Password must be at least 6 characters.':
      'يجب ألا تقل كلمة المرور عن 6 أحرف.',
  'Enter your email first, then tap reset.':
      'اكتب بريدك الإلكتروني أولًا ثم اضغط استعادة.',
  'Password reset email sent. Check your inbox and spam folder.':
      'تم إرسال رسالة استعادة كلمة المرور. تحقق من الوارد والبريد المزعج.',
  'Wrong email or password.': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
  'An account already exists with this email.': 'يوجد حساب بهذا البريد بالفعل.',
  'Password is too weak. Use at least 6 characters.':
      'كلمة المرور ضعيفة. استخدم 6 أحرف على الأقل.',
  'No internet connection. Try again when you are online.':
      'لا يوجد اتصال بالإنترنت. حاول مرة أخرى عند الاتصال.',
  'Too many attempts. Wait a moment and try again.':
      'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.',
  'This account has been disabled.': 'تم تعطيل هذا الحساب.',
  'Email/password sign-in is not enabled for this app yet.':
      'تسجيل الدخول بالبريد وكلمة المرور غير مفعّل لهذا التطبيق بعد.',
  'Sign-in failed. Please try again.': 'فشل تسجيل الدخول. حاول مرة أخرى.',
  'Sign-in service is unavailable. Check your internet connection and restart the app.':
      'خدمة تسجيل الدخول غير متاحة. تحقق من الإنترنت وأعد تشغيل التطبيق.',
  // Emergency screen
  'Could not open the phone dialer.': 'تعذر فتح تطبيق الاتصال.',
  'Write a message first.': 'اكتب رسالة أولًا.',
  'Location permission denied. Message sent without location.':
      'تم رفض إذن الموقع. ستُرسل الرسالة بدون موقع.',
  'Could not get your location. Turn on GPS and try again, or send without it.':
      'تعذر تحديد موقعك. شغّل خدمة الموقع (GPS) وحاول مرة أخرى، أو أرسل بدونه.',
  'Could not open WhatsApp.': 'تعذر فتح واتساب.',
  'Emergency call': 'مكالمة طوارئ',
  'Egypt emergency numbers': 'أرقام الطوارئ في مصر',
  'Tap a number to open the dialer with it filled in. You press call yourself.':
      'اضغط على الرقم ليفتح الاتصال والرقم مكتوب، وأنت تضغط اتصال بنفسك.',
  'Fire 180': 'مطافي 180',
  'Ambulance 123': 'إسعاف 123',
  'Police 122': 'شرطة 122',
  'WhatsApp SOS': 'استغاثة واتساب',
  'Include my location': 'إرفاق موقعي',
  'Sends a Google Maps link with your GPS position. Asks permission now.':
      'يرسل رابط خرائط جوجل بموقعك من GPS. سيطلب الإذن الآن.',
  'REVIEW IN WHATSAPP': 'مراجعة في واتساب',
  'WhatsApp opens with your text. You pick the contact and press send.':
      'يفتح واتساب والنص جاهز. أنت تختار جهة الاتصال وتضغط إرسال.',
  'Safety instructions': 'تعليمات السلامة',
  'How to protect yourself': 'كيف تحمي نفسك',
  'Getting your location...': 'جارٍ تحديد موقعك...',
  'Open safety guide': 'فتح دليل السلامة',
  'Quick steps and what to do for fire, gas leaks and electrical hazards, in Arabic and English.':
      'خطوات سريعة وما يجب فعله عند الحريق وتسرب الغاز والمخاطر الكهربائية.',
  'SAFETY GUIDE': 'دليل السلامة',
};
