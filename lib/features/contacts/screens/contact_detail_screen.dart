// lib/features/contacts/screens/contact_detail_screen.dart
// ─────────────────────────────────────────────────────────────
// Contact detail screen — shows full contact info + how to talk guide.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactDetailScreen extends StatelessWidget {
  final dynamic contact;
  const ContactDetailScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final category    = contact['category'] ?? '';
    final howToTalk   = contact['how_to_talk'];
    final address     = contact['address'];
    final officeHours = contact['office_hours'];
    final phone       = contact['phone'];

    final bool isEmergency = category == 'emergency';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Contact',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // — Contact header ─────────────────────────────
            Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: isEmergency
                        ? const Color(0xFFFEE2E2)
                        : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      isEmergency ? '🚨' : '👤',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact['name'] ?? '',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        contact['designation'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isEmergency
                              ? const Color(0xFFFEE2E2)
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isEmergency
                                ? const Color(0xFFFCA5A5)
                                : AppColors.primaryBorder,
                          ),
                        ),
                        child: Text(
                          _catLabel(category),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isEmergency
                                ? const Color(0xFF991B1B)
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // — Office hours ───────────────────────────────
            if (officeHours != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OFFICE HOURS',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      officeHours,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // — Address ────────────────────────────────────
            if (address != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Text('📍', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // — Call button ────────────────────────────────
            if (phone != null) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEmergency
                        ? const Color(0xFFDC2626)
                        : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () async {
                    // TODO: launch phone dialer
                    final uri = Uri(scheme: 'tel', path: phone);
                    try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (_) {
                        if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open phone dialer')),
                        );
                        }
                    }
                  },
                  child: Text(
                    isEmergency ? 'Call $phone' : 'Call Now',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // — How to talk guide ──────────────────────────
            if (howToTalk != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOW TO TALK',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Split how_to_talk by newlines into steps
                    ..._parseSteps(howToTalk).asMap().entries.map((e) =>
                        _stepRow(e.key + 1, e.value)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _parseSteps(String text) {
    return text
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  Widget _stepRow(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$num',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.replaceAll(RegExp(r'^\d+\.\s*'), ''),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.primary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _catLabel(String cat) {
    switch (cat) {
      case 'emergency':        return 'Emergency';
      case 'official':         return 'Official';
      case 'health':           return 'Health';
      case 'education':        return 'Education';
      case 'service_provider': return 'Service Provider';
      default:                 return cat;
    }
  }
}
