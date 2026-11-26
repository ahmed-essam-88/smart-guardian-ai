import 'package:flutter/material.dart' hide Text;

import '../../main.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// Shows the login screen until the user signs in or chooses to continue
/// without an account. The choice is remembered until sign-out or app reset.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final auth = scope.auth;
    return ListenableBuilder(
      listenable: Listenable.merge([auth, scope]),
      builder: (context, _) {
        if (auth.email != null) {
          return const HomeShell();
        }
        return LoginScreen(
          auth: auth,
          language: scope.languageCode,
          onLanguage: scope.setLanguage,
        );
      },
    );
  }
}
