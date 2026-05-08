// ─────────────────────────────────────────────────────────────────────────────
// FILE — lib/features/profile/screens/admin_panel_screen.dart  ✅ NEW
//
// Admin-only screen. Accessible from Profile screen.
// Sections:
//   1. Pending Verifications — photo + name only (no phone for privacy)
//      Approve / Revoke buttons
//   2. Community Members — all active users, name + role + badge only
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';

// ─── Admin Panel Screen ───────────────────────────────────────────────────────
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {

  // ─── State ──────────────────────────────────────────────────────────────────
  List<dynamic> _pending  = [];
  List<dynamic> _members  = [];
  bool _loadingPending    = true;
  bool _loadingMembers    = true;
  String? _pendingError;
  String? _membersError;
  
  // ─── Window management state (super_admin only) ──────────────────────────────
  Map<String, dynamic>? _window;
  bool    _loadingWindow = true;
  String? _windowError;
  String? _userRole;

  // ─── Create window form controllers ──────────────────────────────────────────
  final _windowLabelCtrl = TextEditingController();
  DateTime? _windowOpensAt;
  DateTime? _windowClosesAt;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadPending();
    _loadMembers();
    _loadWindow();
  }

  // ─── Load Pending Verifications ──────────────────────────────────────────────
  Future<void> _loadPending() async {
    setState(() { _loadingPending = true; _pendingError = null; });
    try {
      final data = await ApiService.getPendingVerifications();
      if (mounted) setState(() { _pending = data; _loadingPending = false; });
    } catch (e) {
      if (mounted) setState(() { _pendingError = e.toString(); _loadingPending = false; });
    }
  }

  // ─── Load Community Members ──────────────────────────────────────────────────
  Future<void> _loadMembers() async {
    setState(() { _loadingMembers = true; _membersError = null; });
    try {
      final data = await ApiService.getCommunityMembers();
      if (mounted) setState(() { _members = data; _loadingMembers = false; });
    } catch (e) {
      if (mounted) setState(() { _membersError = e.toString(); _loadingMembers = false; });
    }
  }

  // ─── Load user role ──────────────────────────────────────────────────────────
  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _userRole = prefs.getString('user_role'));
  }

  // ─── Load current rating window ──────────────────────────────────────────────
  Future<void> _loadWindow() async {
    setState(() { _loadingWindow = true; _windowError = null; });
    try {
      final data = await ApiService.getNetaWindowStatus();
      // ✅ If hidden, treat as no active window
      if (mounted) setState(() {
        _window = (data['is_hidden'] == true) ? null : data;
        _loadingWindow = false;
      });
    } catch (e) {
      if (mounted) setState(() { _window = null; _loadingWindow = false; });
    }
  }

  // ─── Create new rating window ────────────────────────────────────────────────
  Future<void> _createWindow() async {
    if (_windowLabelCtrl.text.trim().isEmpty ||
        _windowOpensAt == null || _windowClosesAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill label, open date and close date.',
            style: GoogleFonts.inter()),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_windowClosesAt!.isBefore(_windowOpensAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Close date must be after open date.',
            style: GoogleFonts.inter()),
        backgroundColor: Colors.red,
      ));
      return;
    }
    try {
      await ApiService.createRatingWindow(
        label:     _windowLabelCtrl.text.trim(),
        opensAt:   _windowOpensAt!,
        closesAt:  _windowClosesAt!,
      );
      _windowLabelCtrl.clear();
      setState(() { _windowOpensAt = null; _windowClosesAt = null; });
      await _loadWindow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Rating window created!', style: GoogleFonts.inter()),
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

  // ─── Hide current window ─────────────────────────────────────────────────────
  Future<void> _hideWindow() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Close Rating Window',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: Text(
          'This will immediately stop all voting. Are you sure?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
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
            child: Text('Close Window',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.hideRatingWindow();
      await _loadWindow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Rating window closed.', style: GoogleFonts.inter()),
          backgroundColor: Colors.orange,
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

  // ─── Unhide current window ───────────────────────────────────────────────────
  Future<void> _unhideWindow(String windowId) async {
    try {
      await ApiService.unhideRatingWindow(windowId);
      await _loadWindow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Rating window reopened!', style: GoogleFonts.inter()),
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

  // ─── Approve User ────────────────────────────────────────────────────────────
  Future<void> _approveUser(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Approve Residency',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: Text(
          'Confirm that $name is a verified resident of Durbe village?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Approve', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.approveUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$name approved as Durbe Niwasi!', style: GoogleFonts.inter()),
          backgroundColor: AppColors.primary,
        ));
        _loadPending();
        _loadMembers();
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

  // ─── Revoke User ─────────────────────────────────────────────────────────────
  Future<void> _revokeUser(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Revoke Badge',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700, color: Colors.red)),
        content: Text(
          'Remove the Durbe Niwasi badge from $name?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Revoke', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.revokeUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$name\'s badge has been revoked.', style: GoogleFonts.inter()),
          backgroundColor: Colors.orange,
        ));
        _loadPending();
        _loadMembers();
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

  // ─── Change user role — super_admin only ─────────────────────────────────────
  Future<void> _changeRole(String userId, String name, String currentRole) async {
    final roles = ['user', 'admin', 'vendor'];
    final labels = {'user': 'User', 'admin': 'Admin', 'vendor': 'Vendor'};

    final selected = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change Role — $name',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((r) => RadioListTile<String>(
            value: r,
            groupValue: currentRole,
            title: Text(labels[r]!, style: GoogleFonts.inter(fontSize: 13)),
            activeColor: AppColors.primary,
            onChanged: (v) => Navigator.pop(context, v),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
        ],
      ),
    );

    if (selected == null || selected == currentRole) return;

    try {
      await ApiService.changeUserRole(userId, selected);
      await _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$name is now ${labels[selected]}.',
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0FDF4),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.primary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Admin Panel',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () { _loadPending(); _loadMembers(); _loadWindow(); },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Pending Verifications ───────────────────────────────────────
            _sectionHeader(
              icon: '⏳',
              title: 'Pending Verifications',
              count: _pending.length,
              countColor: Colors.red,
            ),
            const SizedBox(height: 10),
            _buildPendingSection(),

            const SizedBox(height: 20),

            // ── Community Members ───────────────────────────────────────────
            _sectionHeader(
              icon: '👥',
              title: 'Community Members',
              count: _members.length,
              countColor: AppColors.primary,
            ),
            const SizedBox(height: 10),
            _buildMembersSection(),

            if (_userRole == 'super_admin') ...[
              const SizedBox(height: 20),
              _sectionHeader(
                icon: '🗓️',
                title: 'Rating Window',
                count: _window != null ? 1 : 0,
                countColor: const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 10),
              _buildWindowSection(),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Section Header ──────────────────────────────────────────────────────────
  Widget _sectionHeader({
    required String icon,
    required String title,
    required int count,
    required Color countColor,
  }) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.playfairDisplay(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: const Color(0xFF111827))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: countColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: countColor.withOpacity(0.3)),
          ),
          child: Text('$count',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: countColor)),
        ),
      ],
    );
  }

  // ─── Pending Section ─────────────────────────────────────────────────────────
  Widget _buildPendingSection() {
    if (_loadingPending) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_pendingError != null) {
      return _errorCard(_pendingError!, _loadPending);
    }
    if (_pending.isEmpty) {
      return _emptyCard('No pending verifications 🎉', 'All caught up!');
    }
    return Column(
      children: _pending.map((u) => _buildPendingTile(u)).toList(),
    );
  }

  // ─── Pending Tile ─────────────────────────────────────────────────────────────
  Widget _buildPendingTile(Map<String, dynamic> user) {
    final name     = user['full_name'] ?? 'Unknown';
    final photoUrl = user['profile_photo_url'] as String?;
    final userId   = user['id'].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Photo — no phone shown (privacy)
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFBBF7D0),
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Text(name[0].toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: AppColors.primary))
                : null,
          ),
          const SizedBox(width: 12),

          // Name only — no phone (privacy decision)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827))),
                Text('Awaiting verification',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF6B7280))),
              ],
            ),
          ),

          // Approve button
          GestureDetector(
            onTap: () => _approveUser(userId, name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Text('Approve',
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 6),

          // Revoke button
          GestureDetector(
            onTap: () => _revokeUser(userId, name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text('Revoke',
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Members Section ──────────────────────────────────────────────────────────
  Widget _buildMembersSection() {
    if (_loadingMembers) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_membersError != null) {
      return _errorCard(_membersError!, _loadMembers);
    }
    if (_members.isEmpty) {
      return _emptyCard('No members yet', 'Users will appear here after registration.');
    }
    return Column(
      children: _members.map((u) => _buildMemberTile(u)).toList(),
    );
  }

  // ─── Member Tile ──────────────────────────────────────────────────────────────
  Widget _buildMemberTile(Map<String, dynamic> user) {
    final name     = user['full_name'] ?? 'Unknown';
    final role     = user['role']  ?? 'user';
    final badge    = user['badge'] ?? 'none';
    final userId = user['id']?.toString() ?? '';
    final photoUrl = user['profile_photo_url'] as String?;

    return GestureDetector(
      onTap: (_userRole == 'super_admin' && role != 'super_admin')
          ? () => _changeRole(userId, name, role)
          : null,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFBBF7D0),
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Text(name[0].toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppColors.primary))
                : null,
          ),
          const SizedBox(width: 12),

          // Name + role only — no phone (privacy)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827))),
                Text(_roleLabel(role),
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF6B7280))),
              ],
            ),
          ),

          // Badge chip
          if (badge == 'durbe_niwasi')
            _miniChip('🏠 Verified', const Color(0xFFDCFCE7), AppColors.primary)
          else if (badge == 'pending')
            _miniChip('⏳ Pending', const Color(0xFFFFFBEB), const Color(0xFFD97706))
          else
            _miniChip('No badge', const Color(0xFFF3F4F6), const Color(0xFF9CA3AF)),

          // Tap hint — super_admin only, not for other super_admins
          if (_userRole == 'super_admin' && role != 'super_admin') ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: Color(0xFFD1D5DB)),
          ],
       ],
      ),
    );
  }
  // ─── Helpers ──────────────────────────────────────────────────────────────────
  Widget _emptyCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151))),
          const SizedBox(height: 4),
          Text(subtitle,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  Widget _errorCard(String error, VoidCallback retry) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(error,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.red))),
          TextButton(
            onPressed: retry,
            child: Text('Retry', style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w600, color: text)),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'super_admin': return 'Super Admin';
      case 'admin':       return 'Admin';
      case 'vendor':      return 'Vendor';
      default:            return 'User';
    }
  }
  
  // ─── Window Section ───────────────────────────────────────────────────────────
  Widget _buildWindowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Current window status ───────────────────────────────────────────
        if (_loadingWindow)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else if (_window != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_window!['is_open'] == true)
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEF3C7),
              border: Border.all(
                color: (_window!['is_open'] == true)
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFFCD34D),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      (_window!['is_open'] == true) ? '🗳️ Window Open' : '🔒 Window Closed',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: (_window!['is_open'] == true)
                              ? AppColors.primary
                              : const Color(0xFF92400E)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_window!['label'] ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151))),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Opens: ${_formatDate(_window!['opens_at'])}  ·  Closes: ${_formatDate(_window!['closes_at'])}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF374151)),
                ),
                const SizedBox(height: 10),
                // Hide / Unhide button
                SizedBox(
                  width: double.infinity,
                  child: (_window!['is_open'] == true)
                      ? OutlinedButton.icon(
                          onPressed: _hideWindow,
                          icon: const Icon(Icons.lock_outline_rounded, size: 16),
                          label: Text('Force Close Window',
                              style: GoogleFonts.inter(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () =>
                              _unhideWindow(_window!['id'].toString()),
                          icon: const Icon(Icons.lock_open_rounded, size: 16),
                          label: Text('Reopen Window',
                              style: GoogleFonts.inter(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ] else
          _emptyCard('No active window', 'Create a new rating window below.'),

        const SizedBox(height: 14),

        // ── Create new window form ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create New Window',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: const Color(0xFF374151))),
              const SizedBox(height: 12),

              // Label field
              TextField(
                controller: _windowLabelCtrl,
                style: GoogleFonts.inter(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Label — e.g. Jan 2026',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF9CA3AF)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColors.primary)),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                ),
              ),

              const SizedBox(height: 10),

              // Date pickers row
              Row(
                children: [
                  Expanded(
                    child: _dateTile(
                      label: _windowOpensAt != null
                          ? _formatDate(
                              _windowOpensAt!.toIso8601String())
                          : 'Opens on',
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary),
                            ),
                            child: child!,
                          ),
                        );
                        if (d != null) setState(() => _windowOpensAt = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dateTile(
                      label: _windowClosesAt != null
                          ? _formatDate(
                              _windowClosesAt!.toIso8601String())
                          : 'Closes on',
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary),
                            ),
                            child: child!,
                          ),
                        );
                        if (d != null) setState(() => _windowClosesAt = d);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createWindow,
                  icon: const Icon(Icons.add_rounded,
                      size: 16, color: Colors.white),
                  label: Text('Create Window',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Date tile helper ─────────────────────────────────────────────────────────
  Widget _dateTile({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 13, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: label.contains('on')
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF374151))),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Format date helper ───────────────────────────────────────────────────────
  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) { return iso; }
  }
}