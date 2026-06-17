// lib/features/kyv/screens/kyv_admin_create_screen.dart
// ─────────────────────────────────────────────────────────────
// Know Your Village — Admin: create a question (quiz or poll).
//
// Admin-only. Posting a new question auto-closes the previous
// active one (backend handles it). Quiz = mark one correct option;
// Poll = no correct answer.
//
// Fields:
//   - type toggle (Quiz / Poll)
//   - question text (Hindi, required) + optional English
//   - 2–4 options (add/remove); for quiz, tap to mark the correct one
//   - explanation (the civic/unity payload shown on reveal; optional)
//
// API: ApiService.createKyvQuestion()
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';

class KyvAdminCreateScreen extends StatefulWidget {
  const KyvAdminCreateScreen({super.key});

  @override
  State<KyvAdminCreateScreen> createState() => _KyvAdminCreateScreenState();
}

class _KyvAdminCreateScreenState extends State<KyvAdminCreateScreen> {

  // ─── Form state ──────────────────────────────────────────────
  String _type = 'quiz';                       // 'quiz' or 'poll'
  final _questionCtrl   = TextEditingController();
  final _questionEnCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();

  // Options: each has a controller + (for quiz) whether it's correct.
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  int? _correctIndex;                          // which option is correct (quiz)

  bool _submitting = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    _questionEnCtrl.dispose();
    _explanationCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Add / remove options (2–4) ──────────────────────────────
  void _addOption() {
    if (_optionCtrls.length >= 4) return;
    setState(() => _optionCtrls.add(TextEditingController()));
  }

  void _removeOption(int i) {
    if (_optionCtrls.length <= 2) return;
    setState(() {
      _optionCtrls[i].dispose();
      _optionCtrls.removeAt(i);
      // Fix up the correct index if needed
      if (_correctIndex != null) {
        if (_correctIndex == i) {
          _correctIndex = null;
        } else if (_correctIndex! > i) {
          _correctIndex = _correctIndex! - 1;
        }
      }
    });
  }

  // ─── Validate + submit ───────────────────────────────────────
  Future<void> _submit() async {
    final question = _questionCtrl.text.trim();
    final options = _optionCtrls.map((c) => c.text.trim()).toList();

    // — Validation —
    if (question.isEmpty) {
      _toast('सवाल लिखें');
      return;
    }
    if (options.any((o) => o.isEmpty)) {
      _toast('सभी options भरें');
      return;
    }
    if (_type == 'quiz' && _correctIndex == null) {
      _toast('सही जवाब चुनें (हरे टिक पर टैप करें)');
      return;
    }

    setState(() => _submitting = true);

    try {
      final optionsPayload = <Map<String, dynamic>>[];
      for (var i = 0; i < options.length; i++) {
        optionsPayload.add({
          'option_text': options[i],
          'is_correct': _type == 'quiz' && _correctIndex == i,
          'display_order': i,
        });
      }

      await ApiService.createKyvQuestion(
        questionText: question,
        questionTextEn: _questionEnCtrl.text.trim().isEmpty
            ? null
            : _questionEnCtrl.text.trim(),
        type: _type,
        explanation: _explanationCtrl.text.trim().isEmpty
            ? null
            : _explanationCtrl.text.trim(),
        options: optionsPayload,
      );

      if (!mounted) return;
      _toast('सवाल पोस्ट हो गया!', success: true);
      Navigator.of(context).pop(true);   // signal success to caller
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _toast(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.notoSansDevanagari()),
      backgroundColor: success ? AppColors.primary : AppColors.error,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('New Question',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Type toggle ──
              _label('Type'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _typeChip('quiz', 'Quiz', 'सही जवाब वाला'),
                  const SizedBox(width: 10),
                  _typeChip('poll', 'Poll', 'राय / opinion'),
                ],
              ),
              const SizedBox(height: 18),

              // ── Question ──
              _label('Question (हिंदी)'),
              const SizedBox(height: 6),
              _field(_questionCtrl, 'जैसे: दुर्बे गाँव में कितने वोटर हैं?',
                  maxLines: 2),
              const SizedBox(height: 12),

              _label('Question (English) — optional'),
              const SizedBox(height: 6),
              _field(_questionEnCtrl, 'e.g. How many voters does Durbe have?'),
              const SizedBox(height: 18),

              // ── Options ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _label(_type == 'quiz'
                      ? 'Options (हरे टिक से सही जवाब चुनें)'
                      : 'Options'),
                  if (_optionCtrls.length < 4)
                    GestureDetector(
                      onTap: _addOption,
                      child: Row(children: [
                        Icon(Icons.add, size: 16, color: AppColors.primary),
                        Text(' Add',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_optionCtrls.length, (i) => _optionRow(i)),
              const SizedBox(height: 18),

              // ── Explanation ──
              _label('Explanation / civic message — optional'),
              const SizedBox(height: 4),
              Text('जवाब दिखने के बाद यह संदेश आता है (एकता/जागरूकता)।',
                  style: GoogleFonts.notoSansDevanagari(
                      fontSize: 11, color: AppColors.textHint)),
              const SizedBox(height: 6),
              _field(_explanationCtrl,
                  'जैसे: दुर्बे घुठिया पंचायत का सबसे बड़ा गाँव है। एक साथ आएँ तो ताक़त हमारी।',
                  maxLines: 3),
              const SizedBox(height: 24),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Post Question',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
              Text('यह नया सवाल पुराने active सवाल को बंद कर देगा।',
                  style: GoogleFonts.notoSansDevanagari(
                      fontSize: 11, color: AppColors.textHint)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Type chip ───────────────────────────────────────────────
  Widget _typeChip(String value, String title, String sub) {
    final selected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = value;
          if (value == 'poll') _correctIndex = null;  // polls have no correct
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primary : AppColors.textPrimary)),
              Text(sub,
                  style: GoogleFonts.notoSansDevanagari(
                      fontSize: 11, color: AppColors.textHint)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Option row (text + correct-toggle for quiz + remove) ────
  Widget _optionRow(int i) {
    final isCorrect = _correctIndex == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Correct-answer toggle (quiz only)
          if (_type == 'quiz')
            GestureDetector(
              onTap: () => setState(() => _correctIndex = i),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isCorrect ? AppColors.primary : AppColors.cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isCorrect ? AppColors.primary : AppColors.border),
                ),
                child: Icon(Icons.check,
                    size: 16,
                    color: isCorrect ? Colors.white : AppColors.textHint),
              ),
            ),
          Expanded(
            child: TextField(
              controller: _optionCtrls[i],
              style: GoogleFonts.notoSansDevanagari(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Option ${i + 1}',
                hintStyle: GoogleFonts.notoSansDevanagari(
                    fontSize: 14, color: AppColors.textHint),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ),
          // Remove (only if more than 2)
          if (_optionCtrls.length > 2)
            GestureDetector(
              onTap: () => _removeOption(i),
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.close, size: 18, color: AppColors.textHint),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────
  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));

  Widget _field(TextEditingController c, String hint, {int maxLines = 1}) =>
      TextField(
        controller: c,
        maxLines: maxLines,
        style: GoogleFonts.notoSansDevanagari(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.notoSansDevanagari(
              fontSize: 13, color: AppColors.textHint),
        ),
      );
}