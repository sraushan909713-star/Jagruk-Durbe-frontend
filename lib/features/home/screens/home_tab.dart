// lib/features/home/screens/home_tab.dart
// ──────────────────────────────────────────────────────────────────
// Home tab — main dashboard of Gram Seva.
//
// Layout (top to bottom):
//   Header: नमस्ते + Jagruk Durbe + leaf avatar
//   Carousel: Weather (slide 1, hardcoded) + DB banners (slides 2+)
//   Features: 8 cards in 2-column grid — ALL visible without scroll
//   Notification strip
//   Village Pulse
//
// Carousel rules:
//   - Slide 1 is always the weather card (hardcoded, not from DB)
//   - Slides 2+ come from GET /banners/ — sorted by display_order
//   - Auto-scrolls every 5 seconds
//   - Supports image banners (Cloudinary URL) and color gradient banners
//   - Tappable: internal → navigate to screen, external → open browser
// ──────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_service.dart';
import '../../contacts/screens/contacts_screen.dart';
import '../../mandi_prices/screens/mandi_home_screen.dart';                   // ✅ CHANGE
import '../../schemes/screens/schemes_screen.dart';
import '../../gram_awaaz/screens/gram_awaaz_screen.dart';
import '../../vikas_prastav/screens/vikas_prastav_screen.dart';
import '../../neta_report_card/screens/neta_report_card_screen.dart';
import '../../job_alerts/screens/job_alerts_screen.dart';
import '../../guides/screens/guides_screen.dart';
import '../../weather/screens/rain_alerts_screen.dart';
import '../../../core/theme/banner_themes.dart';                              // ✅ ADD
import '../../banners/screens/banner_detail_screen.dart';                     // ✅ ADD
import '../../about/screens/about_screen.dart';                               // ✅ ADD
import '../../../core/utils/cloudinary_url.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {

  // ─── State ───────────────────────────────────────────────────
  Map<String, dynamic>? _weatherData;
  bool _weatherLoading = true;
  List<dynamic> _banners = [];

  // ─── Carousel ────────────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  // ─── Village Pulse state ─────────────────────────────────────
  int _complaintsCount    = 0;
  int _proposalsCount     = 0;
  int _newComplaintsCount = 0;
  bool _pulseLoading      = true;

  // Total slides = 1 weather + banners from DB
  int get _totalSlides => 1 + _banners.length;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadBanners();
    _loadPulse();
  }

  Future<void> _loadWeather() async {
    try {
      final data = await ApiService.getRainAlerts();
      if (mounted) {
        setState(() {
          _weatherData = data;
          _weatherLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await ApiService.getBanners();
      if (mounted) {
        setState(() => _banners = banners);
        _startAutoScroll();
      }
    } catch (_) {
      // Banners are optional — fail silently
      if (mounted) _startAutoScroll();
    }
  }

  Future<void> _loadPulse() async {
    try {
      final complaints = await ApiService.getGramAwaazPosts();
      final proposals  = await ApiService.getVikasPrastavPosts();
      if (mounted) {
        setState(() {
          _complaintsCount    = complaints.length;
          _proposalsCount     = proposals.length;
          // "new" = posted in last 7 days
          final cutoff = DateTime.now().subtract(const Duration(days: 7));
          _newComplaintsCount = complaints.where((c) {
            try {
              return DateTime.parse(c['created_at']).isAfter(cutoff);
            } catch (_) { return false; }
          }).length;
          _pulseLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _pulseLoading = false);
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_totalSlides <= 1) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _totalSlides;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  // ─── Navigate to feature screen ──────────────────────────────
  void _navigateTo(BuildContext context, Widget? screen, String featureName) {
    if (screen != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '$featureName जल्द आ रहा है!',
          style: GoogleFonts.notoSansDevanagari(),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  // ─── Handle banner tap ────────────────────────────────────────
  void _handleBannerTap(Map<String, dynamic> banner) {                        // ✅ CHANGE
    Navigator.of(context).push(                                               // ✅ CHANGE
      MaterialPageRoute(                                                      // ✅ CHANGE
        builder: (_) => BannerDetailScreen(banner: banner),                   // ✅ CHANGE
      ),                                                                      // ✅ CHANGE
    );                                                                        // ✅ CHANGE
  }                                                                           // ✅ CHANGE

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ─── Header ──────────────────────────────────────
              _buildHeader(),
              const SizedBox(height: 14),

              // ─── Unified Carousel ─────────────────────────────
              _buildCarousel(),
              const SizedBox(height: 14),

              // ─── Features grid (8 boxes) ─────────────────────
              Text('Features',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16, fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              _buildFeaturesGrid(),
              const SizedBox(height: 12),

              // ─── Notification strip ───────────────────────────
              _buildNotificationStrip(),
              const SizedBox(height: 16),

              // ─── Village Pulse ────────────────────────────────
              Text('Village Pulse',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16, fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              _buildVillagePulse(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('नमस्ते 🙏',
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 14, color: AppColors.textSecondary)),
            Text(AppConstants.appTagline,
              style: GoogleFonts.playfairDisplay(
                fontSize: 26, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
            Text('${AppConstants.villageName} · ${AppConstants.villageDistrict}',
              style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
        // ✅ CHANGE (D5) — leaf logo is now tappable, opens the About page.
        // Removed the "?" icon — two circles in the header read as duplicate
        // logos. Profile carries the discoverable About entry; the leaf-tap
        // is a quiet bonus for the curious.
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AboutScreen()),
          ),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryMid,
              border: Border.all(
                  color: AppColors.primaryBorder, width: 1.5),
            ),
            child: const Center(
              child: Text('🌿', style: TextStyle(fontSize: 22))),
          ),
        ),
      ],
    );
  }

  // ─── Unified Carousel ────────────────────────────────────────
  Widget _buildCarousel() {
    return Column(
      children: [
        // ── Slide area ────────────────────────────────────────
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _totalSlides,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              if (index == 0) return _buildWeatherSlide();
              final banner = _banners[index - 1] as Map<String, dynamic>;
              return _buildBannerSlide(banner);
            },
          ),
        ),

        // ── Dot indicators ────────────────────────────────────
        if (_totalSlides > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSlides, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width:  isActive ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  // ─── Slide 0: Weather (hardcoded) ────────────────────────────
  Widget _buildWeatherSlide() {
    final temp         = _weatherData?['current_temp_c'];
    final maxTemp      = _weatherData?['today_temp_max_c'];
    final minTemp      = _weatherData?['today_temp_min_c'];
    final warningLevel = (_weatherData?['warning_level'] as String?) ?? 'None';
    final alertLabel   = warningLevel.toLowerCase() == 'heavy'
        ? 'Heavy Rain Warning'
        : warningLevel.toLowerCase() == 'low'
            ? 'Low Rain Warning'
            : 'No rain expected';

    Color pillBg, pillText, pillBorder;
    if (warningLevel.toLowerCase() == 'heavy') {
      pillBg = const Color(0xFFFFE2E2);
      pillText = const Color(0xFF991B1B);
      pillBorder = const Color(0xFFFCA5A5);
    } else if (warningLevel.toLowerCase() == 'low') {
      pillBg = const Color(0xFFFEF3C7);
      pillText = const Color(0xFF92400E);
      pillBorder = const Color(0xFFFCD34D);
    } else {
      pillBg = Colors.green.shade50;
      pillText = Colors.green.shade700;
      pillBorder = Colors.green.shade200;
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RainAlertsScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryBorder),
        ),
        child: _weatherLoading
            ? Center(child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("TODAY'S WEATHER",
                    style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w300,
                      color: AppColors.primaryDark, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Temp + pill
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            temp != null
                                ? '${temp.toStringAsFixed(0)}°C'
                                : '--°C',
                            style: GoogleFonts.inter(
                              fontSize: 32, fontWeight: FontWeight.w300,
                              color: AppColors.primary)),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: pillBorder),
                            ),
                            child: Text(alertLabel,
                              style: GoogleFonts.inter(
                                fontSize: 10, fontWeight: FontWeight.w500,
                                color: pillText)),
                          ),
                        ],
                      ),
                      // Max/min
                      if (maxTemp != null && minTemp != null)
                        Text(
                          'Max ${maxTemp.toStringAsFixed(0)}° · Min ${minTemp.toStringAsFixed(0)}°',
                          style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.primaryDark)),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  // ─── Slides 1+: DB Banners ────────────────────────────────────
  Widget _buildBannerSlide(Map<String, dynamic> banner) {
    final hasImage     = banner['image_url'] != null &&
                         (banner['image_url'] as String).isNotEmpty;
    final theme        = BannerThemes.byKey(banner['color_theme'] as String?); // ✅ CHANGE
    final title        = banner['title']    as String? ?? '';
    final subtitle     = banner['subtitle'] as String?;
    final icon         = banner['icon']     as String?;
    final tag          = banner['tag']      as String?;

    return GestureDetector(
      onTap: () => _handleBannerTap(banner),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: hasImage ? null : theme.gradient,                          // ✅ CHANGE
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [

            // ── Image or color background ──────────────────
            if (hasImage)
              Image.network(
                CloudinaryUrl.full(banner['image_url']),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  decoration: BoxDecoration(
                    gradient: hasImage ? null : theme.gradient,                          // ✅ CHANGE
                  ),
                ),
              ),

            // ── Bottom gradient overlay for text ──────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Color banner content (no image) ───────────
            if (!hasImage)
              Positioned(
                left: 14, top: 0, bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null)
                      Text(icon, style: const TextStyle(fontSize: 22)),
                    if (icon != null) const SizedBox(height: 4),
                    Text(title,
                      style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: Colors.white)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.8))),
                    ],
                    const SizedBox(height: 4),
                    Text('Tap to view →',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.6))),
                  ],
                ),
              ),

            // ── Image banner: title overlay at bottom ─────
            if (hasImage)
              Positioned(
                bottom: 8, left: 12, right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: Colors.white)),
                    if (subtitle != null)
                      Text(subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),

            // ── Tag badge ─────────────────────────────────
            if (tag != null)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tag,
                    style: GoogleFonts.inter(
                      fontSize: 9, color: Colors.white,
                      fontWeight: FontWeight.w500)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── 8-feature grid ──────────────────────────────────────────
  Widget _buildFeaturesGrid() {
    final features = [
      _Feature('📢', 'Gram Awaaz',       'File complaint',       const GramAwaazScreen()),
      _Feature('📋', 'Schemes',          'Govt benefits',         const SchemesScreen()),
      _Feature('🌾', 'Crop Prices',      'Today\'s rates',       const MandiHomeScreen()),
      _Feature('🏗️', 'Vikas Prastav',   'Proposals',            const VikasPrastavScreen()),
      _Feature('📖', 'Guides',           'How to apply docs',    const GuidesScreen()),
      _Feature('📞', 'Contacts',         'Local office numbers', const ContactsScreen()),
      _Feature('⭐', 'Neta Report Card', 'Rate your neta',       const NetaReportCardScreen()),
      _Feature('💼', 'Job Alerts',       'Sarkari naukri',       const JobAlertsScreen()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.9,
      ),
      itemCount: features.length,
      itemBuilder: (context, i) {
        final f = features[i];
        return GestureDetector(
          onTap: () => _navigateTo(context, f.screen, f.title),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(f.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(f.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15, fontWeight: FontWeight.w500,
                    color: AppColors.primary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(f.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textHint),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Notification strip ───────────────────────────────────────
  Widget _buildNotificationStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.ctaLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ctaBorder),
      ),
      child: Row(children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: AppColors.cta, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(
          _pulseLoading
              ? 'Loading...'
              : _newComplaintsCount == 0
                  ? 'No new complaints this week'
                  : '$_newComplaintsCount new complaint${_newComplaintsCount == 1 ? '' : 's'} in your area',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF9A3412),
            fontWeight: FontWeight.w500)),
      ]),
    );
  }


  Widget _buildVillagePulse() {
    return Column(children: [
      _pulseCard(
        emoji:      '📢',
        title:      'Active Complaints',
        subtitle:   'Durbe Village',
        value:      _pulseLoading ? '...' : '$_complaintsCount',
        valueColor: AppColors.cta,
        onTap:      () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GramAwaazScreen())),
      ),
      const SizedBox(height: 10),
      _pulseCard(
        emoji:      '🗳️',
        title:      'Open Proposals',
        subtitle:   'Needs your vote',
        value:      _pulseLoading ? '...' : '$_proposalsCount',
        valueColor: AppColors.primary,
        onTap:      () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const VikasPrastavScreen())),
      ),
    ]);
  }

  Widget _pulseCard({
    required String emoji, required String title,
    required String subtitle, required String value,
    required Color valueColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
                Text(subtitle, style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textHint)),
              ]),
            ]),
            Text(value, style: GoogleFonts.playfairDisplay(
              fontSize: 28, fontWeight: FontWeight.w600,
              color: valueColor)),
          ],
        ),
      ),
    );
  }
}

// ─── Feature data class ──────────────────────────────────────────
class _Feature {
  final String emoji;
  final String title;
  final String subtitle;
  final Widget? screen;
  const _Feature(this.emoji, this.title, this.subtitle, this.screen);
}

