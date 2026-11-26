import 'package:flutter/material.dart' hide Text;

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../widgets/gradient_card.dart';

/// "My account" tab: who is signed in, and sign out.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final c = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) await c.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final email = c.auth.email;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'MY ACCOUNT',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          GradientCard(
            child: Column(
              children: [
                const Icon(Icons.account_circle,
                    size: 72, color: AppColors.cyan),
                const SizedBox(height: 10),
                const Text('Signed in as',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(email ?? '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmSignOut(context),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
