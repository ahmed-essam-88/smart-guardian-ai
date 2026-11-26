import 'package:flutter/material.dart' hide Text;
import '../../core/l10n.dart';

import '../../core/theme.dart';

/// Shown whenever the values on screen come from Demo Mode. The user must
/// always know whether displayed readings are real or simulated.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.medium.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.medium.withOpacity(0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.science_outlined, size: 15, color: AppColors.medium),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'DEMO MODE - readings on screen are simulated, not from hardware.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
