// lib/features/kyv/models/kyv_models.dart
// ─────────────────────────────────────────────────────────────
// Data models for Know Your Village (quiz + poll).
// Parse the JSON shapes returned by /kyv/* endpoints.
// ─────────────────────────────────────────────────────────────

// ── An option as shown BEFORE answering (no is_correct leak) ──
class KyvOptionPublic {
  final String id;
  final String optionText;
  final int displayOrder;

  KyvOptionPublic({
    required this.id,
    required this.optionText,
    required this.displayOrder,
  });

  factory KyvOptionPublic.fromJson(Map<String, dynamic> j) => KyvOptionPublic(
        id: j['id'] as String,
        optionText: j['option_text'] as String,
        displayOrder: j['display_order'] as int? ?? 0,
      );
}

// ── An option WITH results — after answering / in history ──
class KyvOptionResult {
  final String id;
  final String optionText;
  final int displayOrder;
  final bool isCorrect;
  final int voteCount;
  final double percentage;

  KyvOptionResult({
    required this.id,
    required this.optionText,
    required this.displayOrder,
    required this.isCorrect,
    required this.voteCount,
    required this.percentage,
  });

  factory KyvOptionResult.fromJson(Map<String, dynamic> j) => KyvOptionResult(
        id: j['id'] as String,
        optionText: j['option_text'] as String,
        displayOrder: j['display_order'] as int? ?? 0,
        isCorrect: j['is_correct'] as bool? ?? false,
        voteCount: j['vote_count'] as int? ?? 0,
        percentage: (j['percentage'] as num?)?.toDouble() ?? 0.0,
      );
}

// ── The live/active question (from GET /kyv/active) ──
class KyvActiveQuestion {
  final String id;
  final String questionText;
  final String? questionTextEn;
  final String type;                 // "quiz" or "poll"
  final String? explanation;         // only present after answering
  final int totalAnswers;
  final bool hasAnswered;
  final String? myOptionId;          // what the user picked, if answered
  final List<KyvOptionPublic>? optionsPublic;   // before answering
  final List<KyvOptionResult>? optionsResult;   // after answering

  KyvActiveQuestion({
    required this.id,
    required this.questionText,
    required this.questionTextEn,
    required this.type,
    required this.explanation,
    required this.totalAnswers,
    required this.hasAnswered,
    required this.myOptionId,
    required this.optionsPublic,
    required this.optionsResult,
  });

  bool get isQuiz => type == 'quiz';

  factory KyvActiveQuestion.fromJson(Map<String, dynamic> j) => KyvActiveQuestion(
        id: j['id'] as String,
        questionText: j['question_text'] as String,
        questionTextEn: j['question_text_en'] as String?,
        type: j['type'] as String? ?? 'quiz',
        explanation: j['explanation'] as String?,
        totalAnswers: j['total_answers'] as int? ?? 0,
        hasAnswered: j['has_answered'] as bool? ?? false,
        myOptionId: j['my_option_id'] as String?,
        optionsPublic: (j['options_public'] as List?)
            ?.map((e) => KyvOptionPublic.fromJson(e as Map<String, dynamic>))
            .toList(),
        optionsResult: (j['options_result'] as List?)
            ?.map((e) => KyvOptionResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── A past question (from GET /kyv/history) ──
class KyvHistoryQuestion {
  final String id;
  final String questionText;
  final String? questionTextEn;
  final String type;
  final String? explanation;
  final int totalAnswers;
  final List<KyvOptionResult> optionsResult;
  final DateTime? createdAt;

  KyvHistoryQuestion({
    required this.id,
    required this.questionText,
    required this.questionTextEn,
    required this.type,
    required this.explanation,
    required this.totalAnswers,
    required this.optionsResult,
    this.createdAt,
  });

  bool get isQuiz => type == 'quiz';

  factory KyvHistoryQuestion.fromJson(Map<String, dynamic> j) => KyvHistoryQuestion(
        id: j['id'] as String,
        questionText: j['question_text'] as String,
        questionTextEn: j['question_text_en'] as String?,
        type: j['type'] as String? ?? 'quiz',
        explanation: j['explanation'] as String?,
        totalAnswers: j['total_answers'] as int? ?? 0,
        optionsResult: (j['options_result'] as List? ?? [])
            .map((e) => KyvOptionResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );
}

// ── The reveal payload (from POST /kyv/{id}/answer) ──
class KyvAnswerResult {
  final bool correct;
  final String? correctOptionId;
  final String? explanation;
  final int totalAnswers;
  final List<KyvOptionResult> optionsResult;
  final int myAnsweredCount;
  final int myPoints;

  KyvAnswerResult({
    required this.correct,
    required this.correctOptionId,
    required this.explanation,
    required this.totalAnswers,
    required this.optionsResult,
    required this.myAnsweredCount,
    required this.myPoints,
  });

  factory KyvAnswerResult.fromJson(Map<String, dynamic> j) => KyvAnswerResult(
        correct: j['correct'] as bool? ?? false,
        correctOptionId: j['correct_option_id'] as String?,
        explanation: j['explanation'] as String?,
        totalAnswers: j['total_answers'] as int? ?? 0,
        optionsResult: (j['options_result'] as List? ?? [])
            .map((e) => KyvOptionResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        myAnsweredCount: j['my_answered_count'] as int? ?? 0,
        myPoints: j['my_points'] as int? ?? 0,
      );
}

// ── User stats (from GET /kyv/me) ──
class KyvMeStats {
  final int answeredCount;
  final int points;

  KyvMeStats({required this.answeredCount, required this.points});

  factory KyvMeStats.fromJson(Map<String, dynamic> j) => KyvMeStats(
        answeredCount: j['answered_count'] as int? ?? 0,
        points: j['points'] as int? ?? 0,
      );
}