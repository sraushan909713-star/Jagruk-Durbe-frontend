// lib/features/home/screens/home_screen.dart
// ─────────────────────────────────────────────────────────────
// Home screen — main screen after login.
// Contains bottom navigation with 4 tabs:
//   🏠 Home     — weather card + quick action grid
//   📢 Awaaz    — Gram Awaaz complaints feed
//   📋 Schemes  — government schemes list
//   👤 Profile  — user profile and settings
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'home_tab.dart';
import '../../schemes/screens/schemes_screen.dart';
import '../../gram_awaaz/screens/gram_awaaz_screen.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // — Currently selected tab ────────────────────────────────
  int _selectedIndex = 0;

  // — Tab screens ───────────────────────────────────────────
  final List<Widget> _screens = const [
    HomeTab(),
    GramAwaazScreen(),
    SchemesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        // IndexedStack keeps all tabs alive — state is preserved
        // when switching between tabs
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _navItem(0, Icons.home_outlined,    Icons.home,           'Home'),
                _navItem(1, Icons.campaign_outlined, Icons.campaign,      'Awaaz'),
                _navItem(2, Icons.article_outlined,  Icons.article,       'Schemes'),
                _navItem(3, Icons.person_outlined,   Icons.person,        'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // — Bottom nav item ───────────────────────────────────────
  Widget _navItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textHint,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
