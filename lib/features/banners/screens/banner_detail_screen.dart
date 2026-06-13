// lib/features/banners/screens/banner_detail_screen.dart
// ──────────────────────────────────────────────────────────────────
// Banner Detail Screen
//
// Opened when a villager taps any banner on the home carousel.
// Renders everything the banner has:
//   - Gradient header (using the banner's color_theme)
//   - Title, subtitle (if present), tag chip (if present), emoji icon
//   - Description (mandatory)
//   - Event info grid (date/time/location/fee — shown only if any present)
//   - Embedded YouTube player (in-app, no leaving the app)
//   - External link button (opens in browser)
//   - Tagged contacts (real users) with clickable DPs and phone call
//
// All optional blocks render conditionally — a simple meeting banner
// with just title + description still looks clean.
// ──────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/banner_themes.dart';
import '../../../core/utils/cloudinary_url.dart';

class BannerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> banner;
  const BannerDetailScreen({super.key, required this.banner});

  @override
  State<BannerDetailScreen> createState() => _BannerDetailScreenState();
}

class _BannerDetailScreenState extends State<BannerDetailScreen> {
  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    _setupYouTube();
  }

  void _setupYouTube() {
    final raw = widget.banner['youtube_link'] as String?;
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
    _ytController?.dispose();
    super.dispose();
  }

  // ─── External link launcher (reuses the schemes pattern) ───────
  Future<void> _openExternalUrl(String? raw) async {
    if (raw == null || raw.trim().isEmpty) return;
    var clean = raw.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'https://$clean';
    }
    final uri = Uri.tryParse(clean);
    if (uri == null) return;
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('लिंक नहीं खुल सका: $clean',
              style: GoogleFonts.notoSansDevanagari()),
          backgroundColor: Colors.red,
        ));
      }
    } catch (_) {}
  }

  // ─── Phone dialer ──────────────────────────────────────────────
  Future<void> _callPhone(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  // ─── Open contact DP fullscreen (pinch-zoom) ───────────────────
  void _openPhotoFullscreen(String url, String heroTag) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) =>
          _BannerPhotoViewer(url: url, heroTag: heroTag),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final b           = widget.banner;
    final theme       = BannerThemes.byKey(b['color_theme'] as String?);
    final title       = (b['title'] as String?) ?? '';
    final subtitle    = b['subtitle']    as String?;
    final icon        = b['icon']        as String?;
    final tag         = b['tag']         as String?;
    final description = (b['description'] as String?) ?? '';

    final eventLoc  = b['event_location'] as String?;
    final eventDate = b['event_date']     as String?;
    final eventTime = b['event_time']     as String?;
    final entryFee  = b['entry_fee']      as String?;
    final hasEventInfo = _hasText(eventLoc) ||
        _hasText(eventDate) ||
        _hasText(eventTime) ||
        _hasText(entryFee);

    final externalLink = b['external_link'] as String?;
    final hasExternal  = _hasText(externalLink);
    final contacts     = (b['contacts'] as List?) ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [

          // ─── Gradient header ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: theme.end,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: theme.gradient),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // bottom-up dim overlay for legibility
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end:   Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 56, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Tag chip
                            if (_hasText(tag))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  tag!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            if (_hasText(tag)) const SizedBox(height: 12),

                            // Emoji + Title row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (_hasText(icon)) ...[
                                  Text(icon!,
                                      style: const TextStyle(fontSize: 34)),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Text(
                                    title,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_hasText(subtitle)) ...[
                              const SizedBox(height: 6),
                              Text(
                                subtitle!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Body ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([

                // Description card
                _card(
                  theme: theme,
                  child: Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.7,
                    ),
                  ),
                ),

                // Event info grid
                if (hasEventInfo) ...[
                  const SizedBox(height: 12),
                  _eventInfoCard(
                      theme, eventDate, eventTime, eventLoc, entryFee),
                ],

                // YouTube embedded player
                if (_ytController != null) ...[
                  const SizedBox(height: 12),
                  _videoCard(theme),
                ],

                // External link button
                if (hasExternal) ...[
                  const SizedBox(height: 12),
                  _linkButton(theme, externalLink!),
                ],

                // Tagged contacts
                if (contacts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _contactsCard(theme, contacts),
                ],

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Reusable card shell ───────────────────────────────────────
  Widget _card({
    required Widget child,
    EdgeInsets? padding,
    BannerThemeData? theme,                                      // ✅ ADD — optional tint
  }) {
    // Soft wash of the banner's theme colour. Kept very light (~6%)
    // so text stays fully readable. Falls back to plain white card.
    final Color bg = theme != null
        ? Color.alphaBlend(theme.start.withValues(alpha: 0.06), AppColors.cardBg)   // ✅ ADD
        : AppColors.cardBg;
    final Color borderCol = theme != null
        ? theme.start.withValues(alpha: 0.30)                          // ✅ ADD
        : AppColors.border;

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,                                               // ✅ CHANGE
        border: Border.all(color: borderCol),                    // ✅ CHANGE
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  // ─── Event info card ───────────────────────────────────────────
  Widget _eventInfoCard(BannerThemeData theme, String? date, String? time,
      String? loc, String? fee) {
    final items = <_EventRow>[];
    if (_hasText(date)) {
      items.add(_EventRow(Icons.calendar_today_rounded, 'तारीख (Date)', date!));
    }
    if (_hasText(time)) {
      items.add(_EventRow(Icons.access_time_rounded, 'समय (Time)', time!));
    }
    if (_hasText(loc)) {
      items.add(_EventRow(Icons.place_rounded, 'जगह (Location)', loc!));
    }
    if (_hasText(fee)) {
      items.add(
          _EventRow(Icons.currency_rupee_rounded, 'शुल्क (Entry fee)', fee!));
    }

    return _card(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4, height: 16,
                decoration: BoxDecoration(
                  color: theme.end,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'विवरण (Details)',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.asMap().entries.map((e) => Padding(
                padding: EdgeInsets.only(
                    bottom: e.key == items.length - 1 ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.start.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(e.value.icon, size: 18, color: theme.end),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value.label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.value.value,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─── Embedded YouTube card ─────────────────────────────────────
  Widget _videoCard(BannerThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: theme.end,
        progressColors: ProgressBarColors(
          playedColor: theme.end,
          handleColor: theme.start,
        ),
      ),
    );
  }

  // ─── External link button ──────────────────────────────────────
  Widget _linkButton(BannerThemeData theme, String link) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _openExternalUrl(link),
        icon: const Icon(Icons.open_in_new_rounded,
            size: 18, color: Colors.white),
        label: Text(
          'अधिक जानकारी (More info)',
          style: GoogleFonts.notoSansDevanagari(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.end,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ─── Contacts card ─────────────────────────────────────────────
  Widget _contactsCard(BannerThemeData theme, List contacts) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4, height: 16,
                decoration: BoxDecoration(
                  color: theme.end,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'अधिक जानकारी के लिए संपर्क करें',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap on photo to enlarge · tap phone icon to call',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 14),
          ...contacts.asMap().entries.map((e) {
            final i = e.key;
            final c = e.value as Map<String, dynamic>;
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i == contacts.length - 1 ? 0 : 12),
              child: _contactRow(theme, c),
            );
          }),
        ],
      ),
    );
  }

  Widget _contactRow(BannerThemeData theme, Map<String, dynamic> contact) {
    final name     = (contact['full_name'] as String?) ?? '';
    final phone    = (contact['phone']     as String?) ?? '';
    final photo    = contact['profile_photo_url']  as String?;
    final badge    = (contact['badge']     as String?) ?? 'none';
    final userId   = contact['user_id']?.toString() ?? '';
    final hasPhoto = _hasText(photo);

    return Row(
      children: [
        GestureDetector(
          onTap: hasPhoto
              ? () => _openPhotoFullscreen(
                  photo!, 'banner_contact_$userId')
              : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Hero(
                tag: 'banner_contact_$userId',
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.start.withValues(alpha: 0.15),
                  backgroundImage: hasPhoto ? NetworkImage(CloudinaryUrl.avatar(photo!)) : null,
                  child: !hasPhoto
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.end,
                          ),
                        )
                      : null,
                ),
              ),
              if (hasPhoto)
                Positioned(
                  right: -2, bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: theme.end,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.zoom_in_rounded,
                        size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge == 'durbe_niwasi') ...[
                    const SizedBox(width: 6),
                    const Text('🏠', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                phone,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.phone_rounded),
          color: theme.end,
          tooltip: 'Call',
          onPressed: () => _callPhone(phone),
        ),
      ],
    );
  }

  bool _hasText(String? s) => s != null && s.trim().isNotEmpty;
}

// ─── Helpers ────────────────────────────────────────────────────

class _EventRow {
  final IconData icon;
  final String   label;
  final String   value;
  _EventRow(this.icon, this.label, this.value);
}

// ─── Fullscreen photo viewer (banner contact DP zoom) ──────────
class _BannerPhotoViewer extends StatelessWidget {
  final String url;
  final String heroTag;
  const _BannerPhotoViewer({required this.url, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: heroTag,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 5,
                  child: Image.network(
                    CloudinaryUrl.full(url),
                    fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white),
                      );
                    },
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.white54, size: 64),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50, right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}