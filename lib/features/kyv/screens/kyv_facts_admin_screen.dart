// lib/features/kyv/screens/kyv_facts_admin_screen.dart
// ─────────────────────────────────────────────────────────────
// Village Facts — super_admin management.
//
// Three tabs:
//   गाँव    → add / delete panchayat villages (mark Durbe as home)
//   श्रेणी   → add / delete metrics (the dropdown categories)
//   आँकड़े  → pick a metric → enter each village's value + source/date
//
// All writes are super_admin only (backend enforces).
// On any change we reload so the next screen open is fresh.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import '../models/kyv_facts_models.dart';

class KyvFactsAdminScreen extends StatefulWidget {
  const KyvFactsAdminScreen({super.key});

  @override
  State<KyvFactsAdminScreen> createState() => _KyvFactsAdminScreenState();
}

class _KyvFactsAdminScreenState extends State<KyvFactsAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  KyvVillageFacts? _facts;
  bool _changed = false;   // tell the previous screen to refresh on pop

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final json = await ApiService.getKyvVillageFacts();
      if (!mounted) return;
      setState(() {
        _facts = KyvVillageFacts.fromJson(json);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.notoSansDevanagari()),
      backgroundColor: error ? AppColors.error : AppColors.primary,
    ));
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          title: Text('गाँव के आँकड़े — संपादन',
              style: GoogleFonts.notoSansDevanagari(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.primary,
            labelStyle: GoogleFonts.notoSansDevanagari(
                fontSize: 14, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'गाँव'),
              Tab(text: 'श्रेणी'),
              Tab(text: 'आँकड़े'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _villagesTab(),
                  _metricsTab(),
                  _valuesTab(),
                ],
              ),
      ),
    );
  }

  // ─── Tab 1: Villages ─────────────────────────────────────────
  Widget _villagesTab() {
    final villages = _facts?.villages ?? [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _addButton('गाँव जोड़ें', _addVillageDialog),
        const SizedBox(height: 12),
        if (villages.isEmpty)
          _emptyHint('अभी कोई गाँव नहीं जोड़ा गया।')
        else
          ...villages.map((v) => _rowCard(
                title: v.name,
                subtitle: v.isHomeVillage ? 'अपना गाँव (दुर्बे)' : null,
                onDelete: () => _deleteVillage(v),
              )),
      ],
    );
  }

  Future<void> _addVillageDialog() async {
    final nameCtrl = TextEditingController();
    bool isHome = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('गाँव जोड़ें',
              style: GoogleFonts.notoSansDevanagari(
                  fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.notoSansDevanagari(),
                decoration: InputDecoration(
                  hintText: 'गाँव का नाम',
                  hintStyle: GoogleFonts.notoSansDevanagari(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: isHome,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setLocal(() => isHome = v ?? false),
                  ),
                  Expanded(
                    child: Text('यह अपना गाँव है (दुर्बे)',
                        style: GoogleFonts.notoSansDevanagari(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('रद्द',
                  style: GoogleFonts.notoSansDevanagari(
                      color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('जोड़ें',
                  style: GoogleFonts.notoSansDevanagari(
                      color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    try {
      await ApiService.createKyvVillage(
        name: nameCtrl.text.trim(),
        isHomeVillage: isHome,
        displayOrder: (_facts?.villages.length ?? 0),
      );
      _changed = true;
      await _load();
      _toast('गाँव जुड़ गया');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _deleteVillage(KyvVillage v) async {
    final ok = await _confirmDelete(
        'गाँव हटाएँ?', '${v.name} और इसके सभी आँकड़े हट जाएँगे।');
    if (!ok) return;
    try {
      await ApiService.deleteKyvVillage(v.id);
      _changed = true;
      await _load();
      _toast('गाँव हट गया');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  // ─── Tab 2: Metrics ──────────────────────────────────────────
  Widget _metricsTab() {
    final metrics = _facts?.metrics ?? [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _addButton('श्रेणी जोड़ें', _addMetricDialog),
        const SizedBox(height: 12),
        if (metrics.isEmpty)
          _emptyHint('अभी कोई श्रेणी नहीं। जैसे: जनसंख्या, वोटर, युवा।')
        else
          ...metrics.map((m) => _rowCard(
                title: m.name,
                subtitle: m.unit,
                onDelete: () => _deleteMetric(m),
              )),
      ],
    );
  }

  Future<void> _addMetricDialog() async {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('श्रेणी जोड़ें',
            style: GoogleFonts.notoSansDevanagari(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.notoSansDevanagari(),
              decoration: InputDecoration(
                hintText: 'श्रेणी का नाम (जैसे: वोटर)',
                hintStyle: GoogleFonts.notoSansDevanagari(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: unitCtrl,
              style: GoogleFonts.notoSansDevanagari(),
              decoration: InputDecoration(
                hintText: 'इकाई — वैकल्पिक (जैसे: लोग, %)',
                hintStyle: GoogleFonts.notoSansDevanagari(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('रद्द',
                style: GoogleFonts.notoSansDevanagari(
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('जोड़ें',
                style: GoogleFonts.notoSansDevanagari(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    try {
      await ApiService.createKyvMetric(
        name: nameCtrl.text.trim(),
        unit: unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim(),
        displayOrder: (_facts?.metrics.length ?? 0),
      );
      _changed = true;
      await _load();
      _toast('श्रेणी जुड़ गई');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _deleteMetric(KyvMetric m) async {
    final ok = await _confirmDelete(
        'श्रेणी हटाएँ?', '${m.name} और इसके सभी आँकड़े हट जाएँगे।');
    if (!ok) return;
    try {
      await ApiService.deleteKyvMetric(m.id);
      _changed = true;
      await _load();
      _toast('श्रेणी हट गई');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  // ─── Tab 3: Values ───────────────────────────────────────────
  Widget _valuesTab() {
    final f = _facts;
    if (f == null) return const SizedBox.shrink();
    if (f.metrics.isEmpty || f.villages.isEmpty) {
      return _emptyHint('पहले गाँव और श्रेणी जोड़ें, फिर यहाँ आँकड़े भरें।');
    }
    return _ValuesEditor(
      facts: f,
      onSaved: () {
        _changed = true;
        _load();
      },
      onToast: _toast,
    );
  }

  // ─── Shared widgets ──────────────────────────────────────────
  Widget _addButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.notoSansDevanagari(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _rowCard({required String title, String? subtitle, required VoidCallback onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.notoSansDevanagari(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(subtitle,
                      style: GoogleFonts.notoSansDevanagari(
                          fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Text(text,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansDevanagari(
              fontSize: 13, color: AppColors.textHint, height: 1.6)),
    );
  }

  Future<bool> _confirmDelete(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title,
            style: GoogleFonts.notoSansDevanagari(fontWeight: FontWeight.w600)),
        content: Text(body, style: GoogleFonts.notoSansDevanagari(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('रद्द',
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
    return ok ?? false;
  }
}

// ─────────────────────────────────────────────────────────────
// Values editor — pick a metric, type each village's value.
// ─────────────────────────────────────────────────────────────

class _ValuesEditor extends StatefulWidget {
  final KyvVillageFacts facts;
  final VoidCallback onSaved;
  final void Function(String, {bool error}) onToast;

  const _ValuesEditor({
    required this.facts,
    required this.onSaved,
    required this.onToast,
  });

  @override
  State<_ValuesEditor> createState() => _ValuesEditorState();
}

class _ValuesEditorState extends State<_ValuesEditor> {
  late String _metricId;
  final Map<String, TextEditingController> _ctrls = {};
  final TextEditingController _sourceCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _metricId = widget.facts.metrics.first.id;
    _seedControllers();
  }

  void _seedControllers() {
    for (final v in widget.facts.villages) {
      final existing = widget.facts.valueFor(v.id, _metricId);
      _ctrls[v.id] = TextEditingController(
          text: existing != null ? existing.toString() : '');
    }
    final line = widget.facts.sourceLineFor(_metricId);
    if (line != null) {
      final parts = line.split(' · ');
      if (parts.isNotEmpty) _sourceCtrl.text = parts[0];
      if (parts.length > 1) _dateCtrl.text = parts[1];
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _sourceCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  void _onMetricChange(String id) {
    setState(() {
      _metricId = id;
      _sourceCtrl.clear();
      _dateCtrl.clear();
      for (final c in _ctrls.values) {
        c.dispose();
      }
      _ctrls.clear();
      _seedControllers();
    });
  }

  Future<void> _saveAll() async {
    if (_saving) return;
    setState(() => _saving = true);
    final src = _sourceCtrl.text.trim().isEmpty ? null : _sourceCtrl.text.trim();
    final date = _dateCtrl.text.trim().isEmpty ? null : _dateCtrl.text.trim();
    try {
      for (final v in widget.facts.villages) {
        final raw = _ctrls[v.id]!.text.trim();
        if (raw.isEmpty) continue;
        final parsed = int.tryParse(raw);
        if (parsed == null) continue;
        await ApiService.upsertKyvVillageValue(
          villageId: v.id,
          metricId: _metricId,
          value: parsed,
          source: src,
          asOfDate: date,
        );
      }
      widget.onToast('आँकड़े सेव हो गए');
      widget.onSaved();
    } catch (e) {
      widget.onToast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.facts;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Text('श्रेणी:',
                  style: GoogleFonts.notoSansDevanagari(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _metricId,
                    isExpanded: true,
                    items: f.metrics
                        .map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.name,
                                  style: GoogleFonts.notoSansDevanagari(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ))
                        .toList(),
                    onChanged: (id) {
                      if (id != null) _onMetricChange(id);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...f.villages.map((v) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(v.name,
                        style: GoogleFonts.notoSansDevanagari(
                            fontSize: 14,
                            fontWeight: v.isHomeVillage
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: AppColors.textPrimary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _ctrls[v.id],
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '—',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 8),
        TextField(
          controller: _sourceCtrl,
          style: GoogleFonts.notoSansDevanagari(fontSize: 13),
          decoration: InputDecoration(
            labelText: 'स्रोत (जैसे: ECI 2024)',
            labelStyle: GoogleFonts.notoSansDevanagari(fontSize: 12),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _dateCtrl,
          style: GoogleFonts.notoSansDevanagari(fontSize: 13),
          decoration: InputDecoration(
            labelText: 'तारीख़ (जैसे: जून 2026)',
            labelStyle: GoogleFonts.notoSansDevanagari(fontSize: 12),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: _saving ? null : _saveAll,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _saving ? AppColors.textHint : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('सभी आँकड़े सेव करें',
                    style: GoogleFonts.notoSansDevanagari(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
          ),
        ),
      ],
    );
  }
}