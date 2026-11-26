import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_guardian_ai/services/auth_service.dart';
import 'package:smart_guardian_ai/core/l10n.dart';
import 'package:smart_guardian_ai/ui/screens/login_screen.dart';

class FakeAuth extends AuthApi {
  String? _email;
  String? lastEmail;
  bool fail = false;
  @override
  String? get email => _email;
  @override
  bool get available => true;
  @override
  Future<void> signIn(String e, String p) async {
    if (fail) throw const AuthFailure('Wrong email or password.');
    lastEmail = e;
    _email = e;
    notifyListeners();
  }

  @override
  Future<void> signUp(String e, String p) => signIn(e, p);
  @override
  Future<void> sendPasswordReset(String e) async {}
  @override
  Future<void> signOut() async {
    _email = null;
    notifyListeners();
  }
}

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
  test('error code mapping', () {
    expect(authErrorMessage('wrong-password'), 'Wrong email or password.');
    expect(authErrorMessage('invalid-credential'), 'Wrong email or password.');
    expect(authErrorMessage('weak-password'), contains('6 characters'));
    expect(authErrorMessage('operation-not-allowed'), contains('not enabled'));
    expect(authErrorMessage('something-else'),
        'Sign-in failed. Please try again.');
  });

  testWidgets('sign in with valid input calls the auth api', (tester) async {
    final auth = FakeAuth();
    await tester.pumpWidget(_app('en', LoginScreen(auth: auth)));
    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(auth.lastEmail, 'a@b.com');
  });

  testWidgets('validates email and password before calling', (tester) async {
    final auth = FakeAuth();
    await tester.pumpWidget(_app('en', LoginScreen(auth: auth)));
    await tester.enterText(find.byType(TextField).at(0), 'nope');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('The email address is not valid.'), findsOneWidget);
    expect(auth.lastEmail, isNull);
  });

  testWidgets('Arabic login has no guest option', (tester) async {
    await tester.pumpWidget(_app('ar', LoginScreen(auth: FakeAuth())));
    expect(find.text('تسجيل الدخول'), findsWidgets);
    expect(find.text('المتابعة بدون حساب'), findsNothing);
    expect(find.text('Continue without an account'), findsNothing);
  });

  testWidgets('login screen language switch', (tester) async {
    String? picked;
    await tester.pumpWidget(_app(
        'en',
        LoginScreen(
            auth: FakeAuth(), language: 'en', onLanguage: (v) => picked = v)));
    await tester.tap(find.text('العربية'));
    expect(picked, 'ar');
  });

  test('account tab strings are translated', () {
    expect(translateToArabic('My account'), 'حسابي');
    expect(translateToArabic('Sign out'), 'تسجيل الخروج');
  });
}
