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
import '../../mandi_prices/screens/mandi_home_screen.dart';                   // ✅ ADD
import '../../kyv/screens/kyv_hub_screen.dart';                               // ✅ ADD
import '../../profile/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';                  // ✅ ADD
import '../../../core/network/api_service.dart';                              // ✅ ADD
import '../../kyv/models/kyv_models.dart';                                    // ✅ ADD

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // — Currently selected tab ────────────────────────────────
  int _selectedIndex = 0;

  // — KYV nav dot: new unanswered & not-dismissed question ──
  bool _showKyvDot = false;                                                   // ✅ ADD

  @override                                                                   // ✅ ADD
  void initState() {                                                          // ✅ ADD
    super.initState();                                                        // ✅ ADD
    _refreshKyvDot();                                                         // ✅ ADD
  }                                                                           // ✅ ADD

  Future<void> _refreshKyvDot() async {                                       // ✅ ADD
    try {                                                                     // ✅ ADD
      final json = await ApiService.getKyvActive();                          // ✅ ADD
      if (!mounted) return;                                                   // ✅ ADD
      if (json == null) {                                                     // ✅ ADD
        setState(() => _showKyvDot = false);                                  // ✅ ADD
        return;                                                               // ✅ ADD
      }                                                                       // ✅ ADD
      final q = KyvActiveQuestion.fromJson(json);                            // ✅ ADD
      final prefs = await SharedPreferences.getInstance();                    // ✅ ADD
      final dismissed = prefs.getString('kyv_dismissed_id');                  // ✅ ADD
      if (!mounted) return;                                                   // ✅ ADD
      setState(() {                                                           // ✅ ADD
        _showKyvDot = !q.hasAnswered && dismissed != q.id;                    // ✅ ADD
      });                                                                     // ✅ ADD
    } catch (_) {                                                             // ✅ ADD
      // non-critical — leave dot as-is on failure                            // ✅ ADD
    }                                                                         // ✅ ADD
  }                                                                           // ✅ ADD

  // — Tab screens ───────────────────────────────────────────
  final List<Widget> _screens = const [
    HomeTab(),
    MandiHomeScreen(),
    KyvHubScreen(),
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
                _navItem(0, Icons.home_outlined,        Icons.home,            'Home'),
                _navItem(1, Icons.storefront_outlined,  Icons.storefront,      'Crop Prices'),
                _navItem(2, Icons.location_on_outlined, Icons.location_on,     'Know Your Village'),
                _navItem(3, Icons.person_outlined,      Icons.person,          'Profile'),
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
        onTap: () {                                                         // ✅ CHANGE
            final leavingKyv = _selectedIndex == 2 && index != 2;            // ✅ ADD
            setState(() => _selectedIndex = index);                          // ✅ ADD
            if (leavingKyv) _refreshKyvDot();  // answered? clears the dot   // ✅ ADD
          },                                                                  // ✅ ADD
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(                                                          // ✅ CHANGE
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive ? activeIcon : icon,
                    color: isActive ? AppColors.primary : AppColors.textHint,
                    size: 24,
                  ),
                  // KYV "new question" dot — index 2 only
                  if (index == 2 && _showKyvDot)
                    Positioned(
                      right: -2, top: -2,
                      child: Container(
                        width: 9, height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.cta,            // terracotta — stands out on green
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBg, width: 1.5),
                        ),
                      ),
                    ),
                ],
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
