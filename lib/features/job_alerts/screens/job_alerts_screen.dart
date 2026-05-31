// lib/features/job_alerts/screens/job_alerts_screen.dart
// ──────────────────────────────────────────────────────────────────
// Job Alerts — Sarkari Naukri for Durbe village youth.
//
// List screen:
//   - Category filter chips (Government, Private, Railway etc.)
//   - Job cards sorted by deadline (closest first)
//   - Deadline shown in red if < 7 days away
//
// Detail screen:
//   - Full job info cards (eligibility, how to apply, salary etc.)
//   - "Apply Now" button → opens apply_link in browser
//   - Applicants section → social proof (who from Durbe applied)
//
// API methods used:
//   ApiService.getJobAlerts()         → GET /job-alerts
//   ApiService.getJobAlertDetail()    → GET /job-alerts/{id}
//   ApiService.getJobApplicants()     → GET /job-alerts/{id}/applicants
// ──────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/cloudinary_url.dart';

// ─── Category config ─────────────────────────────────────────────
const List<Map<String, String>> _categories = [
  {'value': 'government', 'label': 'Government', 'emoji': '🏛️'},
  {'value': 'private',    'label': 'Private',    'emoji': '🏢'},
  {'value': 'railway',    'label': 'Railway',    'emoji': '🚂'},
  {'value': 'banking',    'label': 'Banking',    'emoji': '🏦'},
  {'value': 'defence',    'label': 'Defence',    'emoji': '🪖'},
  {'value': 'teaching',   'label': 'Teaching',   'emoji': '📚'},
  {'value': 'other',      'label': 'Other',      'emoji': '📌'},
];

String _catLabel(String value) => _categories
    .firstWhere((c) => c['value'] == value, orElse: () => {'label': value})['label']!;

String _catEmoji(String value) => _categories
    .firstWhere((c) => c['value'] == value, orElse: () => {'emoji': '📌'})['emoji']!;

Color _catColor(String cat) {
  switch (cat) {
    case 'government': return const Color(0xFF166534);
    case 'private':    return const Color(0xFF1D4ED8);
    case 'railway':    return const Color(0xFF9D174D);
    case 'banking':    return const Color(0xFF92400E);
    case 'defence':    return const Color(0xFF1E3A5F);
    case 'teaching':   return const Color(0xFF6B21A8);
    default:           return const Color(0xFF374151);
  }
}

Color _catBgColor(String cat) {
  switch (cat) {
    case 'government': return const Color(0xFFDCFCE7);  // soft green
    case 'private':    return const Color(0xFFDBEAFE);  // soft blue
    case 'railway':    return const Color(0xFFFCE7F3);  // soft pink
    case 'banking':    return const Color(0xFFFEF3C7);  // soft amber
    case 'defence':    return const Color(0xFFE0E7FF);  // soft indigo
    case 'teaching':   return const Color(0xFFF3E8FF);  // soft purple
    default:           return const Color(0xFFF3F4F6);  // soft grey
  }
}

// ─── Deadline helpers ────────────────────────────────────────────
int _daysLeft(String lastDate) {
  try {
    final deadline = DateTime.parse(lastDate);
    return deadline.difference(DateTime.now()).inDays;
  } catch (_) {
    return 999;
  }
}

String _formatDate(String lastDate) {
  try {
    final d = DateTime.parse(lastDate);
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  } catch (_) {
    return lastDate;
  }
}


// ══════════════════════════════════════════════════════════════════
// MAIN LIST SCREEN
// ══════════════════════════════════════════════════════════════════
class JobAlertsScreen extends StatefulWidget {
  const JobAlertsScreen({super.key});

  @override
  State<JobAlertsScreen> createState() => _JobAlertsScreenState();
}

class _JobAlertsScreenState extends State<JobAlertsScreen> {

  List<dynamic> _activeJobs  = [];
  List<dynamic> _expiredJobs = [];
  bool          _isLoading   = true;
  String?       _error;
  String?       _selectedCat;
  String?       _userRole;

  @override
    void initState() {
    super.initState();
    _loadUserRole();
    _fetchJobs();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _userRole = prefs.getString('user_role'));
  }

  Future<void> _fetchJobs() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final jobs = await ApiService.getJobAlerts(category: _selectedCat);
      if (mounted) setState(() {
        _activeJobs  = jobs.where((j) => _daysLeft(j['last_date'] ?? '') >= 0).toList();
        _expiredJobs = jobs.where((j) => _daysLeft(j['last_date'] ?? '') < 0).toList();
        _isLoading   = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Job Alerts',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchJobs),
        ],
      ),

      floatingActionButton: (_userRole == 'admin' || _userRole == 'super_admin')
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _CreateJobScreen()),
              ).then((_) => _fetchJobs()),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Add Job',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ─── Tagline ────────────────────────────────────────
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              'सरकारी नौकरी — आपके गाँव तक',
              style: GoogleFonts.notoSansDevanagari(
                color: Colors.white70, fontSize: 13),
            ),
          ),

          // ─── Category filter chips ───────────────────────────
          Container(
            height: 50,
            color: AppColors.primaryDark,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Center(child: _CatChip(
                  label: 'All',
                  isSelected: _selectedCat == null,
                  onTap: () { setState(() => _selectedCat = null); _fetchJobs(); },
                )),
                const SizedBox(width: 8),
                ..._categories.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(child: _CatChip(
                    label: '${c['emoji']} ${c['label']}',
                    isSelected: _selectedCat == c['value'],
                    onTap: () {
                      setState(() => _selectedCat = c['value']);
                      _fetchJobs();
                    },
                  )),
                )),
              ],
            ),
          ),

// ─── Job count ───────────────────────────────────────
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                '${_activeJobs.length} job${_activeJobs.length == 1 ? '' : 's'} found',
                style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
              ),
            ),

          // ─── List ────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : _activeJobs.isEmpty && _expiredJobs.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _fetchJobs,
                            color: AppColors.primary,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                              children: [

                                // Active jobs
                                ..._activeJobs.map((job) => _JobCard(
                                  job: job,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) =>
                                      _JobDetailScreen(
                                        jobId:    job['id'],
                                        userRole: _userRole,
                                        onDeleted: _fetchJobs,
                                      )),
                                  ),
                                )),

                                // Past Jobs section
                                if (_expiredJobs.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                                    child: Row(children: [
                                      const Icon(Icons.history_rounded,
                                          size: 15, color: Color(0xFF9CA3AF)),
                                      const SizedBox(width: 6),
                                      Text('Past Jobs',
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF9CA3AF))),
                                      const SizedBox(width: 8),
                                      Expanded(child: Divider(
                                          color: Colors.grey.shade300)),
                                    ]),
                                  ),
                                  ..._expiredJobs.map((job) => _JobCard(
                                    job: job,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) =>
                                        _JobDetailScreen(
                                          jobId:     job['id'],
                                          userRole:  _userRole,
                                          onDeleted: _fetchJobs,
                                        )),
                                    ),
                                  )),
                                ],
                              ],
                            ),
                          ),
                        ),
        ],
      ),
    );
  }

  Widget _buildError() => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
      const SizedBox(height: 12),
      Text(_error!, style: GoogleFonts.inter(color: AppColors.error)),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _fetchJobs,
        icon: const Icon(Icons.refresh),
        label: Text('Try again', style: GoogleFonts.inter()),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      ),
    ]),
  ));

  Widget _buildEmpty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.work_outline, size: 72, color: Colors.grey),
      const SizedBox(height: 14),
      Text('No jobs found',
        style: GoogleFonts.inter(
          color: AppColors.textSecondary, fontSize: 16,
          fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      Text('Try a different category',
        style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 13)),
    ],
  ));
}


// ══════════════════════════════════════════════════════════════════
// CATEGORY FILTER CHIP
// ══════════════════════════════════════════════════════════════════
class _CatChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _CatChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.inter(
          color: isSelected ? AppColors.primary : Colors.white,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        )),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════════
// JOB CARD — list item
// ══════════════════════════════════════════════════════════════════
class _JobCard extends StatelessWidget {
  final dynamic job;
  final VoidCallback onTap;
  const _JobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat      = (job['category'] as String?) ?? 'other';
    final catColor = _catColor(cat);
    final lastDate = job['last_date'] as String? ?? '';
    final days     = _daysLeft(lastDate);
    final isUrgent = days <= 7;
    final isExpired = _daysLeft(job['last_date'] ?? '') < 0;

    return Opacity(
      opacity: isExpired ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
          color: _catBgColor(cat),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUrgent && !isExpired
                ? const Color(0xFFFCA5A5)
                : catColor.withOpacity(0.25),
          ),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ─── Top row: category badge + deadline ───────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '${_catEmoji(cat)} ${_catLabel(cat)}',
                  style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: catColor)),
              ),

              // Deadline badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isExpired
                      ? const Color(0xFFF3F4F6)
                      : isUrgent
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(
                  isExpired
                      ? 'Expired'
                      : isUrgent
                          ? '⚠️ $days days left'
                          : '📅 ${_formatDate(lastDate)}',
                  style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: isExpired
                        ? AppColors.textHint
                        : isUrgent
                            ? const Color(0xFF991B1B)
                            : const Color(0xFF166534)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ─── Job title ────────────────────────────────────
          Text(job['title'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),

          const SizedBox(height: 3),

          // ─── Organization ─────────────────────────────────
          Text(job['organization'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textSecondary)),

          const SizedBox(height: 10),

          // ─── Posts + Salary row ───────────────────────────
          Row(children: [
            if (job['total_posts'] != null) ...[
              Icon(Icons.people_outline, size: 13, color: AppColors.textHint),
              const SizedBox(width: 3),
              Text('${job['total_posts']} posts',
                style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
            ],
            if (job['salary_range'] != null) ...[
              Icon(Icons.currency_rupee, size: 13, color: AppColors.textHint),
              const SizedBox(width: 2),
              Text(job['salary_range'],
                style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary)),
            ],
            const Spacer(),
            Text('View details',
              style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.primary,
                fontWeight: FontWeight.w500)),
            const SizedBox(width: 2),
            Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primary),
          ]),
        ]),
        )
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════════
// JOB DETAIL SCREEN
// ══════════════════════════════════════════════════════════════════
class _JobDetailScreen extends StatefulWidget {
  final String     jobId;
  final String?    userRole;
  final VoidCallback? onDeleted;
  const _JobDetailScreen({
    required this.jobId,
    this.userRole,
    this.onDeleted,
  });

  @override
  State<_JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<_JobDetailScreen> {
  Map<String, dynamic>? _job;
  List<dynamic>         _applicants      = [];
  bool                  _isLoading       = true;
  bool                  _applicantsLoading = true;
  String?               _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
    _fetchApplicants();
  }

  Future<void> _fetchDetail() async {
    try {
      final job = await ApiService.getJobAlertDetail(widget.jobId);
      if (mounted) setState(() { _job = job; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _fetchApplicants() async {
    try {
      final applicants = await ApiService.getJobApplicants(widget.jobId);
      if (mounted) setState(() {
        _applicants        = applicants;
        _applicantsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _applicantsLoading = false);
    }
  }

  Future<void> _launchApplyLink() async {
    final link = _job?['apply_link'];
    if (link == null || link.toString().isEmpty) return;
    try {
      final uri = Uri.parse(link);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open the link. Try copying it manually.'),
        ));
      }
    }
  }

  // ─── Delete job — admin only ──────────────────────────────────
  Future<void> _deleteJob() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Job',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700, color: Colors.red)),
        content: Text('Are you sure you want to delete this job posting?',
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
      await ApiService.deleteJobAlert(widget.jobId);
      if (mounted) {
        Navigator.pop(context);
        widget.onDeleted?.call();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Job deleted.', style: GoogleFonts.inter()),
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

  // ─── Add applicant — admin only ───────────────────────────────
  Future<void> _showAddApplicantDialog() async {
    final nameCtrl     = TextEditingController();
    final relNameCtrl  = TextEditingController();
    String gender      = 'male';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Add Applicant',
              style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Full name',
                hintStyle: GoogleFonts.inter(color: AppColors.textHint),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: relNameCtrl,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Father / Husband name',
                hintStyle: GoogleFonts.inter(color: AppColors.textHint),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Text('Gender:', style: GoogleFonts.inter(fontSize: 13)),
              const SizedBox(width: 12),
              ChoiceChip(
                label: Text('Male', style: GoogleFonts.inter(fontSize: 12)),
                selected: gender == 'male',
                selectedColor: AppColors.primaryLight,
                onSelected: (_) => setS(() => gender = 'male'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Female', style: GoogleFonts.inter(fontSize: 12)),
                selected: gender == 'female',
                selectedColor: const Color(0xFFFCE4EC),
                onSelected: (_) => setS(() => gender = 'female'),
              ),
            ]),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(context);
                try {
                  await ApiService.addJobApplicant(widget.jobId, {
                    'name':          nameCtrl.text.trim(),
                    'relative_name': relNameCtrl.text.trim().isEmpty
                        ? null : relNameCtrl.text.trim(),
                    'gender':        gender,
                    'applied_date':  DateTime.now()
                        .toIso8601String().split('T')[0],
                  });
                  _fetchApplicants();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Applicant added!',
                          style: GoogleFonts.inter()),
                      backgroundColor: AppColors.primary,
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e.toString(),
                          style: GoogleFonts.inter()),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              },
              child: Text('Add',
                  style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Job Details',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.userRole == 'admin' || widget.userRole == 'super_admin')
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 22),
              tooltip: 'Delete job',
              onPressed: _deleteJob,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!,
                  style: GoogleFonts.inter(color: AppColors.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ─── Header card ──────────────────────
                      _buildHeaderCard(),
                      const SizedBox(height: 12),

                      // ─── Eligibility ──────────────────────
                      _buildSection(
                        icon: Icons.verified_user_outlined,
                        title: 'पात्रता (Eligibility)',
                        content: _job?['eligibility'] ?? '',
                        color: const Color(0xFF1D4ED8),
                      ),

                      // ─── How to apply ─────────────────────
                      _buildSection(
                        icon: Icons.assignment_outlined,
                        title: 'आवेदन कैसे करें (How to Apply)',
                        content: _job?['how_to_apply'] ?? '',
                        color: const Color(0xFF6B21A8),
                      ),

                      // ─── Notes (if present) ───────────────
                      if (_job?['notes'] != null &&
                          (_job!['notes'] as String).isNotEmpty)
                        _buildSection(
                          icon: Icons.lightbulb_outline,
                          title: 'अतिरिक्त जानकारी (Important Notes)',
                          content: _job!['notes'],
                          color: const Color(0xFF92400E),
                        ),

                      // ─── Apply Now button ─────────────────
                      if (_job?['apply_link'] != null &&
                          (_job!['apply_link'] as String).isNotEmpty) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _launchApplyLink,
                            icon: const Icon(Icons.open_in_new,
                                color: Colors.white, size: 18),
                            label: Text('Apply Now',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.cta,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ─── Applicants section ───────────────
                      _buildApplicantsSection(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  // ─── Header card ─────────────────────────────────────────────
  Widget _buildHeaderCard() {
    final cat      = (_job?['category'] as String?) ?? 'other';
    final catColor = _catColor(cat);
    final lastDate = _job?['last_date'] as String? ?? '';
    final days     = _daysLeft(lastDate);
    final isUrgent = days <= 7 && days >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: catColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: catColor.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Category + emoji
        Row(children: [
          Text(_catEmoji(cat), style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(child: Text(_job?['title'] ?? '',
            style: GoogleFonts.playfairDisplay(
              fontSize: 17, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary))),
        ]),

        const SizedBox(height: 8),

        Text(_job?['organization'] ?? '',
          style: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textSecondary,
            fontWeight: FontWeight.w500)),

        const SizedBox(height: 10),

        // Info row: posts | salary | deadline
        Wrap(spacing: 10, runSpacing: 6, children: [
          if (_job?['total_posts'] != null)
            _infoPill('👥 ${_job!['total_posts']} posts', AppColors.primary),
          if (_job?['salary_range'] != null)
            _infoPill('₹ ${_job!['salary_range']}', const Color(0xFF166534)),
          _infoPill(
            isUrgent
                ? '⚠️ $days days left'
                : '📅 ${_formatDate(lastDate)}',
            isUrgent ? const Color(0xFF991B1B) : AppColors.primary,
          ),
        ]),
      ]),
    );
  }

  Widget _infoPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20)),
      child: Text(text,
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ─── Section card ─────────────────────────────────────────────
  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(title, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ]),
        const SizedBox(height: 8),
        Text(content, style: GoogleFonts.inter(
          fontSize: 13, color: AppColors.textPrimary, height: 1.6)),
      ]),
    );
  }

  // ─── Applicants / social proof section ───────────────────────
  Widget _buildApplicantsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.people_alt_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('जो आवेदान कर चुके हैं (Applicants)',
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.primary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12)),
            child: Text('${_applicants.length}',
              style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.primary)),
          ),
          // ✅ Add applicant button — admin only
          if (widget.userRole == 'admin' || widget.userRole == 'super_admin') ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showAddApplicantDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add, size: 12, color: Colors.white),
                  const SizedBox(width: 3),
                  Text('Add',
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ]),
              ),
            ),
          ],
        ]),

        const SizedBox(height: 12),

        if (_applicantsLoading)
          Center(child: CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 2))
        else if (_applicants.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No one from Durbe has applied yet.\nBe the first! 💪',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textHint, fontSize: 13, height: 1.5),
            ),
          ))
        else
          ..._applicants.map((a) => _ApplicantTile(applicant: a)),
      ]),
    );
  }
}


// ══════════════════════════════════════════════════════════════════
// APPLICANT TILE — social proof row
// ══════════════════════════════════════════════════════════════════
class _ApplicantTile extends StatelessWidget {
  final dynamic applicant;
  const _ApplicantTile({required this.applicant});

  @override
  Widget build(BuildContext context) {
    final gender   = applicant['gender'] ?? 'male';
    final isFemale = gender == 'female';
    final appliedDate = applicant['applied_date'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [

        // Photo or avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: isFemale
              ? const Color(0xFFFCE4EC)
              : const Color(0xFFE3F2FD),
          backgroundImage: applicant['photo_url'] != null
              ? NetworkImage(CloudinaryUrl.avatar(applicant['photo_url'])) : null,
          child: applicant['photo_url'] == null
              ? Text(isFemale ? '👩' : '👨',
                  style: const TextStyle(fontSize: 18))
              : null,
        ),

        const SizedBox(width: 10),

        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(applicant['name'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
            if (applicant['relative_name'] != null)
              Text(
                '${isFemale ? 'Husband' : 'Father'}: ${applicant['relative_name']}',
                style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary)),
          ],
        )),

        // Applied date
        if (appliedDate != null)
          Text(_formatDate(appliedDate),
            style: GoogleFonts.inter(
              fontSize: 10, color: AppColors.textHint)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CREATE JOB SCREEN — admin/super_admin only
// ══════════════════════════════════════════════════════════════════
class _CreateJobScreen extends StatefulWidget {
  const _CreateJobScreen({super.key});

  @override
  State<_CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<_CreateJobScreen> {
  final _titleCtrl        = TextEditingController();
  final _orgCtrl          = TextEditingController();
  final _eligibilityCtrl  = TextEditingController();
  final _howToApplyCtrl   = TextEditingController();
  final _salaryCtrl       = TextEditingController();
  final _postsCtrl        = TextEditingController();
  final _applyLinkCtrl    = TextEditingController();
  final _notesCtrl        = TextEditingController();

  String    _category  = 'government';
  DateTime? _lastDate;
  bool      _saving    = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _lastDate = picked);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _orgCtrl.text.trim().isEmpty ||
        _lastDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Title, organisation and deadline are required.',
            style: GoogleFonts.inter()),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiService.createJobAlert({
        'title':        _titleCtrl.text.trim(),
        'organization': _orgCtrl.text.trim(),
        'category':     _category,
        'eligibility':  _eligibilityCtrl.text.trim(),
        'how_to_apply': _howToApplyCtrl.text.trim(),
        'salary_range': _salaryCtrl.text.trim().isEmpty ? null : _salaryCtrl.text.trim(),
        'total_posts':  _postsCtrl.text.isEmpty ? null : int.tryParse(_postsCtrl.text),
        'apply_link':   _applyLinkCtrl.text.trim().isEmpty ? null : _applyLinkCtrl.text.trim(),
        'notes':        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'last_date':    _lastDate!.toIso8601String().split('T')[0],
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Job posted successfully!', style: GoogleFonts.inter()),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Post a Job',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          _label('Job Title *'),
          _field(_titleCtrl, 'e.g. Bihar Police Constable 2026'),

          _label('Organisation *'),
          _field(_orgCtrl, 'e.g. Bihar Gov'),

          _label('Category *'),
          _dropdown(),

          _label('Eligibility'),
          _field(_eligibilityCtrl, 'e.g. 10th pass, age 18-25', maxLines: 2),

          _label('How to Apply'),
          _field(_howToApplyCtrl, 'e.g. Visit official website and fill form', maxLines: 2),

          _label('Salary Range'),
          _field(_salaryCtrl, 'e.g. 25000-35000'),

          _label('Total Posts'),
          _field(_postsCtrl, 'e.g. 5000',
              keyboardType: TextInputType.number),

          _label('Apply Link'),
          _field(_applyLinkCtrl, 'https://...'),

          _label('Notes (optional)'),
          _field(_notesCtrl, 'Any extra info', maxLines: 2),

          _label('Last Date to Apply *'),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Text(
                  _lastDate != null
                      ? _formatDate(_lastDate!.toIso8601String())
                      : 'Select deadline date',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _lastDate != null
                          ? AppColors.textPrimary
                          : AppColors.textHint),
                ),
                const Spacer(),
                Icon(Icons.calendar_today_rounded,
                    size: 16, color: AppColors.textSecondary),
              ]),
            ),
          ),

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
                  : Text('Post Job',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 14,
                          fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
        ]),
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

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1,
      TextInputType keyboardType = TextInputType.text}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
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
            fillColor: Colors.white,
          ),
        ),
      );

  Widget _dropdown() => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textPrimary),
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c['value'],
                        child: Text('${c['emoji']} ${c['label']}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _titleCtrl.dispose();
    _orgCtrl.dispose();
    _eligibilityCtrl.dispose();
    _howToApplyCtrl.dispose();
    _salaryCtrl.dispose();
    _postsCtrl.dispose();
    _applyLinkCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}