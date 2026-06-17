// lib/features/kyv/models/kyv_facts_models.dart
// ─────────────────────────────────────────────────────────────
// Village Facts — data models.
// Parses the combined payload from GET /kyv/village-facts:
//   { villages: [...], metrics: [...], values: [...] }
// Loaded once; the dropdown switches metrics client-side (instant).
// ─────────────────────────────────────────────────────────────

class KyvVillage {
  final String id;
  final String name;
  final bool isHomeVillage;
  final int displayOrder;

  KyvVillage({
    required this.id,
    required this.name,
    required this.isHomeVillage,
    required this.displayOrder,
  });

  factory KyvVillage.fromJson(Map<String, dynamic> j) => KyvVillage(
        id: j['id'] as String,
        name: j['name'] as String,
        isHomeVillage: j['is_home_village'] as bool? ?? false,
        displayOrder: j['display_order'] as int? ?? 0,
      );
}

class KyvMetric {
  final String id;
  final String name;
  final String? unit;
  final int displayOrder;
  final bool isActive;

  KyvMetric({
    required this.id,
    required this.name,
    required this.unit,
    required this.displayOrder,
    required this.isActive,
  });

  factory KyvMetric.fromJson(Map<String, dynamic> j) => KyvMetric(
        id: j['id'] as String,
        name: j['name'] as String,
        unit: j['unit'] as String?,
        displayOrder: j['display_order'] as int? ?? 0,
        isActive: j['is_active'] as bool? ?? true,
      );
}

class KyvVillageValue {
  final String villageId;
  final String metricId;
  final int? value;
  final String? source;
  final String? asOfDate;

  KyvVillageValue({
    required this.villageId,
    required this.metricId,
    required this.value,
    required this.source,
    required this.asOfDate,
  });

  factory KyvVillageValue.fromJson(Map<String, dynamic> j) => KyvVillageValue(
        villageId: j['village_id'] as String,
        metricId: j['metric_id'] as String,
        value: j['value'] as int?,
        source: j['source'] as String?,
        asOfDate: j['as_of_date'] as String?,
      );
}

// ── The whole payload, plus helpers the charts need ──
class KyvVillageFacts {
  final List<KyvVillage> villages;
  final List<KyvMetric> metrics;
  final List<KyvVillageValue> values;

  KyvVillageFacts({
    required this.villages,
    required this.metrics,
    required this.values,
  });

  factory KyvVillageFacts.fromJson(Map<String, dynamic> j) => KyvVillageFacts(
        villages: (j['villages'] as List? ?? [])
            .map((e) => KyvVillage.fromJson(e as Map<String, dynamic>))
            .toList(),
        metrics: (j['metrics'] as List? ?? [])
            .map((e) => KyvMetric.fromJson(e as Map<String, dynamic>))
            .toList(),
        values: (j['values'] as List? ?? [])
            .map((e) => KyvVillageValue.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // Has the admin added anything yet?
  bool get isEmpty => villages.isEmpty || metrics.isEmpty;

  // The value for one village × metric, or null if not set.
  int? valueFor(String villageId, String metricId) {
    for (final v in values) {
      if (v.villageId == villageId && v.metricId == metricId) return v.value;
    }
    return null;
  }

  // Source/date line for a metric (takes the first value that has one).
  String? sourceLineFor(String metricId) {
    for (final v in values) {
      if (v.metricId == metricId && (v.source != null || v.asOfDate != null)) {
        final parts = <String>[];
        if (v.source != null) parts.add(v.source!);
        if (v.asOfDate != null) parts.add(v.asOfDate!);
        return parts.join(' · ');
      }
    }
    return null;
  }
}