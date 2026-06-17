// lib/features/kyv/screens/kyv_hub_screen.dart
// ─────────────────────────────────────────────────────────────
// Know Your Village — the hub (opened from the home card or nav).
//
// Two tabs:
//   History       → past questions & polls with full result bars
//   Village Facts → demographics + Ghuthiya panchayat comparison
//                   (placeholder for now — built as a second step)
//
// API used:
//   ApiService.getKyvHistory() → GET /kyv/history
//   ApiService.getKyvMe()      → GET /kyv/me (stats in the header)
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import '../models/kyv_models.dart';
import 'package:shared_preferences/shared_preferences.dart';                  // ✅ ADD
import 'kyv_admin_create_screen.dart';                                        // ✅ ADD
import '../widgets/kyv_village_facts_tab.dart';                               // ✅ ADD

class KyvHubScreen extends StatefulWidget {
  const KyvHubScreen({super.key});

  @override
  State<KyvHubScreen> createState() => _KyvHubScreenState();
}

class _KyvHubScreenState extends State<KyvHubScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  // ─── State ───────────────────────────────────────────────────
  List<KyvHistoryQuestion> _history = [];
  bool _historyLoading = true;
  String? _historyError;

  KyvMeStats? _stats;
  String? _userRole;                                                          // ✅ ADD

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);                                // ✅ ADD
    _loadHistory();
    _loadStats();
    _loadUserRole();                                                          // ✅ ADD
  }

  Future<void> _loadUserRole() async {                                        // ✅ ADD
    final prefs = await SharedPreferences.getInstance();                      // ✅ ADD
    if (mounted) setState(() => _userRole = prefs.getString('user_role'));    // ✅ ADD
  }                                                                           // ✅ ADD

  void _onTabChanged() {                                                      // ✅ ADD
    // Rebuild so the FAB shows only on the History tab.
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);                             // ✅ ADD
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final list = await ApiService.getKyvHistory();
      if (!mounted) return;
      setState(() {
        _history = list
            .map((e) => KyvHistoryQuestion.fromJson(e as Map<String, dynamic>))
            .toList();
        _historyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = 'इतिहास लोड नहीं हो सका';
        _historyLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final json = await ApiService.getKyvMe();
      if (!mounted) return;
      setState(() => _stats = KyvMeStats.fromJson(json));
    } catch (_) {
      // stats optional in header — ignore failure
    }
  }

  // ─── Delete a question (super admin) ─────────────────────────  // ✅ ADD
  Future<void> _deleteQuestion(KyvHistoryQuestion q) async {
    // Confirm first — deletion is permanent from the user's view.
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('सवाल हटाएँ?',
            style: GoogleFonts.notoSansDevanagari(fontWeight: FontWeight.w600)),
        content: Text('यह सवाल हमेशा के लिए हट जाएगा।',
            style: GoogleFonts.notoSansDevanagari(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('रद्द करें',
                style: GoogleFonts.notoSansDevanagari(
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('हटाएँ',
                style: GoogleFonts.notoSansDevanagari(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.deleteKyvQuestion(q.id);
      if (!mounted) return;
      _loadHistory();   // refresh the list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.notoSansDevanagari()),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = _userRole == 'super_admin';                          // ✅ CHANGE
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: (isSuperAdmin && _tabController.index == 0)      // ✅ CHANGE
          ? FloatingActionButton.extended(                                    // ✅ ADD
              onPressed: () async {                                           // ✅ ADD
                final posted = await Navigator.of(context).push<bool>(        // ✅ ADD
                  MaterialPageRoute(                                          // ✅ ADD
                      builder: (_) => const KyvAdminCreateScreen()),          // ✅ ADD
                );                                                            // ✅ ADD
                if (posted == true) {                                         // ✅ ADD
                  _loadHistory();                                             // ✅ ADD
                  _loadStats();                                               // ✅ ADD
                }                                                             // ✅ ADD
              },                                                              // ✅ ADD
              backgroundColor: AppColors.primary,                            // ✅ ADD
              icon: const Icon(Icons.add, color: Colors.white),              // ✅ ADD
              label: Text('New Question',                                    // ✅ ADD
                  style: GoogleFonts.inter(                                  // ✅ ADD
                      fontSize: 14, fontWeight: FontWeight.w600,             // ✅ ADD
                      color: Colors.white)),                                 // ✅ ADD
            )                                                                 // ✅ ADD
          : null,                                                            // ✅ ADD
      appBar: AppBar(
        title: Text('Know Your Village',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Village Facts'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_stats != null) _statsHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _historyTab(),
                _villageFactsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats header (answered + points) ────────────────────────
  Widget _statsHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.local_fire_department,
              size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text('${_stats!.answeredCount} answered',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Text('${_stats!.points} अंक',
              style: GoogleFonts.notoSansDevanagari(
                  fontSize: 13, color: AppColors.primaryMid)),
        ],
      ),
    );
  }

  // ─── History tab ─────────────────────────────────────────────
  Widget _historyTab() {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historyError != null) {
      return Center(
        child: Text(_historyError!,
            style: GoogleFonts.notoSansDevanagari(
                color: AppColors.textSecondary)),
      );
    }
    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'अभी तक कोई पुराना सवाल नहीं।\nनया सवाल आने पर यहाँ दिखेगा।',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansDevanagari(
                fontSize: 14, color: AppColors.textHint, height: 1.6),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _history.length,
      itemBuilder: (_, i) => _historyCard(_history[i]),
    );
  }

  Widget _historyCard(KyvHistoryQuestion q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              children: [
                _typeTag(q.isQuiz),
                const SizedBox(width: 8),
                // Date — so old polls are dated (e.g. "15 Jun 2026")   // ✅ ADD
                Text(_formatDate(q.createdAt),                          // ✅ ADD
                    style: GoogleFonts.inter(                           // ✅ ADD
                        fontSize: 11, color: AppColors.textHint)),      // ✅ ADD
                const Spacer(),
                Text('${q.totalAnswers} ${q.isQuiz ? "answered" : "voted"}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textHint)),
                // Delete (super admin only)                            // ✅ ADD
                if (_userRole == 'super_admin') ...[                    // ✅ ADD
                  const SizedBox(width: 8),                             // ✅ ADD
                  GestureDetector(                                      // ✅ ADD
                    onTap: () => _deleteQuestion(q),                    // ✅ ADD
                    behavior: HitTestBehavior.opaque,                   // ✅ ADD
                    child: Icon(Icons.delete_outline,                   // ✅ ADD
                        size: 18, color: AppColors.error),              // ✅ ADD
                  ),                                                    // ✅ ADD
                ],                                                      // ✅ ADD
              ],
            ),
          const SizedBox(height: 8),
          Text(q.questionText,
              style: GoogleFonts.notoSansDevanagari(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.4)),
          const SizedBox(height: 12),
          ...q.optionsResult.map((o) => _historyBar(o, q.isQuiz)),
          if (q.explanation != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(q.explanation!,
                  style: GoogleFonts.notoSansDevanagari(
                      fontSize: 12.5,
                      color: AppColors.primaryDark,
                      height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _historyBar(KyvOptionResult o, bool isQuiz) {
    final isHighlight = isQuiz && o.isCorrect;
    final barColor = isHighlight ? AppColors.primary : AppColors.textHint;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(o.optionText,
                    style: GoogleFonts.notoSansDevanagari(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        fontWeight:
                            isHighlight ? FontWeight.w600 : FontWeight.w400)),
              ),
              const SizedBox(width: 8),
              Text('${o.percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                      fontSize: 11.5, color: AppColors.textSecondary)),
              if (isHighlight) ...[
                const SizedBox(width: 4),
                Icon(Icons.check, size: 13, color: AppColors.primary),
              ],
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: o.percentage / 100.0,
              minHeight: 7,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeTag(bool isQuiz) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isQuiz ? AppColors.primaryMid : AppColors.ctaLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(isQuiz ? 'QUIZ' : 'POLL',
          style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isQuiz ? AppColors.primary : AppColors.cta)),
    );
  }

  // ─── Village Facts tab ───────────────────────────────────────
  Widget _villageFactsTab() {
    return const KyvVillageFactsTab();
  }

  //─── Format a date for history cards ─────────────────────────  // ✅ ADD
  String _formatDate(DateTime? d) {
    if (d == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}