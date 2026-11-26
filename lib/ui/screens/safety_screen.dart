import 'package:flutter/material.dart' hide Text;
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../widgets/gradient_card.dart';

class _Section {
  final IconData icon;
  final Color color;
  final String titleEn, titleAr;
  final List<String> en, ar;
  const _Section(
      this.icon, this.color, this.titleEn, this.titleAr, this.en, this.ar);
}

const _sections = <_Section>[
  _Section(
    Icons.local_fire_department,
    AppColors.critical,
    'If there is a fire',
    'عند حدوث حريق',
    [
      'Get out immediately. Do not stop to collect belongings.',
      'Alert the people around you on the way out.',
      'Stay low if there is smoke. Cover your nose and mouth with a cloth.',
      'Feel the door with the back of your hand before opening it. If it is hot, do not open it. Use another way out.',
      'Never use the elevator. Use the stairs.',
      'Close doors behind you to slow the fire and smoke.',
      'Once outside, call the fire brigade (180) and move away from the building.',
      'Never go back inside. Wait for the firefighters.',
      'If your clothes catch fire: stop, drop to the ground, cover your face and roll until it is out.',
      'If you are trapped: close the door, seal the gaps with wet cloth, go to a window, signal for help and call 180.',
    ],
    [
      'اخرج فورًا ولا تتوقف لجمع أغراضك.',
      'نبّه من حولك وأنت تخرج.',
      'إذا كان هناك دخان فابقَ منخفضًا قرب الأرض وغطِّ أنفك وفمك بقطعة قماش.',
      'المس الباب بظهر يدك قبل فتحه. إذا كان ساخنًا فلا تفتحه واستخدم مخرجًا آخر.',
      'لا تستخدم المصعد أبدًا. استخدم السلم.',
      'أغلق الأبواب خلفك لإبطاء انتشار النار والدخان.',
      'بعد الخروج اتصل بالمطافي (180) وابتعد عن المبنى.',
      'لا تعد إلى الداخل أبدًا. انتظر رجال الإطفاء.',
      'إذا اشتعلت ملابسك: توقف، اسقط على الأرض، غطِّ وجهك وتدحرج حتى تنطفئ.',
      'إذا حوصرت: أغلق الباب، سدّ الفتحات بقماش مبلل، اذهب إلى نافذة، أشر لطلب النجدة واتصل بـ 180.',
    ],
  ),
  _Section(
    Icons.gas_meter,
    AppColors.high,
    'If you smell gas',
    'عند شم رائحة غاز',
    [
      'Do not switch any light or appliance on or off. Do not use a lighter or match.',
      'Do not use your phone inside the area.',
      'If it is safe, close the gas cylinder or main valve.',
      'Open doors and windows to let the gas out.',
      'Leave the building and take everyone with you.',
      'From a safe distance, call the emergency services or the gas company.',
    ],
    [
      'لا تُشغّل أو تُطفئ أي إضاءة أو جهاز كهربائي، ولا تستخدم ولاعة أو عود ثقاب.',
      'لا تستخدم هاتفك داخل المكان.',
      'إذا كان ذلك آمنًا فأغلق محبس الأسطوانة أو المحبس الرئيسي.',
      'افتح الأبواب والنوافذ ليخرج الغاز.',
      'اترك المبنى وأخرج كل من معك.',
      'من مكان آمن بعيد اتصل بالطوارئ أو بشركة الغاز.',
    ],
  ),
  _Section(
    Icons.electrical_services,
    AppColors.medium,
    'Electrical fires',
    'الحرائق الكهربائية',
    [
      'Never pour water on an electrical fire.',
      'If you can do it safely, switch off the power at the main breaker.',
      'Use a CO2 or dry powder extinguisher only if you are trained and the fire is small.',
      'Otherwise leave and call 180.',
      'Do not overload sockets. Replace damaged cables.',
    ],
    [
      'لا تصب الماء على حريق كهربائي أبدًا.',
      'إذا كان ذلك آمنًا فافصل الكهرباء من القاطع الرئيسي.',
      'استخدم طفاية ثاني أكسيد الكربون أو البودرة الجافة فقط إذا كنت مدربًا والحريق صغير.',
      'وإلا فاخرج واتصل بـ 180.',
      'لا تحمّل المقابس فوق طاقتها واستبدل الأسلاك التالفة.',
    ],
  ),
  _Section(
    Icons.soup_kitchen,
    AppColors.high,
    'Kitchen and oil fires',
    'حرائق المطبخ والزيت',
    [
      'Turn off the heat if it is safe.',
      'Cover the pan with a lid or a metal tray to cut off the air.',
      'Never use water on an oil fire.',
      'Never carry a burning pan.',
      'If it spreads, leave and call 180.',
    ],
    [
      'أطفئ مصدر الحرارة إذا كان ذلك آمنًا.',
      'غطِّ الإناء بغطاء أو صينية معدنية لقطع الهواء عن النار.',
      'لا تستخدم الماء على حريق الزيت أبدًا.',
      'لا تحمل إناءً مشتعلًا.',
      'إذا انتشرت النار فاخرج واتصل بـ 180.',
    ],
  ),
  _Section(
    Icons.fire_extinguisher,
    AppColors.electricBlue,
    'Using a fire extinguisher (PASS)',
    'استخدام طفاية الحريق (PASS)',
    [
      'Only try if the fire is small, you have a clear way out behind you and you know how to use it.',
      'Pull the safety pin.',
      'Aim the nozzle at the base of the fire.',
      'Squeeze the handle.',
      'Sweep from side to side. If the fire does not go out quickly, leave.',
    ],
    [
      'حاول فقط إذا كانت النار صغيرة ومخرجك خلفك مفتوح وتعرف كيف تستخدمها.',
      'اسحب مسمار الأمان.',
      'وجّه الفوهة إلى قاعدة النار.',
      'اضغط على المقبض.',
      'حرّك الفوهة يمينًا ويسارًا. إذا لم تنطفئ النار بسرعة فاخرج.',
    ],
  ),
  _Section(
    Icons.home_work,
    AppColors.safe,
    'Prevent it at home',
    'الوقاية في البيت',
    [
      'Install smoke alarms and test them every month.',
      'Plan two exits from every room and practise the escape plan with your family.',
      'Keep matches, lighters and candles away from children.',
      'Do not leave cooking, heaters or candles unattended.',
      'Keep the exits and the stairs clear.',
      'Keep a small fire extinguisher in the kitchen and know where it is.',
      'Save 180 (fire), 123 (ambulance) and 122 (police) in your phone.',
    ],
    [
      'ركّب أجهزة إنذار الدخان واختبرها كل شهر.',
      'حدّد مخرجين من كل غرفة ودرّب أسرتك على خطة الهروب.',
      'أبعد الكبريت والولاعات والشموع عن الأطفال.',
      'لا تترك الطبخ أو المدافئ أو الشموع دون مراقبة.',
      'أبقِ المخارج والسلالم خالية من العوائق.',
      'احتفظ بطفاية حريق صغيرة في المطبخ وتأكد أنك تعرف مكانها.',
      'احفظ 180 (مطافي) و123 (إسعاف) و122 (شرطة) في هاتفك.',
    ],
  ),
];

/// Bilingual safety guide. Content follows the app language.
class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  Future<void> _dial(String number) async {
    await launchUrl(Uri(scheme: 'tel', path: number));
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabicContext(context);
    return Scaffold(
      appBar: AppBar(title: const Text('SAFETY GUIDE')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientCard(
            borderColor: AppColors.critical.withOpacity(0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Egypt emergency numbers',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.critical),
                        onPressed: () => _dial('180'),
                        child: const Text('Fire 180'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.high),
                        onPressed: () => _dial('123'),
                        child: const Text('Ambulance 123'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _dial('122'),
                        child: const Text('Police 122'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          for (final s in _sections) ...[
            const SizedBox(height: 12),
            GradientCard(
              borderColor: s.color.withOpacity(0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(s.icon, color: s.color, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(ar ? s.titleAr : s.titleEn,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < (ar ? s.ar : s.en).length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text('${i + 1}.',
                                style: TextStyle(
                                    color: s.color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                          Expanded(
                            child: Text((ar ? s.ar : s.en)[i],
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.45,
                                    color: AppColors.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            ar
                ? 'هذا التطبيق أداة مراقبة مساعدة ولا يغني عن أجهزة الإنذار المعتمدة ولا عن خدمات الطوارئ. هذه الإرشادات عامة، وفي أي خطر حقيقي اتصل بالطوارئ فورًا.'
                : 'This app is a supplementary monitoring tool. It does not replace certified alarms or emergency services. These tips are general. In real danger, call emergency services immediately.',
            style: const TextStyle(
                fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
