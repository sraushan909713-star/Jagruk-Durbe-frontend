// lib/main.dart
// ─────────────────────────────────────────────────────────────
// Entry point of Gram Seva app.
// Shows SplashScreen on launch, then navigates to Login.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/screens/splash_screen.dart';

void main() {
  runApp(const GramSevaApp());
}

class GramSevaApp extends StatelessWidget {
  const GramSevaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}