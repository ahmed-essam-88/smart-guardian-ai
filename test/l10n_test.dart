import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_guardian_ai/core/l10n.dart';
import 'package:smart_guardian_ai/ui/screens/safety_screen.dart';

Widget _app(String lang, Widget child) => MaterialApp(
      locale: Locale(lang),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );

void main() {
  test('dictionary and dynamic rules', () {
    expect(translateToArabic('SAFE'), 'آمن');
    expect(translateToArabic('Fire 180'), 'مطافي 180');
    expect(translateToArabic('5m ago'), 'منذ 5 دقيقة');
    expect(translateToArabic('Smoke reading 150 above 100 threshold'),
        'قراءة الدخان 150 أعلى من الحد 100');
    expect(translateToArabic('Something unknown'), 'Something unknown');
  });

  testWidgets('safety guide renders Arabic and RTL', (tester) async {
    await tester.pumpWidget(_app('ar', const SafetyScreen()));
    expect(find.text('عند حدوث حريق'), findsOneWidget);
    expect(find.text('مطافي 180'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(SafetyScreen))),
        TextDirection.rtl);
  });

  testWidgets('safety guide renders English', (tester) async {
    await tester.pumpWidget(_app('en', const SafetyScreen()));
    expect(find.text('If there is a fire'), findsOneWidget);
    expect(find.text('Fire 180'), findsOneWidget);
  });
}
