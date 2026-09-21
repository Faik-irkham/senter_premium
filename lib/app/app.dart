import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/flashlight/presentation/flashlight_page.dart';

class SenterPremiumApp extends StatelessWidget {
  const SenterPremiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const FlashlightPage(),
    );
  }
}
