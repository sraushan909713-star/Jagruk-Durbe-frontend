// lib/features/neta_report_card/screens/neta_report_card_screen.dart
// ─────────────────────────────────────────────────────────────
// Neta Ka Report Card — Rate Your Representative
// Shows all registered leaders with their average star rating.
// Banner at top shows whether rating window is currently open.
// Only Durbe Niwasi verified users can submit ratings.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import 'neta_detail_screen.dart';
import 'promises_screen.dart';

class NetaReportCardScreen extends StatefulWidget {
  const NetaReportCardScreen({super.key});

  @override
  State<NetaReportCardScreen> createState() => _NetaReportCardScreenState();
}

class _NetaReportCardScreenState extends State<NetaReportCardScreen> {

  List<dynamic> _netas     = [];
  Map<String, dynamic>? _window;
  bool _loading            = true;
  String _selectedFilter   = 'All';

  final List<String> _filters = [
    'All', 'Mukhiya', 'Sarpanch', 'Ward Member', 'MLA', 'MP', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getNetaList(),
        ApiService.getNetaWindowStatus(),
      ]);
      if (mounted) setState(() {
        _netas   = results[0] as List<dynamic>;
        _window  = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Filter leaders by designation ───────────────────────
  List<dynamic> get _filtered {
    if (_selectedFilter == 'All') return _netas;
    return _netas.where((n) {
      final designation = (n['designation'] ?? '').toString().toLowerCase();
      return designation.contains(_selectedFilter.toLowerCase());
    }).toList();
  }

  // ─── Star row widget ──────────────────────────────────────
  Widget _starRow(double? avg, int? total) {
    final rating = avg ?? 0.0;
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < rating.floor()) {
            return const Icon(Icons.star_rounded,
                size: 14, color: Color(0xFFF59E0B));
          } else if (i < rating && rating - i >= 0.5) {
            return const Icon(Icons.star_half_rounded,
                size: 14, color: Color(0xFFF59E0B));
          } else {
            return const Icon(Icons.star_outline_rounded,
                size: 14, color: Color(0xFFD1D5DB));
          }
        }),
        const SizedBox(width: 4),
        Text(
          avg != null
              ? '${avg.toStringAsFixed(1)} (${total ?? 0})'
              : 'No ratings yet',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ─── Designation badge color ──────────────────────────────
  Color _badgeColor(String designation) {
    final d = designation.toLowerCase();
    if (d.contains('sarpanch'))    return const Color(0xFFDCFCE7);
    if (d.contains('ward'))        return const Color(0xFFEFF6FF);
    if (d.contains('mla'))         return const Color(0xFFFEF3C7);
    if (d.contains('mp'))          return const Color(0xFFFCE7F3);
    return AppColors.background;
  }

  Color _badgeTextColor(String designation) {
    final d = designation.toLowerCase();
    if (d.contains('sarpanch'))    return const Color(0xFF166534);
    if (d.contains('ward'))        return const Color(0xFF1D4ED8);
    if (d.contains('mla'))         return const Color(0xFF92400E);
    if (d.contains('mp'))          return const Color(0xFF9D174D);
    return AppColors.textSecondary;
  }

    String _formatWindowDate(String? isoDate) {
        if (isoDate == null) return '';
        try {
        final dt = DateTime.parse(isoDate).toLocal();
        const months = [
            '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${dt.day} ${months[dt.month]} ${dt.year}';
        } catch (_) {
        return '';
        }
    }

  @override
  Widget build(BuildContext context) {
    final bool windowOpen = _window?['is_open'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Neta Report Card',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PromisesScreen()),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fact_check_outlined,
                      size: 15, color: Colors.white),
                  const SizedBox(width: 5),
                  Text('Vaade',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [

            // ─── Tagline banner ─────────────────────────
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'अपने नेता को रेट करें — आपकी आवाज़ मायने रखती है',
                style: GoogleFonts.notoSansDevanagari(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),

            // ─── Rating window status banner ─────────────
            if (_window != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: windowOpen
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: windowOpen
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFCD34D),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      windowOpen ? '🗳' : '🔒',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            windowOpen
                                ? 'Rating window is open — ${_window!['label']}'
                                : 'Rating window is closed',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: windowOpen
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF92400E),
                            ),
                          ),
                          Text(
                            windowOpen
                                ? 'Open until ${_formatWindowDate(_window!['closes_at'])} · Tap a leader to rate'
                                : 'Next window opens ${_formatWindowDate(_window!['opens_at'])}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: windowOpen
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Filter chips ─────────────────────────────
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final f = _filters[i];
                  final isActive = _selectedFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        f,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // ─── Leader list ──────────────────────────────
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No leaders found.',
                            style: GoogleFonts.inter(
                                color: AppColors.textHint),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) =>
                                _netaCard(_filtered[i], windowOpen),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Leader card ──────────────────────────────────────────
  Widget _netaCard(dynamic neta, bool windowOpen) {
    final designation = neta['designation'] ?? '';
    final avg = neta['average_rating'] != null
        ? (neta['average_rating'] as num).toDouble()
        : null;
    final total = neta['total_ratings'] as int?;

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NetaDetailScreen(
              netaId:      neta['id'],
              windowOpen:  windowOpen,
              windowLabel: _window?['label'],
            ),
          ),
        );
        _loadData(); // ✅ refresh after returning from detail
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [

            // ─── Photo / Avatar ────────────────────────
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: neta['photo_url'] != null
                  ? Image.network(
                      neta['photo_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text('🏛️', style: TextStyle(fontSize: 22)),
                      ),
                    )
                  : const Center(
                      child: Text('🏛️', style: TextStyle(fontSize: 22)),
                    ),
            ),

            const SizedBox(width: 12),

            // ─── Name + designation + rating ──────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    neta['name'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _badgeColor(designation),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          designation,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _badgeTextColor(designation),
                          ),
                        ),
                      ),
                      if (neta['party'] != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          neta['party'],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  _starRow(avg, total),
                ],
              ),
            ),

            // ─── Arrow ────────────────────────────────
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
// End of file