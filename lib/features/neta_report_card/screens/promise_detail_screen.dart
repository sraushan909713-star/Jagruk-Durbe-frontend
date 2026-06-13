// ─────────────────────────────────────────────────────────────────────────────
// FILE — lib/features/neta_report_card/screens/promise_detail_screen.dart ✅ NEW
//
// Shows full promise details + scrollable list of witnesses (name + photo).
// Admin who created it can update status or delete.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';   // ✅ ADD
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import '../../../core/utils/cloudinary_url.dart';

// ─── Promise Detail Screen ────────────────────────────────────────────────────
class PromiseDetailScreen extends StatefulWidget {
  final String promiseId;
  const PromiseDetailScreen({super.key, required this.promiseId});

  @override
  State<PromiseDetailScreen> createState() => _PromiseDetailScreenState();
}

class _PromiseDetailScreenState extends State<PromiseDetailScreen> {

  // ─── State ──────────────────────────────────────────────────────────────────
  Map<String, dynamic>? _promise;
  List<dynamic>         _witnesses  = [];
  bool  _loadingPromise   = true;
  bool  _loadingWitnesses = true;
  String? _userRole;
  String? _userId;

  YoutubePlayerController? _ytController;   // ✅ ADD

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadAll();
  }

  // ✅ ADD: build the YouTube controller once the promise has loaded
  void _setupYouTube() {
    if (_ytController != null) return;                       // already set up
    final raw = _promise?['youtube_link'] as String?;
    if (raw == null || raw.trim().isEmpty) return;
    final videoId = YoutubePlayer.convertUrlToId(raw.trim());
    if (videoId == null || videoId.isEmpty) return;
    _ytController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    _ytController?.dispose();   // ✅ ADD
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userRole = prefs.getString('user_role');
        _userId   = prefs.getString('user_id');
      });
    }
  }

  Future<void> _loadAll() async {
    _loadPromise();
    _loadWitnesses();
  }

  Future<void> _loadPromise() async {
    setState(() => _loadingPromise = true);
    try {
      final data = await ApiService.getPromise(widget.promiseId);
      if (mounted) setState(() { _promise = data; _loadingPromise = false; });
      _setupYouTube();   // ✅ ADD: build player once youtube_link is known
    } catch (e) {
      if (mounted) setState(() => _loadingPromise = false);
    }
  }

  Future<void> _loadWitnesses() async {
    setState(() => _loadingWitnesses = true);
    try {
      final data = await ApiService.getPromiseWitnesses(widget.promiseId);
      if (mounted) setState(() { _witnesses = data; _loadingWitnesses = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingWitnesses = false);
    }
  }

  // ─── Update status — admin only ──────────────────────────────────────────────
  Future<void> _updateStatus(String currentStatus) async {
    final statuses = ['pending', 'fulfilled', 'half_delivered', 'broken'];
    final labels   = {
      'pending':       'Pending',
      'fulfilled':     'Fulfilled',
      'half_delivered':'Half Delivered',
      'broken':        'Broken',
    };

    final selected = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update Status',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: RadioGroup<String>(
          groupValue: currentStatus,
          onChanged: (v) => Navigator.pop(context, v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses.map((s) => RadioListTile<String>(
              value: s,
              title: Text(labels[s]!, style: GoogleFonts.inter(fontSize: 13)),
              activeColor: AppColors.primary,
            )).toList(),
          ),
        ),
      ),
    );

    if (selected == null || selected == currentStatus) return;

    try {
      await ApiService.updatePromiseStatus(widget.promiseId, selected);
      await _loadPromise();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated!', style: GoogleFonts.inter()),
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

  // ─── Delete — admin only ─────────────────────────────────────────────────────
  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Promise',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700, color: Colors.red)),
        content: Text('Are you sure you want to delete this promise?',
            style: GoogleFonts.inter(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deletePromise(widget.promiseId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(), style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPromise) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text('Promise Details',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20, fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_promise == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('Promise not found.')),
      );
    }

    final p              = _promise!;
    final status         = p['status'] ?? 'pending';
    final isAdmin        = _userRole == 'admin' || _userRole == 'super_admin';
    final isCreator      = p['created_by'] == _userId;
    final canEditDelete  = isAdmin && (isCreator || _userRole == 'super_admin');

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
        title: Text('Promise Details',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w600,
                color: Colors.white)),
        actions: [
          if (canEditDelete) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              tooltip: 'Update status',
              onPressed: () => _updateStatus(status),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              tooltip: 'Delete',
              onPressed: _delete,
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Promise detail card ─────────────────────────────────────
              Container(
                width: double.infinity,
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
                        Expanded(
                          child: Text(p['leader_name'] ?? '',
                              style: GoogleFonts.playfairDisplay(
                                  fontSize: 18, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                        ),
                        _statusChip(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _roleChip(p['leader_role'] ?? ''),
                    const SizedBox(height: 14),

                    // Promise text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD1FAE5)),
                      ),
                      child: Text('"${p['promise_text']}"',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontStyle: FontStyle.italic,
                              color: AppColors.textPrimary)),
                    ),

                    const SizedBox(height: 14),
                    _detailRow('📍', 'Where', _madeWhereLabel(p['made_where'] ?? ''),
                        sub: p['made_where_detail']),
                    _detailRow('📅', 'Made on', _formatDate(p['made_on'])),
                    if (p['deadline'] != null)
                      _detailRow('⏰', 'Deadline', _formatDate(p['deadline'])),
                    if (p['crowd_count'] != null)
                      _detailRow('👥', 'People present',
                          '${p['crowd_count']} people'),
                  ],
                ),
              ),

              // ── Video proof (if youtube_link present) ───────────────────  // ✅ ADD
              if (_ytController != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('🎥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text('Video Proof',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: YoutubePlayer(
                    controller: _ytController!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: AppColors.primary,
                    progressColors: const ProgressBarColors(
                      playedColor: AppColors.primary,
                      handleColor: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Witnesses section ───────────────────────────────────────
              Row(
                children: [
                  const Text('👁', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('Witnesses',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_witnesses.length}',
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _loadingWitnesses
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _witnesses.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text('No witnesses yet.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  color: AppColors.textHint)),
                        )
                      : Column(
                          children: _witnesses
                              .map((w) => _witnessTile(w))
                              .toList(),
                        ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Witness tile ─────────────────────────────────────────────────────────────
  Widget _witnessTile(Map<String, dynamic> w) {
    final name     = w['full_name'] ?? 'Unknown';
    final photoUrl = w['photo_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFBBF7D0),
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(CloudinaryUrl.avatar(photoUrl))
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Text(name[0].toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.primary))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
          Text(_formatDateTime(w['witnessed_at']),
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.textHint)),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────
  Widget _detailRow(String icon, String label, String value, {String? sub}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text('$label: ',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          Expanded(
            child: Text(sub != null ? '$value · $sub' : value,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String role) {
    const labels = {
      'mukhiya': 'Mukhiya', 'vidhayak': 'Vidhayak',
      'mp': 'MP', 'sarpanch': 'Sarpanch', 'other': 'Other',
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
          color: c.$2, borderRadius: BorderRadius.circular(20)),
      child: Text(c.$1,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: c.$3)),
    );
  }

  String _madeWhereLabel(String val) {
    const labels = {
      'rally': 'Rally', 'village_visit': 'Village Visit',
      'personal_meeting': 'Personal Meeting', 'other': 'Other',
    };
    return labels[val] ?? val;
  }

  String _formatDate(dynamic val) {
    if (val == null) return '';
    try {
      final dt = DateTime.parse(val.toString());
      const months = ['', 'Jan','Feb','Mar','Apr','May','Jun',
          'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) { return val.toString(); }
  }

  String _formatDateTime(dynamic val) {
    if (val == null) return '';
    try {
      final dt = DateTime.parse(val.toString()).toLocal();
      const months = ['','Jan','Feb','Mar','Apr','May','Jun',
          'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) { return ''; }
  }
}
