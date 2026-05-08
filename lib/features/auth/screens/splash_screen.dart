// lib/features/auth/screens/splash_screen.dart
// ─────────────────────────────────────────────────────────────
// Splash screen — first thing villagers see when opening the app.
// Shows for 3 seconds then navigates to Login screen.
//
// Design (from locked design sprint — Screen 1):
//   Background: #14532D (primaryDark — deep forest green)
//   Logo: leaf emoji in frosted circle
//   Title: "Gram Seva" in white Playfair Display
//   Subtitle: "AWAKEN DURBE" in white caps
//   Hindi: "जागरूक दुर्बे" in white Noto Sans Devanagari
//   Footer: "DURBE · GAYA · BIHAR" in faded white
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    // — Fade-in animation ─────────────────────────────────
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // — Navigate to Login after 3 seconds ─────────────────
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Stack(
          children: [
            // — Decorative circles (background detail) ────
            Positioned(
              top: -60, right: -60,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.07), width: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -30, left: -30,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),

            // — Main content ──────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // Logo circle
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.22), width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text('🌿', style: TextStyle(fontSize: 36)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // App name
                  Text(
                    AppConstants.appName,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // "AWAKEN DURBE" subtitle
                  Text(
                    'AWAKEN DURBE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.55),
                      letterSpacing: 2.0,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Hindi tagline
                  Text(
                    AppConstants.appTaglineHindi,
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Village footer
                  Text(
                    'DURBE · ${AppConstants.villageDistrict.toUpperCase()}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.38),
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Loading dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dot(active: true),
                      const SizedBox(width: 4),
                      _dot(active: false),
                      const SizedBox(width: 4),
                      _dot(active: false),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot({required bool active}) {
    return Container(
      width: active ? 14 : 5,
      height: 5,
      decoration: BoxDecoration(
        color: active
            ? Colors.white
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}