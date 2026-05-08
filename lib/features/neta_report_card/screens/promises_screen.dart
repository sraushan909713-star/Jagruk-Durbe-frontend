// ─────────────────────────────────────────────────────────────────────────────
// FILE — lib/features/neta_report_card/screens/promises_screen.dart  ✅ NEW
//
// Neta ke Vaade — Promises tracker
// Accessible via top-right button on Neta Report Card screen.
// Shows all promises made by leaders with witness count.
// Durbe Niwasi can tap to confirm they witnessed a promise.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import 'promise_detail_screen.dart';

// ─── Promises Screen ──────────────────────────────────────────────────────────
class PromisesScreen extends StatefulWidget {
  const PromisesScreen({super.key});

  @override
  State<PromisesScreen> createState() => _PromisesScreenState();
}

class _PromisesScreenState extends State<PromisesScreen> {

  // ─── State ──────────────────────────────────────────────────────────────────
  List<dynamic> _promises    = [];
  bool          _loading     = true;
  String?       _error;
  String        _filter      = 'All';
  String?       _userBadge;
  String?       _userRole;

  final List<String> _filters = ['All', 'Pending', 'Fulfilled', 'Half Delivered', 'Broken'];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadPromises();
  }

  // ─── Load user badge/role from SharedPreferences ─────────────────────────────
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() {
      _userBadge = prefs.getString('badge');
      _userRole  = prefs.getString('user_role');
    });
  }

  // ─── Load Promises ───────────────────────────────────────────────────────────
  Future<void> _loadPromises() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getPromises();
      if (mounted) setState(() { _promises = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ─── Filtered list ───────────────────────────────────────────────────────────
  List<dynamic> get _filtered {
    if (_filter == 'All') return _promises;
    final map = {
      'Pending':       'pending',
      'Fulfilled':     'fulfilled',
      'Half Delivered':'half_delivered',
      'Broken':        'broken',
    };
    return _promises.where((p) => p['status'] == map[_filter]).toList();
  }

  // ─── Witness a promise ───────────────────────────────────────────────────────
  Future<void> _handleWitness(String promiseId, String leaderName) async {
    // Warn user — irreversible action
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Witness',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are confirming that you personally witnessed '
                      'this promise by $leaderName. '
                      'This action cannot be undone.',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes, I Witnessed',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.witnessPromise(promiseId);
      await _loadPromises();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Your confirmation has been recorded!',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.primary,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(), style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isAdmin = _userRole == 'admin' || _userRole == 'super_admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Neta ke Vaade',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),

      // ── FAB — admin only: add new promise ──────────────────────────────────
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddPromiseScreen()),
              ).then((_) => _loadPromises()),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Add Promise',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,

      body: Column(
        children: [
          // ── Tagline ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'नेताओं के वादे — जवाबदेही आपके हाथ में है',
              style: GoogleFonts.notoSansDevanagari(
                  color: Colors.white70, fontSize: 13),
            ),
          ),

          // ── Filter chips ─────────────────────────────────────────────────
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final f       = _filters[i];
                final isActive = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(f,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                        )),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ── Promise list ─────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : _filtered.isEmpty
                        ? Center(
                            child: Text('No promises found.',
                                style: GoogleFonts.inter(
                                    color: AppColors.textHint)))
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _loadPromises,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) =>
                                  _promiseCard(_filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // ─── Promise Card ─────────────────────────────────────────────────────────────
  Widget _promiseCard(Map<String, dynamic> p) {
    final status       = p['status'] ?? 'pending';
    final witnessCount = p['witness_count'] ?? 0;
    final hasWitnessed = p['has_witnessed'] ?? false;
    final isVerified   = _userBadge == 'durbe_niwasi';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PromiseDetailScreen(promiseId: p['id'])),
      ).then((_) => _loadPromises()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header: leader name + status chip ──────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['leader_name'] ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      _roleChip(p['leader_role'] ?? ''),
                    ],
                  ),
                ),
                _statusChip(status),
              ],
            ),

            const SizedBox(height: 10),

            // ── Promise text ────────────────────────────────────────────
            Text('"${p['promise_text']}"',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic)),

            const SizedBox(height: 10),

            // ── Meta info ───────────────────────────────────────────────
            _metaRow('📍', _madeWhereLabel(p['made_where'] ?? ''),
                p['made_where_detail']),
            _metaRow('📅', _formatDate(p['made_on']), null),
            if (p['deadline'] != null)
              _metaRow('⏰', 'Deadline: ${_formatDate(p['deadline'])}', null),
            if (p['crowd_count'] != null)
              _metaRow('👥', '${p['crowd_count']} people present', null),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Witness row ─────────────────────────────────────────────
            Row(
              children: [
                Text('👁  $witnessCount residents witnessed this',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),

                // Witness button — only for verified residents
                if (isVerified && !hasWitnessed)
                  GestureDetector(
                    onTap: () =>
                        _handleWitness(p['id'], p['leader_name'] ?? ''),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('I Witnessed',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),

                // Already witnessed
                if (isVerified && hasWitnessed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('Witnessed',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),

                // Not verified — show lock
                if (!isVerified)
                  Text('🔒 Verify to witness',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text('Failed to load promises',
              style: GoogleFonts.inter(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadPromises,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: Text('Retry',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String icon, String label, String? detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            detail != null ? '$label · $detail' : label,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String role) {
    final labels = {
      'mukhiya':  'Mukhiya',
      'vidhayak': 'Vidhayak',
      'mp':       'MP',
      'sarpanch': 'Sarpanch',
      'other':    'Other',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(labels[role] ?? role,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: AppColors.primary)),
    );
  }

  Widget _statusChip(String status) {
    final configs = {
      'pending':       ('Pending',       const Color(0xFFFFFBEB), const Color(0xFFD97706)),
      'fulfilled':     ('Fulfilled ✅',  const Color(0xFFDCFCE7), const Color(0xFF166534)),
      'half_delivered':('Half Done ⚠️',  const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      'broken':        ('Broken ❌',     const Color(0xFFFEF2F2), const Color(0xFFDC2626)),
    };
    final c = configs[status] ??
        ('Unknown', const Color(0xFFF3F4F6), const Color(0xFF6B7280));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.$2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(c.$1,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: c.$3)),
    );
  }

  String _madeWhereLabel(String val) {
    const labels = {
      'rally':            'Rally',
      'village_visit':    'Village Visit',
      'personal_meeting': 'Personal Meeting',
      'other':            'Other',
    };
    return labels[val] ?? val;
  }

  String _formatDate(dynamic val) {
    if (val == null) return '';
    try {
      final dt = DateTime.parse(val.toString());
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return val.toString();
    }
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Add Promise Screen — admin only, accessed via FAB
// ─────────────────────────────────────────────────────────────────────────────
class AddPromiseScreen extends StatefulWidget {
  const AddPromiseScreen({super.key});

  @override
  State<AddPromiseScreen> createState() => _AddPromiseScreenState();
}

class _AddPromiseScreenState extends State<AddPromiseScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _leaderNameCtrl   = TextEditingController();
  final _promiseCtrl      = TextEditingController();
  final _whereDetailCtrl  = TextEditingController();
  final _crowdCtrl        = TextEditingController();

  String  _leaderRole  = 'mukhiya';
  String  _madeWhere   = 'rally';
  DateTime? _madeOn;
  DateTime? _deadline;
  bool    _saving      = false;

  final _leaderRoles = ['mukhiya', 'vidhayak', 'mp', 'sarpanch', 'other'];
  final _madeWheres  = ['rally', 'village_visit', 'personal_meeting', 'other'];

  Future<void> _pickDate({required bool isDeadline}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isDeadline) _deadline = picked;
      else _madeOn = picked;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_madeOn == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select the date the promise was made.',
            style: GoogleFonts.inter()),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.createPromise({
        'leader_name':       _leaderNameCtrl.text.trim(),
        'leader_role':       _leaderRole,
        'promise_text':      _promiseCtrl.text.trim(),
        'made_where':        _madeWhere,
        'made_where_detail': _whereDetailCtrl.text.trim().isEmpty
            ? null
            : _whereDetailCtrl.text.trim(),
        'made_on':           _madeOn!.toIso8601String().split('T')[0],
        'deadline':          _deadline?.toIso8601String().split('T')[0],
        'crowd_count':       _crowdCtrl.text.isEmpty
            ? null
            : int.tryParse(_crowdCtrl.text),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Promise added!', style: GoogleFonts.inter()),
          backgroundColor: AppColors.primary,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(), style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Add Promise',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w600,
                color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _label('Leader Name *'),
              _field(_leaderNameCtrl, 'e.g. Ramesh Singh'),

              const SizedBox(height: 14),
              _label('Leader Role *'),
              _dropdown(
                value: _leaderRole,
                items: _leaderRoles,
                labels: const {
                  'mukhiya':  'Mukhiya',
                  'vidhayak': 'Vidhayak (MLA)',
                  'mp':       'MP',
                  'sarpanch': 'Sarpanch',
                  'other':    'Other',
                },
                onChanged: (v) => setState(() => _leaderRole = v!),
              ),

              const SizedBox(height: 14),
              _label('Promise *'),
              _field(_promiseCtrl, 'What did the leader promise?',
                  maxLines: 3),

              const SizedBox(height: 14),
              _label('Where was it made? *'),
              _dropdown(
                value: _madeWhere,
                items: _madeWheres,
                labels: const {
                  'rally':            'Rally',
                  'village_visit':    'Village Visit',
                  'personal_meeting': 'Personal Meeting',
                  'other':            'Other',
                },
                onChanged: (v) => setState(() => _madeWhere = v!),
              ),

              const SizedBox(height: 14),
              _label('Location detail (optional)'),
              _field(_whereDetailCtrl, 'e.g. Durbe main chowk'),

              const SizedBox(height: 14),
              _label('Date promise was made *'),
              _dateTile(
                label: _madeOn != null
                    ? '${_madeOn!.day}/${_madeOn!.month}/${_madeOn!.year}'
                    : 'Select date',
                onTap: () => _pickDate(isDeadline: false),
              ),

              const SizedBox(height: 14),
              _label('Fulfillment deadline (optional)'),
              _dateTile(
                label: _deadline != null
                    ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                    : 'Select deadline',
                onTap: () => _pickDate(isDeadline: true),
              ),

              const SizedBox(height: 14),
              _label('People present (optional)'),
              _field(_crowdCtrl, 'e.g. 500',
                  keyboardType: TextInputType.number, required: false),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Save Promise',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              color: AppColors.textHint, fontSize: 13),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary)),
          filled: true,
          fillColor: AppColors.cardBg,
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      );

  Widget _dropdown({
    required String value,
    required List<String> items,
    required Map<String, String> labels,
    required void Function(String?) onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textPrimary),
            items: items
                .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(labels[v] ?? v),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _dateTile({required String label, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: label.startsWith('Select')
                          ? AppColors.textHint
                          : AppColors.textPrimary)),
              const Spacer(),
              Icon(Icons.calendar_today_rounded,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      );
}