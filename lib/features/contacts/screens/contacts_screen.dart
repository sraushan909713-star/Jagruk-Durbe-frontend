// lib/features/contacts/screens/contacts_screen.dart
// ─────────────────────────────────────────────────────────────
// Contacts screen — shows all local contacts grouped by category.
// Category 1: Emergency (Police, Ambulance, Fire)
// Category 2: Officials (Mukhiya, BDO, Sarpanch)
// Category 3: Health (Doctor, ASHA, PHC)
// Category 4: Education (School, Anganwadi)
// Category 5: Service Providers (Plumber, Electrician, etc.)
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import 'contact_detail_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {

  List<dynamic> _contacts = [];
  bool _loading = true;
  String _selectedFilter = 'all';

  final List<Map<String, String>> _filters = [
    {'key': 'all',              'label': 'All'},
    {'key': 'emergency',        'label': 'Emergency'},
    {'key': 'official',         'label': 'Officials'},
    {'key': 'health',           'label': 'Health'},
    {'key': 'service_provider', 'label': 'Services'},
  ];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final data = await ApiService.getContacts(
        category: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      if (mounted) setState(() {
        _contacts = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _loading = true;
    });
    _loadContacts();
  }

  // — Group contacts by category ────────────────────────────
  Map<String, List<dynamic>> get _grouped {
    final Map<String, List<dynamic>> groups = {};
    for (final c in _contacts) {
      final cat = c['category'] ?? 'other';
      groups.putIfAbsent(cat, () => []).add(c);
    }
    return groups;
  }

  // — Category display names ─────────────────────────────────
  String _catLabel(String cat) {
    switch (cat) {
      case 'emergency':        return 'Emergency';
      case 'official':         return 'Officials';
      case 'health':           return 'Health';
      case 'education':        return 'Education';
      case 'service_provider': return 'Service Providers';
      default:                 return cat;
    }
  }

  // — Avatar color per category ─────────────────────────────
  Color _catColor(String cat) {
    switch (cat) {
      case 'emergency':        return const Color(0xFFFEE2E2);
      case 'official':         return AppColors.primaryLight;
      case 'health':           return const Color(0xFFEFF6FF);
      case 'education':        return const Color(0xFFF5F3FF);
      case 'service_provider': return AppColors.ctaLight;
      default:                 return AppColors.background;
    }
  }

  String _catEmoji(String cat) {
    switch (cat) {
      case 'emergency':        return '🚨';
      case 'official':         return '🏛️';
      case 'health':           return '🏥';
      case 'education':        return '📚';
      case 'service_provider': return '🔧';
      default:                 return '📞';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white, // ✅ gives back arrow automatically
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ tagline banner — consistent with all other screens
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'आपकी सेवा और सहायता के लिए',
                style: GoogleFonts.notoSansDevanagari(
                  color: Colors.white70, fontSize: 13),
              ),
            ),

            // — Filter chips ──────────────────────────────
            const SizedBox(height: 8),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final f = _filters[i];
                  final isActive = _selectedFilter == f['key'];
                  return GestureDetector(
                    onTap: () => _applyFilter(f['key']!),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        f['label']!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // — Contact list ──────────────────────────────
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _contacts.isEmpty
                      ? Center(
                          child: Text(
                            'No contacts found.',
                            style: GoogleFonts.inter(
                                color: AppColors.textHint),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(14),
                          children: _grouped.entries.map((entry) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category header
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8, bottom: 8),
                                  child: Text(
                                    _catLabel(entry.key).toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textHint,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                // Contact cards
                                ...entry.value.map((contact) =>
                                    _contactCard(contact, entry.key)),
                                const SizedBox(height: 4),
                              ],
                            );
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(dynamic contact, String category) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ContactDetailScreen(contact: contact),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _catColor(category),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _catEmoji(category),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + designation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['name'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    contact['designation'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Call button
            if (contact['phone'] != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: category == 'emergency'
                      ? const Color(0xFFDC2626)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category == 'emergency'
                      ? 'Call ${contact['phone']}'
                      : 'Call',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
// End of file
