// lib/features/schemes/screens/schemes_screen.dart
// ──────────────────────────────────────────────────────────────────
// Government Schemes — list and detail view for Durbe village.
//
// Villagers can browse and search all active government schemes.
// Tapping a scheme shows full detail: eligibility, how to apply, link.
// No login required — reading is public.
//
// Categories: health, farming, education, housing, finance, women, other
//
// API methods used:
//   ApiService.getSchemes()       → GET /schemes (list, filter, search)
//   ApiService.getSchemeDetail()  → GET /schemes/{id} (full detail)
// ──────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'my_scheme_screen.dart';
import 'my_scheme_screen.dart' show MySchemeScreen;


// ── Category enum — must match backend SchemeCategory exactly ─────
const List<Map<String, String>> _categories = [
  {'value': 'health',    'label': 'Health',     'emoji': '🏥'},
  {'value': 'farming',   'label': 'Farming',    'emoji': '🌾'},
  {'value': 'education', 'label': 'Education',  'emoji': '📚'},
  {'value': 'housing',   'label': 'Housing',    'emoji': '🏠'},
  {'value': 'finance',   'label': 'Finance',    'emoji': '💰'},
  {'value': 'women',     'label': 'Women',      'emoji': '👩'},
  {'value': 'other',     'label': 'Other',      'emoji': '📌'},
];

String _catLabel(String value) {
  return _categories.firstWhere(
    (c) => c['value'] == value,
    orElse: () => {'label': value},
  )['label']!;
}

String _catEmoji(String value) {
  return _categories.firstWhere(
    (c) => c['value'] == value,
    orElse: () => {'emoji': '📌'},
  )['emoji']!;
}

Color _catColor(String cat) {
  switch (cat) {
    case 'health':    return const Color(0xFF4CAF50);
    case 'farming':   return const Color(0xFF8BC34A);
    case 'education': return const Color(0xFF9C27B0);
    case 'housing':   return const Color(0xFFFF9800);
    case 'finance':   return const Color(0xFF2196F3);
    case 'women':     return const Color(0xFFE91E63);
    default:          return AppColors.textSecondary;
  }
}


// ══════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════════
class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {

  // — State ──────────────────────────────────────────────────────
  List<dynamic> _schemes      = [];
  bool          _isLoading    = true;
  String?       _error;
  String?       _selectedCat; // null = all categories
  final         _searchCtrl   = TextEditingController();
  bool          _showSearch   = false;

  @override
  void initState() {
    super.initState();
    _fetchSchemes();
  }

  // ── GET /schemes ──────────────────────────────────────────────
  Future<void> _fetchSchemes() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final schemes = await ApiService.getSchemes(
        category: _selectedCat,
        search: _searchCtrl.text.trim().isEmpty
            ? null : _searchCtrl.text.trim(),
      );
      setState(() { _schemes = schemes; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _openDetail(dynamic scheme) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _SchemeDetailScreen(schemeId: scheme['id'])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Schemes',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ✅ Search toggle button
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  _fetchSchemes();
                }
              });
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSchemes),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // — Tagline banner ─────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MySchemeScreen())),
            child: Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'जानें और उठाएं लाभ सरकारी योजनाओं का',
                    style: GoogleFonts.notoSansDevanagari(
                      color: Colors.white70, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🌐', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 3),
                      Text('myscheme.gov.in',
                        style: GoogleFonts.inter(
                          fontSize: 10, color: Colors.white)),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // — Search bar (shown when search icon tapped) ─────────
          if (_showSearch)
            Container(
              color: AppColors.primaryDark,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'योजना खोजें...',
                  hintStyle: GoogleFonts.notoSansDevanagari(
                    color: Colors.white54, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchCtrl.clear();
                            _fetchSchemes();
                          })
                      : null,
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _fetchSchemes(),
                onChanged: (v) {
                  setState(() {});
                  if (v.isEmpty) _fetchSchemes();
                },
              ),
            ),

          // — Category filter chips ──────────────────────────────
          _buildFilterRow(),

          // — Scheme count ───────────────────────────────────────
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text('${_schemes.length} योजनाएं',
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 13, color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
            ),

          // — Main content ───────────────────────────────────────
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : _schemes.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _fetchSchemes,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                              itemCount: _schemes.length,
                              itemBuilder: (_, i) => _SchemeCard(
                                scheme: _schemes[i],
                                onTap: () => _openDetail(_schemes[i]),
                              ),
                            ),
                          )
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      color: AppColors.primaryDark,
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Center(child: _CatChip(
            label: 'All',
            isSelected: _selectedCat == null,
            onTap: () { setState(() => _selectedCat = null); _fetchSchemes(); },
          )),
          const SizedBox(width: 8),
          ..._categories.map((c) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: _CatChip(
              label: '${c['emoji']} ${c['label']}',
              isSelected: _selectedCat == c['value'],
              onTap: () {
                setState(() => _selectedCat = c['value']);
                _fetchSchemes();
              },
            )),
          )),
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
        onPressed: _fetchSchemes,
        icon: const Icon(Icons.refresh),
        label: Text('फिर कोशिश करें', style: GoogleFonts.notoSansDevanagari()),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      ),
    ]),
  ));

  Widget _buildEmpty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.list_alt_outlined, size: 72, color: Colors.grey),
      const SizedBox(height: 14),
      Text('कोई योजना नहीं मिली',
        style: GoogleFonts.notoSansDevanagari(
          color: AppColors.textSecondary, fontSize: 16,
          fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      Text('फ़िल्टर बदलकर देखें',
        style: GoogleFonts.notoSansDevanagari(
          color: AppColors.textHint, fontSize: 13)),
    ],
  ));

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
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
// SCHEME CARD — list item
// Uses SchemeListResponse: id, name, description, category, is_active
// ══════════════════════════════════════════════════════════════════
class _SchemeCard extends StatelessWidget {
  final dynamic scheme;
  final VoidCallback onTap;
  const _SchemeCard({required this.scheme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat      = (scheme['category'] as String?) ?? 'other';
    final catColor = _catColor(cat);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: catColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: catColor.withOpacity(0.25)),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // — Category emoji circle ──────────────────────────────
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(_catEmoji(cat),
                style: const TextStyle(fontSize: 22)),
            ),
          ),

          const SizedBox(width: 12),

          // — Scheme info ────────────────────────────────────────
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _catLabel(cat),
                  style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.bold, color: catColor)),
              ),

              const SizedBox(height: 6),

              // Scheme name
              Text(scheme['name'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),

              const SizedBox(height: 4),

              // Description (2 lines max)
              Text(scheme['description'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary,
                  height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),

              const SizedBox(height: 8),

              // "View details" hint
              Row(children: [
                Text('विवरण देखें',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 11, color: AppColors.primary,
                    fontWeight: FontWeight.w500)),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios,
                  size: 10, color: AppColors.primary),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════════
// SCHEME DETAIL SCREEN
// Full screen (not bottom sheet) — lots of text content
// Fetches full detail: eligibility, how_to_apply, official_link
// ══════════════════════════════════════════════════════════════════
class _SchemeDetailScreen extends StatefulWidget {
  final String schemeId;
  const _SchemeDetailScreen({required this.schemeId});

  @override
  State<_SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends State<_SchemeDetailScreen> {
  Map<String, dynamic>? _scheme;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _members    = [];
  bool          _membersLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
    _fetchMembers();
  }

  Future<void> _fetchDetail() async {
    try {
      final scheme = await ApiService.getSchemeDetail(widget.schemeId);
      setState(() { _scheme = scheme; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ✅ ADD: fetch members who are availing this scheme
  Future<void> _fetchMembers() async {
    try {
      final members = await ApiService.getSchemeMembers(widget.schemeId);
      if (mounted) setState(() { _members = members; _membersLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _membersLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = (_scheme?['category'] as String?) ?? 'other';
    final catColor = _catColor(cat);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Schemes',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    // — Header card ──────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: catColor.withOpacity(0.2))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(_catEmoji(cat), style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_scheme?['name'] ?? '',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16, fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary))),
                        ]),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20)),
                          child: Text(_catLabel(cat),
                            style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.bold,
                              color: catColor)),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // — Description ──────────────────────────────
                    _buildSection(
                      icon: Icons.info_outline,
                      title: 'योजना के बारे में',
                      content: _scheme?['description'] ?? '',
                      color: AppColors.primary,
                    ),

                    // — Eligibility ──────────────────────────────
                    _buildSection(
                      icon: Icons.verified_user_outlined,
                      title: 'पात्रता (Eligibility)',
                      content: _scheme?['eligibility'] ?? '',
                      color: const Color(0xFF2196F3),
                    ),

                    // — How to apply ─────────────────────────────
                    _buildSection(
                      icon: Icons.assignment_outlined,
                      title: 'आवेदन कैसे करें (How to Apply)',
                      content: _scheme?['how_to_apply'] ?? '',
                      color: const Color(0xFF9C27B0),
                    ),

                    // — Additional info (if present) ─────────────
                    if (_scheme?['additional_info'] != null &&
                        (_scheme!['additional_info'] as String).isNotEmpty)
                      _buildSection(
                        icon: Icons.lightbulb_outline,
                        title: 'अतिरिक्त जानकारी',
                        content: _scheme!['additional_info'],
                        color: const Color(0xFFFF9800),
                      ),

                    // — Official link button (if present) ─────────
                    if (_scheme?['official_link'] != null &&
                        (_scheme!['official_link'] as String).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // open URL in browser directly 
                            final url = Uri.parse(_scheme!['official_link']);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('लिंक नहीं खुल सका।',
                                    style: GoogleFonts.notoSansDevanagari()),
                                  backgroundColor: AppColors.error,
                                ));
                              }
                            }
                          },
                          icon: const Icon(Icons.link, color: Colors.white),
                          label: Text('सरकारी वेबसाइट खोलें',
                            style: GoogleFonts.notoSansDevanagari(
                              color: Colors.white, fontWeight: FontWeight.w500)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                    ],
                    // — Availing Members section ─────────────────
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.people_alt_outlined,
                            size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('इस योजना से लाभान्वित लोग',
                            style: GoogleFonts.notoSansDevanagari(
                              fontSize: 13, fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                          const Spacer(),
                          Text('${_members.length}',
                            style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                        ]),
                        const SizedBox(height: 12),

                        // ✅ Members list
                        if (_membersLoading)
                          Center(child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2))
                        else if (_members.isEmpty)
                          Center(child: Text('अभी कोई नहीं जुड़ा',
                            style: GoogleFonts.notoSansDevanagari(
                              color: AppColors.textHint, fontSize: 13)))
                        else
                          ..._members.map((m) => _MemberTile(member: m)),
                      ]),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
    );
  }

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
        color: color.withOpacity(0.07),        // ✅ CHANGE — was AppColors.cardBg
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25))),  // ✅ CHANGE — was AppColors.border
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(title, style: GoogleFonts.notoSansDevanagari(
            fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 8),
        Text(content, style: GoogleFonts.notoSansDevanagari(
          fontSize: 14, color: AppColors.textPrimary, height: 1.65)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// MEMBER TILE — shows one person availing a scheme
// ══════════════════════════════════════════════════════════════════
class _MemberTile extends StatelessWidget {
  final dynamic member;
  
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final gender   = member['gender'] ?? 'male';
    final isFemale = gender == 'female';
    final sinceDate = member['since_date'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        // ✅ Profile photo or gender icon
        CircleAvatar(
          radius: 20,
          backgroundColor: isFemale
              ? const Color(0xFFFCE4EC)
              : const Color(0xFFE3F2FD),
          backgroundImage: member['photo_url'] != null
              ? NetworkImage(member['photo_url']) : null,
          child: member['photo_url'] == null
              ? Text(isFemale ? '👩' : '👨',
                  style: const TextStyle(fontSize: 18))
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(member['name'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
            Text(
              '${isFemale ? 'पति' : 'पिता'}: ${member['relative_name'] ?? ''}',
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
        // ✅ Since date
        Text(sinceDate,
          style: GoogleFonts.inter(
            fontSize: 11, color: AppColors.textHint)),
      ]),
    );
  }
}