// lib/features/kyv/widgets/kyv_home_card.dart
// ─────────────────────────────────────────────────────────────
// Know Your Village — Home invitation card.
//
// Self-contained widget that drops onto the Home tab between the
// carousel and the Features grid. Handles the FULL in-place flow:
//
//   loading            → renders nothing (no flicker)
//   no active question → renders nothing (clean home — Raushan's rule)
//   unanswered         → full invitation card with tappable options
//   answering          → option shows brief spinner
//   revealed           → correct/wrong + explanation + result bars + stats
//   already answered   → collapses to a thin result strip on load
//
// Invitation, NOT interruption: never blocks, user can scroll past.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import '../models/kyv_models.dart';
import '../screens/kyv_hub_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KyvHomeCard extends StatefulWidget {
  const KyvHomeCard({super.key});

  @override
  State<KyvHomeCard> createState() => _KyvHomeCardState();
}

class _KyvHomeCardState extends State<KyvHomeCard> {

  // ─── State ───────────────────────────────────────────────────
  bool _loading = true;
  KyvActiveQuestion? _question;          // null = no active question
  String? _selectedOptionId;             // option being submitted / chosen
  bool _submitting = false;
  KyvAnswerResult? _result;              // populated after a fresh answer
  String? _inlineError;                  // e.g. 403 not-verified message
  String? _dismissedId;                  // ✅ ADD: question id the user hid from home
  bool _collapsedReveal = false;         // ✅ ADD: user tapped ✕ on the reveal → show thin strip

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getString('kyv_dismissed_id');
      final json = await ApiService.getKyvActive();
      if (!mounted) return;
      setState(() {
        _dismissedId = dismissed;
        _question = json == null ? null : KyvActiveQuestion.fromJson(json);
        _loading = false;
      });
    } catch (_) {
      // KYV is non-critical on home — fail silently to nothing
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ ADD: hide this answered question from home (until a new one is posted)
  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kyv_dismissed_id', _question!.id);
    if (!mounted) return;
    setState(() => _dismissedId = _question!.id);
  }

  // ─── Submit an answer ────────────────────────────────────────
  Future<void> _submit(String optionId) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _selectedOptionId = optionId;
      _inlineError = null;
    });
    try {
      final json = await ApiService.answerKyvQuestion(
        questionId: _question!.id,
        optionId: optionId,
      );
      if (!mounted) return;
      setState(() {
        _result = KyvAnswerResult.fromJson(json);
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Backend is authoritative (e.g. 403 not verified, already answered)
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _submitting = false;
        _selectedOptionId = null;
        _inlineError = msg;
      });
    }
  }

  void _openHub() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KyvHubScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // No flicker while loading; nothing when there's no question.
    if (_loading || _question == null) return const SizedBox.shrink();

    final q = _question!;

    // User dismissed THIS question from home → render nothing.
    // (A newly posted question has a different id, so it reappears.)
    if (_dismissedId != null && _dismissedId == q.id) {
      return const SizedBox.shrink();
    }

    // Already answered (on load) OR just answered → result state.
    final answered = q.hasAnswered || _result != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: answered ? _buildAnsweredStrip(q) : _buildUnanswered(q),
      ),
    );
  }

  // ─── Unanswered: full invitation card ────────────────────────
  Widget _buildUnanswered(KyvActiveQuestion q) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: NEW + type + hub link ──
          Row(
            children: [
              _pill(q.isQuiz ? 'NEW' : 'POLL',
                  bg: AppColors.primary, fg: Colors.white, bold: true),
              const SizedBox(width: 8),
              Text('Know Your Village',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.primary)),
              const Spacer(),
              GestureDetector(
                onTap: _openHub,
                child: Icon(Icons.history,
                    size: 18, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Question (Hindi primary, English sub) ──
          Text(q.questionText,
              style: GoogleFonts.notoSansDevanagari(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.4)),
          if (q.questionTextEn != null) ...[
            const SizedBox(height: 3),
            Text(q.questionTextEn!,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 14),

          // ── Options ──
          ...?q.optionsPublic?.map((o) => _optionButton(o)),

          // ── Inline error (e.g. not verified) ──
          if (_inlineError != null) ...[
            const SizedBox(height: 8),
            Text(_inlineError!,
                style: GoogleFonts.notoSansDevanagari(
                    fontSize: 12, color: AppColors.error)),
          ],
        ],
      ),
    );
  }

  Widget _optionButton(KyvOptionPublic o) {
    final isThisSubmitting = _submitting && _selectedOptionId == o.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GestureDetector(
        onTap: _submitting ? null : () => _submit(o.id),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(o.optionText,
                    style: GoogleFonts.notoSansDevanagari(
                        fontSize: 14, color: AppColors.textPrimary)),
              ),
              if (isThisSubmitting)
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Answered: reveal (fresh) OR thin strip (on load) ────────
  Widget _buildAnsweredStrip(KyvActiveQuestion q) {
    // If we have a fresh result (just answered) AND user hasn't collapsed it,
    // show the rich reveal. Once collapsed, fall through to the thin strip.
    if (_result != null && !_collapsedReveal) return _buildReveal(q, _result!);

    // Otherwise (answered in a previous session) — thin teaser strip.
    final results = q.optionsResult ?? [];
    final myPct = results
        .firstWhere(
          (r) => r.id == q.myOptionId,
          orElse: () => KyvOptionResult(
              id: '', optionText: '', displayOrder: 0,
              isCorrect: false, voteCount: 0, percentage: 0),
        )
        .percentage;

    return GestureDetector(
      onTap: _openHub,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                q.isQuiz
                    ? 'You answered · ${q.totalAnswers} villagers played'
                    : 'You voted · ${myPct.toStringAsFixed(0)}% agreed · ${q.totalAnswers} voted',
                style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Text('देखें →',
                  style: GoogleFonts.notoSansDevanagari(
                      fontSize: 12, color: AppColors.primary)),
              // ✅ ADD: dismiss this answered question from home
              GestureDetector(
                onTap: _dismiss,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Icon(Icons.close, size: 16, color: AppColors.textHint),
                ),
              ),
            ],
        ),
      ),
    );
  }

  // ─── Full reveal after answering ─────────────────────────────
  Widget _buildReveal(KyvActiveQuestion q, KyvAnswerResult r) {
    final correct = r.correct;
    final headline = q.isQuiz
        ? (correct ? 'सही! +10 अंक' : 'सही जवाब नीचे देखें')
        : 'आपका जवाब दर्ज हुआ';
    final headlineColor = q.isQuiz
        ? (correct ? AppColors.primary : AppColors.error)
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question (kept for context) + collapse ✕
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(q.questionText,
                      style: GoogleFonts.notoSansDevanagari(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.4)),
                ),
                GestureDetector(
                  onTap: () => setState(() => _collapsedReveal = true),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.close, size: 18, color: AppColors.textHint),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // Headline
          Row(
            children: [
              Icon(
                q.isQuiz
                    ? (correct ? Icons.celebration : Icons.lightbulb_outline)
                    : Icons.how_to_vote,
                size: 18, color: headlineColor,
              ),
              const SizedBox(width: 6),
              Text(headline,
                  style: GoogleFonts.notoSansDevanagari(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: headlineColor)),
            ],
          ),

          // Civic / unity payload
          if (r.explanation != null) ...[
            const SizedBox(height: 8),
            Text(r.explanation!,
                style: GoogleFonts.notoSansDevanagari(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.55)),
          ],
          const SizedBox(height: 16),

          // "What the village chose"
          Text('गाँव के ${r.totalAnswers} लोगों ने क्या चुना:',
              style: GoogleFonts.notoSansDevanagari(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          ...r.optionsResult.map((o) => _resultBar(o, q)),

          const SizedBox(height: 14),

          // Actions: hub + share
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _openHub,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('और देखें →',
                        style: GoogleFonts.notoSansDevanagari(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  // share_plus not yet added — Phase D wires real sharing
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Share जल्द आ रहा है',
                        style: GoogleFonts.notoSansDevanagari()),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 2),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Icon(Icons.share_outlined,
                      size: 18, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── A single result bar ─────────────────────────────────────
  Widget _resultBar(KyvOptionResult o, KyvActiveQuestion q) {
    // Highlight the correct option (quiz) in green; others muted.
    final isHighlight = q.isQuiz && o.isCorrect;
    final barColor = isHighlight ? AppColors.primary : AppColors.textHint;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
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
                        fontWeight: isHighlight
                            ? FontWeight.w600
                            : FontWeight.w400)),
              ),
              const SizedBox(width: 8),
              Text('${o.percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
              if (isHighlight) ...[
                const SizedBox(width: 4),
                Icon(Icons.check, size: 14, color: AppColors.primary),
              ],
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: o.percentage / 100.0,
              minHeight: 8,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Small pill ──────────────────────────────────────────────
  Widget _pill(String text,
      {required Color bg, required Color fg, bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.5,
              color: fg)),
    );
  }
}