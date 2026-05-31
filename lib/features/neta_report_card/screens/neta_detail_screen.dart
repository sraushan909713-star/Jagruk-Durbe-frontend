// lib/features/neta_report_card/screens/neta_detail_screen.dart
// ─────────────────────────────────────────────────────────────
// Neta Detail — full profile, star rating UI, history graph.
// Rating rules:
//   - Window must be open
//   - User must be Durbe Niwasi (verified)
//   - One submission per window — locked after submit
// Graph shows per-cycle average ratings (X = label, Y = stars).
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import '../../../core/utils/cloudinary_url.dart';

class NetaDetailScreen extends StatefulWidget {
  final String netaId;
  final bool windowOpen;
  final String? windowLabel;

  const NetaDetailScreen({
    super.key,
    required this.netaId,
    required this.windowOpen,
    this.windowLabel,
  });

  @override
  State<NetaDetailScreen> createState() => _NetaDetailScreenState();
}

class _NetaDetailScreenState extends State<NetaDetailScreen> {

  Map<String, dynamic>? _neta;
  List<dynamic> _history = [];
  bool _loading          = true;
  bool _submitting       = false;
  int _selectedStars     = 0;     // 0 = not selected yet
  bool _isVerified       = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVerified = prefs.getBool('is_verified') ?? false;

      final results = await Future.wait([
        ApiService.getNetaDetail(widget.netaId),
        ApiService.getNetaHistory(widget.netaId),
      ]);
      if (mounted) setState(() {
        _neta    = results[0] as Map<String, dynamic>;
        _history = (results[1] as Map<String, dynamic>)['history'] ?? [];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Submit rating ────────────────────────────────────────
  Future<void> _submitRating() async {
    if (_selectedStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating first.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await ApiService.submitNetaRating(
        netaId: widget.netaId,
        stars: _selectedStars,
      );
      if (mounted) {
        if (result['id'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rating submitted! Thank you for your vote.'),
              backgroundColor: AppColors.primary,
            ),
          );
          _loadAll(); // refresh to show has_rated + updated avg
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['detail'] ?? 'Could not submit rating.'),
              backgroundColor: AppColors.cta,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ─── Large star row for rating input ─────────────────────
  Widget _ratingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starNum = i + 1;
        return GestureDetector(
          onTap: () => setState(() => _selectedStars = starNum),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              starNum <= _selectedStars
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: 40,
              color: starNum <= _selectedStars
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFD1D5DB),
            ),
          ),
        );
      }),
    );
  }

  // ─── Small display stars ──────────────────────────────────
  Widget _displayStars(double avg) {
    return Row(
      children: List.generate(5, (i) {
        if (i < avg.floor()) {
          return const Icon(Icons.star_rounded,
              size: 18, color: Color(0xFFF59E0B));
        } else if (i < avg && avg - i >= 0.5) {
          return const Icon(Icons.star_half_rounded,
              size: 18, color: Color(0xFFF59E0B));
        } else {
          return const Icon(Icons.star_outline_rounded,
              size: 18, color: Color(0xFFD1D5DB));
        }
      }),
    );
  }

  // ─── History graph (custom bar chart) ────────────────────
  Widget _historyGraph() {
    if (_history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No rating history yet.\nHistory will appear after the first\nclosed rating cycle.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textHint,
              height: 1.6,
            ),
          ),
        ),
      );
    }

    // Find max for scaling
    final maxRating = 5.0;

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _history.map<Widget>((point) {
          final avg = (point['average_stars'] as num).toDouble();
          final label = point['window_label'] as String;
          final barHeight = (avg / maxRating) * 110;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Value label
                  Text(
                    avg.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // X label
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_neta == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text('Leader not found.',
              style: GoogleFonts.inter(color: AppColors.textHint)),
        ),
      );
    }

    final avg = _neta!['average_rating'] != null
        ? (_neta!['average_rating'] as num).toDouble()
        : null;
    final total       = _neta!['total_ratings'] as int? ?? 0;
    final hasRated    = _neta!['has_rated_this_window'] == true;
    final designation = _neta!['designation'] ?? '';

    // ── Can user rate? ────────────────────────────────────
    final canRate = widget.windowOpen && _isVerified && !hasRated;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _neta!['name'] ?? 'Leader',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ─── Profile card ────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  // Photo
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _neta!['photo_url'] != null
                        ? Image.network(
                            CloudinaryUrl.thumb(_neta!['photo_url']),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Text('🏛️',
                                  style: TextStyle(fontSize: 28)),
                            ),
                          )
                        : const Center(
                            child: Text('🏛️',
                                style: TextStyle(fontSize: 28)),
                          ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _neta!['name'] ?? '',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          designation,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_neta!['party'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _neta!['party'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─── Overall rating card ─────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Rating',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (avg != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                avg.toStringAsFixed(1),
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                ' / 5',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _displayStars(avg),
                        ] else
                          Text(
                            'No ratings yet',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.textHint,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '$total',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        total == 1 ? 'vote' : 'votes',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─── Rating section ───────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Rating',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Already rated ──────────────────────
                  if (hasRated)
                    _statusBanner(
                      icon: '✅',
                      text: 'You have already rated in the ${widget.windowLabel ?? 'current'} window.',
                      subtext: 'One vote per window — thank you for participating!',
                      bgColor: const Color(0xFFDCFCE7),
                      borderColor: const Color(0xFF86EFAC),
                      textColor: const Color(0xFF166534),
                    )

                  // ── Window closed ──────────────────────
                  else if (!widget.windowOpen)
                    _statusBanner(
                      icon: '🔒',
                      text: 'Rating window is currently closed.',
                      subtext: 'Next window opens on Jan 1 or Jul 1.',
                      bgColor: const Color(0xFFFEF3C7),
                      borderColor: const Color(0xFFFCD34D),
                      textColor: const Color(0xFF92400E),
                    )

                  // ── Not verified ───────────────────────
                  else if (!_isVerified)
                    _statusBanner(
                      icon: '🔐',
                      text: 'Only verified Durbe Niwasi residents can rate.',
                      subtext: 'Contact the Admin to get your verification badge.',
                      bgColor: const Color(0xFFEFF6FF),
                      borderColor: const Color(0xFF93C5FD),
                      textColor: const Color(0xFF1D4ED8),
                    )

                  // ── Can rate — show star selector ──────
                  else ...[
                    Text(
                      'How would you rate ${_neta!['name']?.split(' ').first}\'s performance?',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ratingStars(),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _selectedStars == 0 ? 'Tap to rate'
                            : _selectedStars == 1 ? '⭐ Very Poor'
                            : _selectedStars == 2 ? '⭐⭐ Poor'
                            : _selectedStars == 3 ? '⭐⭐⭐ Average'
                            : _selectedStars == 4 ? '⭐⭐⭐⭐ Good'
                            : '⭐⭐⭐⭐⭐ Excellent',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submitRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cta,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                'Submit Rating',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─── History graph card ───────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Rating History',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(per 6-month cycle)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _historyGraph(),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Status banner helper ─────────────────────────────────
  Widget _statusBanner({
    required String icon,
    required String text,
    required String subtext,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: textColor,
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
// End of file