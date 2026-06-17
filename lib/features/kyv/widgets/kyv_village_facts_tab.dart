// lib/features/kyv/widgets/kyv_village_facts_tab.dart
// ─────────────────────────────────────────────────────────────
// Village Facts — the demographics tab inside the KYV hub.
//
//   Metric dropdown (जनसंख्या / वोटर / युवा …) drives BOTH charts:
//     • Solid PIE  — each village's share of the selected metric,
//                    Durbe highlighted green, tap a slice to pop it
//                    out + read its number/%.
//     • BARS       — same metric across all villages, Durbe in green,
//                    others muted, sorted biggest-first.
//
//   Data loads ONCE (GET /kyv/village-facts); switching the metric
//   is instant (client-side) — no network call, smooth morph.
//
//   Empty state shows until the super admin adds villages + metrics
//   (build the platform now, fill data later).
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import '../models/kyv_facts_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/kyv_facts_admin_screen.dart';

class KyvVillageFactsTab extends StatefulWidget {
  const KyvVillageFactsTab({super.key});

  @override
  State<KyvVillageFactsTab> createState() => _KyvVillageFactsTabState();
}

class _KyvVillageFactsTabState extends State<KyvVillageFactsTab> {
  bool _loading = true;
  String? _error;
  KyvVillageFacts? _facts;

  String? _selectedMetricId;   // current dropdown selection
  int _poppedIndex = 0;        // which pie slice is popped out
  String? _userRole;

  // Palette for slices — Durbe (home) always gets primary green via
  // _colorFor(); the rest cycle through these.
  static const List<Color> _palette = [
    Color(0xFF1D9E75), // teal-green
    Color(0xFFC2440A), // terracotta
    Color(0xFFEF9F27), // amber
    Color(0xFF378ADD), // blue
    Color(0xFFD4537E), // pink
    Color(0xFF7C5CBF), // purple
    Color(0xFF5DCAA5), // mint
    Color(0xFFB58900), // gold
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _userRole = prefs.getString('user_role'));
  }

  Future<void> _openAdmin() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const KyvFactsAdminScreen()),
    );
    if (changed == true) {
      setState(() => _loading = true);
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final json = await ApiService.getKyvVillageFacts();
      if (!mounted) return;
      final facts = KyvVillageFacts.fromJson(json);
      setState(() {
        _facts = facts;
        _selectedMetricId =
            facts.metrics.isNotEmpty ? facts.metrics.first.id : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'आँकड़े लोड नहीं हो सके';
        _loading = false;
      });
    }
  }

  // ─── Derived helpers ─────────────────────────────────────────

  List<MapEntry<KyvVillage, int>> _rowsForSelected() {
    final f = _facts!;
    final mid = _selectedMetricId!;
    final rows = <MapEntry<KyvVillage, int>>[];
    for (final v in f.villages) {
      final val = f.valueFor(v.id, mid);
      if (val != null) rows.add(MapEntry(v, val));
    }
    rows.sort((a, b) => b.value.compareTo(a.value)); // desc
    return rows;
  }

  Color _colorFor(KyvVillage village, int paletteIndex) {
    if (village.isHomeVillage) return AppColors.primary; // Durbe = green
    return _palette[paletteIndex % _palette.length];
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!,
            style: GoogleFonts.notoSansDevanagari(
                color: AppColors.textSecondary)),
      );
    }

    final f = _facts!;
    final isSuperAdmin = _userRole == 'super_admin';
    if (f.isEmpty) {
      return Stack(
        children: [
          _emptyState(),
          if (isSuperAdmin)
            Positioned(
              right: 16, bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: _openAdmin,
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                label: Text('आँकड़े जोड़ें',
                    style: GoogleFonts.notoSansDevanagari(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
        ],
      );
    }

    final metric = f.metrics.firstWhere(
      (m) => m.id == _selectedMetricId,
      orElse: () => f.metrics.first,
    );
    final rows = _rowsForSelected();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isSuperAdmin) ...[
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _openAdmin,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 15, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('संपादित करें',
                      style: GoogleFonts.notoSansDevanagari(
                          fontSize: 13, color: AppColors.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        _intro(),
        const SizedBox(height: 14),
        _metricDropdown(f),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          _noDataForMetric()
        else ...[
          _pieCard(metric, rows),
          const SizedBox(height: 14),
          _barsCard(metric, rows),
        ],
        const SizedBox(height: 8),
        _sourceLine(metric),
      ],
    );
  }

  Widget _intro() {
    return Text(
      'दुर्बे घुठिया पंचायत का सबसे बड़ा गाँव है। एक साथ आएँ तो सबसे बड़ी ताक़त।',
      style: GoogleFonts.notoSansDevanagari(
          fontSize: 13, color: AppColors.textSecondary, height: 1.55),
    );
  }

  Widget _metricDropdown(KyvVillageFacts f) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text('दिखाएँ:',
              style: GoogleFonts.notoSansDevanagari(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMetricId,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down,
                    color: AppColors.primary),
                items: f.metrics
                    .map((m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.name,
                              style: GoogleFonts.notoSansDevanagari(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary)),
                        ))
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  setState(() {
                    _selectedMetricId = id;
                    _poppedIndex = 0;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pieCard(KyvMetric metric, List<MapEntry<KyvVillage, int>> rows) {
    final total = rows.fold<int>(0, (s, e) => s + e.value);
    final popped = rows[_poppedIndex.clamp(0, rows.length - 1)];
    final poppedPct =
        total > 0 ? (popped.value / total * 100).toStringAsFixed(0) : '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('गाँवों की हिस्सेदारी — ${metric.name}',
              style: GoogleFonts.notoSansDevanagari(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('किसी हिस्से पर टैप करें',
              style: GoogleFonts.notoSansDevanagari(
                  fontSize: 11, color: AppColors.textHint)),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 0,
                    startDegreeOffset: -90,
                    sections: _pieSections(rows, total),
                    pieTouchData: PieTouchData(
                      touchCallback: (event, resp) {
                        if (!event.isInterestedForInteractions ||
                            resp == null ||
                            resp.touchedSection == null) {
                          return;
                        }
                        final idx =
                            resp.touchedSection!.touchedSectionIndex;
                        if (idx >= 0 && idx < rows.length) {
                          setState(() => _poppedIndex = idx);
                        }
                      },
                    ),
                  ),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                ),
                IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(popped.key.name,
                          style: GoogleFonts.notoSansDevanagari(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      Text(popped.value.toString(),
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      Text('$poppedPct%',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _legend(rows, total),
        ],
      ),
    );
  }

  List<PieChartSectionData> _pieSections(
      List<MapEntry<KyvVillage, int>> rows, int total) {
    return List.generate(rows.length, (i) {
      final village = rows[i].key;
      final value = rows[i].value;
      final isPopped = i == _poppedIndex;
      final pct = total > 0 ? value / total * 100 : 0.0;
      return PieChartSectionData(
        value: value.toDouble(),
        color: _colorFor(village, i),
        radius: isPopped ? 104 : 88,
        showTitle: pct >= 8,
        title: '${pct.toStringAsFixed(0)}%',
        titleStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white),
        titlePositionPercentageOffset: 0.6,
      );
    });
  }

  Widget _barsCard(KyvMetric metric, List<MapEntry<KyvVillage, int>> rows) {
    final maxVal = rows.first.value;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('गाँवों की तुलना — ${metric.name}',
              style: GoogleFonts.notoSansDevanagari(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          ...List.generate(rows.length, (i) {
            final village = rows[i].key;
            final value = rows[i].value;
            final frac = maxVal > 0 ? value / maxVal : 0.0;
            final color = _colorFor(village, i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(village.name,
                            style: GoogleFonts.notoSansDevanagari(
                                fontSize: 12.5,
                                color: AppColors.textPrimary,
                                fontWeight: village.isHomeVillage
                                    ? FontWeight.w700
                                    : FontWeight.w400)),
                      ),
                      Text(value.toString(),
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: village.isHomeVillage
                                  ? FontWeight.w700
                                  : FontWeight.w400)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  LayoutBuilder(builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: frac),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => Container(
                            height: 10,
                            width: constraints.maxWidth * v,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _legend(List<MapEntry<KyvVillage, int>> rows, int total) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: List.generate(rows.length, (i) {
        final village = rows[i].key;
        final pct = total > 0 ? (rows[i].value / total * 100) : 0.0;
        return GestureDetector(
          onTap: () => setState(() => _poppedIndex = i),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: _colorFor(village, i),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Text('${village.name} ${pct.toStringAsFixed(0)}%',
                  style: GoogleFonts.notoSansDevanagari(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: village.isHomeVillage
                          ? FontWeight.w600
                          : FontWeight.w400)),
            ],
          ),
        );
      }),
    );
  }

  Widget _sourceLine(KyvMetric metric) {
    final src = _facts!.sourceLineFor(metric.id);
    if (src == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('स्रोत: $src',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textHint)),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('गाँव के आँकड़े जल्द आ रहे हैं',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansDevanagari(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text('जनसंख्या, वोटर और पंचायत तुलना',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansDevanagari(
                    fontSize: 12, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _noDataForMetric() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text('इस श्रेणी के लिए अभी आँकड़े नहीं हैं।',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansDevanagari(
              fontSize: 13, color: AppColors.textHint)),
    );
  }
}