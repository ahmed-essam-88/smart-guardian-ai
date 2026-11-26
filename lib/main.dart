import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'data/settings_store.dart';
import 'services/auth_service.dart';
import 'state/monitor_controller.dart';
import 'ui/screens/splash_screen.dart';

/// Gives every screen access to the shared [MonitorController].
class AppScope extends InheritedNotifier<MonitorController> {
  const AppScope({
    super.key,
    required MonitorController controller,
    required super.child,
  }) : super(notifier: controller);

  static MonitorController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing');
    return scope!.notifier!;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsStore.load();
  final auth = FirebaseAuthApi();
  await auth.init();
  final controller = MonitorController(settings, auth);
  await controller.init();
  FlutterError.onError = (details) => FlutterError.presentError(details);
  runApp(AppScope(controller: controller, child: const SmartGuardianApp()));
}

class SmartGuardianApp extends StatelessWidget {
  const SmartGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    final code = AppScope.of(context).languageCode;
    return MaterialApp(
      title: 'Smart Guardian Egypt',
      locale: Locale(code),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
