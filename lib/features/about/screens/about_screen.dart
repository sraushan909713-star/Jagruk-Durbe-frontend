// lib/features/about/screens/about_screen.dart
// ═══════════════════════════════════════════════════════════════════════════
// About / Guide page — bilingual (English / Hindi) with simultaneous wipe.
//
// DELIVERY 3 (this version):
//   ✅ NEW — Hindi/English toggle pill in the header
//   ✅ NEW — Simultaneous left-to-right wipe reveal on language switch
//            (all blocks animate together — whichever block the user is
//             looking at, IT animates right away — no top-to-bottom wait)
//   ✅ NEW — All 8 feature paragraphs available in Hindi
//   ✅ NEW — Intro header bilingual
//   ✅ NEW — Closing line bilingual
//   ✅ NEW — Hindi subtitles update with main titles
//   Tribute STAYS English regardless of toggle (locked decision).
//
// DELIVERY 4 (this version adds):
//   ✅ NEW — "Three Layers" foundation section between intro and features.
//            Explains Admin / Verified Villager / User permission system.
//            Uses three_layers.svg (figures only — captions are Flutter Text
//            widgets so the EN|हिं toggle works on them naturally).
//   ✅ NEW — "Banners" info card after the 8 features.
//   ✅ NEW — "Today's Weather" info card after Banners.
//            Both are slim text-only cards (no illustration zone) — the
//            banner and weather are already visible on the home screen,
//            so the About copy just names them and explains what they're for.
//
// All Hindi text is the locked, finalized version from the translation
// rounds. No fresh translation — only the words Raushan approved.
//
// What's still missing (later deliveries):
//   - Real entry points: home "?" + Profile row + welcome card 4 button (D5)
//   - Tribute photo (D5)
//   - Welcome cards build (D4)
//
// Feature green for this page = #1A8870 (locked across this feature).
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatefulWidget {                       // ✅ CHANGE — now Stateful (for toggle + animation)
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {

  // ══ About-feature palette ══════════════════════════════════════════════════
  static const Color _green     = Color(0xFF1A8870);
  static const Color _greenDark = Color(0xFF114F44);
  static const Color _terracotta= Color(0xFFC2440A);
  static const Color _bg        = Color(0xFFFAFAF7);
  static const Color _ink       = Color(0xFF1F2937);
  static const Color _body      = Color(0xFF374151);
  static const Color _border    = Color(0xFFE5E7EB);

  // ══ Language state ═════════════════════════════════════════════════════════
  bool _isHindi = false;
  bool _animating = false;   // blocks rapid re-taps mid-animation

  // Master animation controller — drives the cascading wipe across all
  // text blocks on the page. Each block reads its own slice of progress
  // based on its index. Slower than a cascade ("a touch slower" — locked).
  late final AnimationController _wipeCtrl;

  // ✅ NEW (Delivery 3.5) — Scroll controller so feature cards can detect
  // when they enter the viewport and trigger their reveal animation.
  final ScrollController _scrollCtrl = ScrollController();

  // Every animated text block registers itself with an index so the
  // wipe progresses top-to-bottom in registration order.
  int _blockCount = 0;

  // ✅ CHANGE — wipe is now SIMULTANEOUS across all blocks (stagger = 0).
  // Top-to-bottom cascading was confusing when the user was scrolled to the
  // bottom — they'd see nothing for a while, then the last block animates.
  // With simultaneous, whichever block the user is looking at animates right
  // away. Per-block is also slower now so the wipe feels deliberate, not a
  // flicker.
  static const Duration _wipePerBlock = Duration(milliseconds: 950);
  static const Duration _wipeStagger  = Duration.zero;

  @override
  void initState() {
    super.initState();
    _wipeCtrl = AnimationController(vsync: this);
    _countBlocks();   // pre-count so total duration is known up front
  }

  @override
  void dispose() {
    _wipeCtrl.dispose();
    _scrollCtrl.dispose();                              // ✅ NEW (D3.5)
    super.dispose();
  }

  // We pre-count the bilingual text blocks: 1 intro title + 1 intro body
  // + 4 three-layers blocks + (1 title + 1 subtitle + N paragraphs) per
  // feature + 2 banner + 2 weather + 1 closing.
  void _countBlocks() {
    int n = 2; // intro title + intro body
    n += 4;    // ✅ NEW (D4) — three layers (title + intro + roles + tagline)
    for (final f in _features) {
      n += 2 + f.paragraphsEn.length; // title, subtitle, then paragraphs
    }
    n += 2;    // ✅ NEW (D4) — banners (title + body)
    n += 2;    // ✅ NEW (D4) — weather (title + body)
    n += 1;    // closing line
    _blockCount = n;
  }

  void _toggleLanguage() {
    if (_animating) return;
    setState(() {
      _isHindi = !_isHindi;
      _animating = true;
    });

    // Total duration: with stagger = 0, all blocks finish in per-block time.
    // (Kept generic so if stagger is ever re-introduced the math still works.)
    final total = _wipePerBlock + _wipeStagger * (_blockCount - 1);
    _wipeCtrl
      ..duration = total
      ..forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _animating = false);
      });
  }

  @override
  Widget build(BuildContext context) {
    final sections = _features;
    int blockIdx = 0;   // top-to-bottom registration counter

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isHindi ? 'इस ऐप के बारे में' : 'About this app',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18, fontWeight: FontWeight.w600, color: _ink,
          ),
        ),
        actions: [
          // ✅ NEW — Hindi/English toggle pill
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _languageToggle(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollCtrl,                          // ✅ NEW (D3.5)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro header
            _introHeader(
              titleBlockIdx: blockIdx++,
              bodyBlockIdx:  blockIdx++,
            ),
            const SizedBox(height: 4),

            // ✅ NEW (D4) — Three Layers foundation section.
            // Sits between intro and features because this question
            // ("why three roles?") comes BEFORE users care about features.
            // IIFE for the same reason features below use IIFEs: closure
            // capture-by-reference would share blockIdx across the children.
            // ✅ FIX (D4.1) — wrapped in _RevealOnScroll so the card fades
            // in and the SVG sweeps diagonally on first viewport entry,
            // matching the 8 feature cards below.
            (() {
              final titleIdx   = blockIdx++;
              final introIdx   = blockIdx++;
              final rolesIdx   = blockIdx++;
              final taglineIdx = blockIdx++;
              return _RevealOnScroll(
                scrollController: _scrollCtrl,
                builder: (cardProgress, illoSweep) => _threeLayersSection(
                  titleIdx:     titleIdx,
                  introIdx:     introIdx,
                  rolesIdx:     rolesIdx,
                  taglineIdx:   taglineIdx,
                  cardProgress: cardProgress,
                  illoSweep:    illoSweep,
                ),
              );
            })(),

            // 8 feature cards — each registers its own block indices
            // ✅ NEW (D3.5) — each card now wrapped in _RevealOnScroll so it
            // fades + slides up when scrolled into view, and its illustration
            // sweeps in diagonally (the "draws itself in" effect, locked in
            // the May 16 design phase but missed from earlier deliveries).
            //
            // NOTE: indices are captured into LOCAL final values BEFORE the
            // builder closure, because closures in Dart capture by reference
            // — if we did `titleIdx: blockIdx++` inside the closure, all 8
            // closures would share the same blockIdx and see its final value.
            for (int i = 0; i < sections.length; i++)
              (() {
                final f = sections[i];
                final cardTitleIdx    = blockIdx++;
                final cardSubtitleIdx = blockIdx++;
                final cardFirstPara   = blockIdx;
                blockIdx += f.paragraphsEn.length;
                return _RevealOnScroll(
                  scrollController: _scrollCtrl,
                  builder: (cardProgress, illoSweep) => _featureCard(
                    f, i + 1, sections.length,
                    titleIdx:     cardTitleIdx,
                    subtitleIdx:  cardSubtitleIdx,
                    firstParaIdx: cardFirstPara,
                    cardProgress: cardProgress,
                    illoSweep:    illoSweep,
                  ),
                );
              })(),

            // ✅ NEW (D4) — Banners info card. No illustration — the banner
            // is already visible on the home screen, so the About copy just
            // names it and explains what it's for.
            (() {
              final titleIdx = blockIdx++;
              final bodyIdx  = blockIdx++;
              return _homeScreenInfoCard(
                titleIdx:    titleIdx,
                bodyIdx:     bodyIdx,
                titleEn:     _bannersTitleEn,
                titleHi:     _bannersTitleHi,
                bodyEn:      _bannersBodyEn,
                bodyHi:      _bannersBodyHi,
                icon:        Icons.campaign_outlined,
                accentColor: const Color(0xFF7A2D08),
              );
            })(),

            // ✅ NEW (D4) — Today's Weather info card.
            (() {
              final titleIdx = blockIdx++;
              final bodyIdx  = blockIdx++;
              return _homeScreenInfoCard(
                titleIdx:    titleIdx,
                bodyIdx:     bodyIdx,
                titleEn:     _weatherTitleEn,
                titleHi:     _weatherTitleHi,
                bodyEn:      _weatherBodyEn,
                bodyHi:      _weatherBodyHi,
                icon:        Icons.wb_cloudy_outlined,
                accentColor: const Color(0xFF1F5F7A),
              );
            })(),

            // Closing line
            _closingLine(blockIdx: blockIdx++),

            // Tribute (NOT animated, NOT bilingual — locked English)
            _tribute(),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ══ Hindi/English toggle pill ══════════════════════════════════════════════
  Widget _languageToggle() {                                     // ✅ NEW
    return GestureDetector(
      onTap: _toggleLanguage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: _green.withValues(alpha: 0.10),
          border: Border.all(color: _green.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _togglePillSide(label: 'EN', active: !_isHindi),
            _togglePillSide(label: 'हिं', active: _isHindi),
          ],
        ),
      ),
    );
  }

  Widget _togglePillSide({required String label, required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? _green : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: (label == 'हिं'
                ? GoogleFonts.notoSansDevanagari
                : GoogleFonts.inter)(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : _green,
        ),
      ),
    );
  }

  // ══ Intro header ═══════════════════════════════════════════════════════════
  Widget _introHeader({required int titleBlockIdx, required int bodyBlockIdx}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_green, _greenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WipeText(
            blockIdx: titleBlockIdx,
            controller: _wipeCtrl,
            isHindi: _isHindi,
            animating: _animating,
            blockCount: _blockCount,
            perBlock: _wipePerBlock,
            stagger: _wipeStagger,
            child: Text(
              _isHindi
                  ? 'यह ऐप किसलिए है'
                  : 'What this app is for',
              style: (_isHindi
                      ? GoogleFonts.notoSansDevanagari
                      : GoogleFonts.playfairDisplay)(
                fontSize: 22, fontWeight: FontWeight.w600,
                color: Colors.white, height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 9),
          _WipeText(
            blockIdx: bodyBlockIdx,
            controller: _wipeCtrl,
            isHindi: _isHindi,
            animating: _animating,
            blockCount: _blockCount,
            perBlock: _wipePerBlock,
            stagger: _wipeStagger,
            child: Text(
              _isHindi ? _introHi : _introEn,
              style: (_isHindi
                      ? GoogleFonts.notoSansDevanagari
                      : GoogleFonts.inter)(
                fontSize: 13, height: 1.65,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══ One feature card (Design B) ════════════════════════════════════════════
  Widget _featureCard(_Feature f, int number, int total, {
    required int titleIdx,
    required int subtitleIdx,
    required int firstParaIdx,
    required Animation<double> cardProgress,             // ✅ NEW (D3.5)
    required Animation<double> illoSweep,                // ✅ NEW (D3.5)
  }) {
    // ✅ NEW (D3.5) — fade in + slide up as the card enters the viewport.
    // cardProgress runs 0→1 over the first ~40% of the reveal duration.
    return AnimatedBuilder(
      animation: cardProgress,
      builder: (context, child) {
        return Opacity(
          opacity: cardProgress.value,
          child: Transform.translate(
            offset: Offset(0, (1 - cardProgress.value) * 16),
            child: child,
          ),
        );
      },
      child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14, offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coloured header zone (illustration + badge)
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [f.zoneLight, f.zoneDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: _illustrationFor(f, illoSweep),  // ✅ CHANGE (D3.5)
                ),
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    width: 26, height: 26,
                    decoration: const BoxDecoration(
                      color: _green, shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$number',
                      style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Text block
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The FEATURE n OF 8 label — not animated (small UI label)
                  Text(
                    _isHindi
                        ? 'फ़ीचर $number / $total'
                        : 'FEATURE $number OF $total',
                    style: (_isHindi
                            ? GoogleFonts.notoSansDevanagari
                            : GoogleFonts.inter)(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 0.5, color: _terracotta,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Title (animated)
                  _WipeText(
                    blockIdx: titleIdx,
                    controller: _wipeCtrl,
                    isHindi: _isHindi,
                    animating: _animating,
                    blockCount: _blockCount,
                    perBlock: _wipePerBlock,
                    stagger: _wipeStagger,
                    child: Text(
                      _isHindi ? f.titleHi : f.titleEn,
                      style: (_isHindi
                              ? GoogleFonts.notoSansDevanagari
                              : GoogleFonts.playfairDisplay)(
                        fontSize: 19, fontWeight: FontWeight.w600, color: _ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Subtitle (animated) — only appears when EN is on
                  // (in Hindi mode, the title IS Hindi so subtitle would be
                  // a duplicate. So in Hindi mode we show the English title
                  // as the subtitle — keeps the bilingual feel balanced.)
                  _WipeText(
                    blockIdx: subtitleIdx,
                    controller: _wipeCtrl,
                    isHindi: _isHindi,
                    animating: _animating,
                    blockCount: _blockCount,
                    perBlock: _wipePerBlock,
                    stagger: _wipeStagger,
                    child: Text(
                      _isHindi ? f.titleEn : f.subtitleHi,
                      style: (_isHindi
                              ? GoogleFonts.inter
                              : GoogleFonts.notoSansDevanagari)(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: _terracotta,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Paragraphs (each animated, each its own block)
                  for (int p = 0;
                       p < (_isHindi ? f.paragraphsHi : f.paragraphsEn).length;
                       p++) ...[
                    _WipeText(
                      blockIdx: firstParaIdx + p,
                      controller: _wipeCtrl,
                      isHindi: _isHindi,
                      animating: _animating,
                      blockCount: _blockCount,
                      perBlock: _wipePerBlock,
                      stagger: _wipeStagger,
                      child: Text(
                        (_isHindi ? f.paragraphsHi : f.paragraphsEn)[p],
                        style: (_isHindi
                                ? GoogleFonts.notoSansDevanagari
                                : GoogleFonts.inter)(
                          fontSize: 13.5, height: 1.72, color: _body,
                        ),
                      ),
                    ),
                    if (p != (_isHindi ? f.paragraphsHi : f.paragraphsEn).length - 1)
                      const SizedBox(height: 11),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),                                                  // ✅ NEW (D3.5) — closes AnimatedBuilder child
    );
  }

  // ── Illustration switch: real SVG if asset is set, else placeholder ──
  // ✅ CHANGE (D3.5) — illustration now revealed via a diagonal ShaderMask
  // sweep that runs as the card enters the viewport. This is the closest
  // pure-Flutter approximation of the "drawing itself in" effect that
  // delighted Raushan during the original SVG-streaming preview.
  Widget _illustrationFor(_Feature f, Animation<double> sweep) {
    final Widget content;
    if (f.illustrationAsset == null) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined,
                size: 30, color: Colors.white.withValues(alpha: 0.55)),
            const SizedBox(height: 4),
            Text(
              'illustration',
              style: GoogleFonts.inter(
                fontSize: 10, color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: SvgPicture.asset(f.illustrationAsset!, fit: BoxFit.contain),
      );
    }

    // Diagonal sweep reveal. Wraps content in a ShaderMask whose gradient
    // moves from upper-left to lower-right as sweep.value goes 0→1.
    return AnimatedBuilder(
      animation: sweep,
      builder: (context, _) {
        final t = sweep.value;
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            // Diagonal gradient: revealed area is opaque white, then a
            // soft edge (the "drawing tip"), then transparent.
            // We compute the diagonal extent and slide the visible region.
            final diag = bounds.width + bounds.height;
            final cut  = (diag * t).clamp(0.0, diag);
            final edge = 60.0;     // soft pencil-edge width
            final stop1 = (cut / diag).clamp(0.0, 1.0);
            final stop2 = ((cut + edge) / diag).clamp(0.0, 1.0);
            return LinearGradient(
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
              colors: const [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, stop1, stop2],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: content,
        );
      },
    );
  }

  // ══ Closing line ═══════════════════════════════════════════════════════════
  Widget _closingLine({required int blockIdx}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Divider(color: _border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: 5, height: 5,
                  decoration: const BoxDecoration(
                    color: _terracotta, shape: BoxShape.circle,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: _border)),
            ],
          ),
          const SizedBox(height: 16),
          _WipeText(
            blockIdx: blockIdx,
            controller: _wipeCtrl,
            isHindi: _isHindi,
            animating: _animating,
            blockCount: _blockCount,
            perBlock: _wipePerBlock,
            stagger: _wipeStagger,
            child: Text(
              _isHindi ? _closingHi : _closingEn,
              textAlign: TextAlign.center,
              style: (_isHindi
                      ? GoogleFonts.notoSansDevanagari
                      : GoogleFonts.inter)(
                fontSize: 13, height: 1.7, color: _body,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══ Grandfather's tribute — ENGLISH ONLY, NOT animated ═════════════════════
  Widget _tribute() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 0),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ CHANGE (D5) — grandfather's photo replaces the placeholder
            ClipOval(
              child: Image.asset(
                'assets/illustrations/grandfather.jpg',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                // If the file is missing or fails to load, fall back to a
                // soft grey circle so the page never breaks.
                errorBuilder: (context, error, stack) => Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDE8),
                    shape: BoxShape.circle,
                    border: Border.all(color: _border),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Thought and Built by the\ngrandson of Chandu Yadav',
              style: GoogleFonts.inter(
                fontSize: 11, height: 1.5,
                color: Colors.black.withValues(alpha: 0.40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══ Three Layers foundation section ════════════════════════════════════════
  // Custom layout — looks like a feature card but with a "FOUNDATION" label
  // instead of "FEATURE n OF 8", a slate-toned gradient zone (visually
  // distinct from any feature), the three_layers.svg illustration, the
  // three role descriptions as a tight list, and a bilingual tagline.
  //
  // All four text blocks (title, intro, roles, tagline) are wired into the
  // _WipeText animation system so the Hindi/English toggle wipes them too.
  //
  // ✅ FIX (D4.1) — accepts the two reveal animations (cardProgress + illoSweep)
  // from the parent _RevealOnScroll, so this section gets the same scroll-in
  // behaviour as the 8 feature cards below.
  Widget _threeLayersSection({
    required int titleIdx,
    required int introIdx,
    required int rolesIdx,
    required int taglineIdx,
    required Animation<double> cardProgress,
    required Animation<double> illoSweep,
  }) {
    final rolesEn = _threeLayersRolesEn;
    final rolesHi = _threeLayersRolesHi;
    final roles = _isHindi ? rolesHi : rolesEn;

    // Outer AnimatedBuilder: card fade-in + slide-up over the first ~40%
    // of the reveal duration. Same shape as _featureCard.
    return AnimatedBuilder(
      animation: cardProgress,
      builder: (context, child) {
        return Opacity(
          opacity: cardProgress.value,
          child: Transform.translate(
            offset: Offset(0, (1 - cardProgress.value) * 16),
            child: child,
          ),
        );
      },
      child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14, offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slate-toned header zone — distinct from any feature card colour
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE6ECEF), Color(0xFFC8D3D8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label (small, not animated — same pattern as FEATURE n OF 8)
                  Text(
                    _isHindi ? 'बुनियाद' : 'FOUNDATION',
                    style: (_isHindi
                            ? GoogleFonts.notoSansDevanagari
                            : GoogleFonts.inter)(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 0.5, color: _greenDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title (animated)
                  _WipeText(
                    blockIdx: titleIdx,
                    controller: _wipeCtrl,
                    isHindi: _isHindi,
                    animating: _animating,
                    blockCount: _blockCount,
                    perBlock: _wipePerBlock,
                    stagger: _wipeStagger,
                    child: Text(
                      _isHindi ? _threeLayersTitleHi : _threeLayersTitleEn,
                      style: (_isHindi
                              ? GoogleFonts.notoSansDevanagari
                              : GoogleFonts.playfairDisplay)(
                        fontSize: 20, fontWeight: FontWeight.w600, color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Intro paragraph (animated)
                  _WipeText(
                    blockIdx: introIdx,
                    controller: _wipeCtrl,
                    isHindi: _isHindi,
                    animating: _animating,
                    blockCount: _blockCount,
                    perBlock: _wipePerBlock,
                    stagger: _wipeStagger,
                    child: Text(
                      _isHindi ? _threeLayersIntroHi : _threeLayersIntroEn,
                      style: (_isHindi
                              ? GoogleFonts.notoSansDevanagari
                              : GoogleFonts.inter)(
                        fontSize: 13.5, height: 1.72, color: _body,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // The illustration (figures-only — captions are Flutter
                  // Text widgets so the EN|हिं toggle works on them).
                  // ✅ FIX (D4.1) — wrapped in AnimatedBuilder + ShaderMask
                  // for the diagonal sweep reveal, matching _illustrationFor.
                  Center(
                    child: AnimatedBuilder(
                      animation: illoSweep,
                      builder: (context, _) {
                        final t = illoSweep.value;
                        return ShaderMask(
                          shaderCallback: (Rect bounds) {
                            final diag = bounds.width + bounds.height;
                            final cut  = (diag * t).clamp(0.0, diag);
                            const edge = 60.0;
                            final stop1 = (cut / diag).clamp(0.0, 1.0);
                            final stop2 = ((cut + edge) / diag).clamp(0.0, 1.0);
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end:   Alignment.bottomRight,
                              colors: const [Colors.white, Colors.white, Colors.transparent],
                              stops: [0.0, stop1, stop2],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: SvgPicture.asset(
                            'assets/illustrations/three_layers.svg',
                            width: 230,
                            fit: BoxFit.contain,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Role descriptions (animated as a single block — keeps the
                  // wipe coherent across the list).
                  _WipeText(
                    blockIdx: rolesIdx,
                    controller: _wipeCtrl,
                    isHindi: _isHindi,
                    animating: _animating,
                    blockCount: _blockCount,
                    perBlock: _wipePerBlock,
                    stagger: _wipeStagger,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < roles.length; i++) ...[
                          _roleLine(roles[i][0], roles[i][1]),
                          if (i != roles.length - 1)
                            const SizedBox(height: 9),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Tagline (italic, centered, animated)
                  _WipeText(
                    blockIdx: taglineIdx,
                    controller: _wipeCtrl,
                    isHindi: _isHindi,
                    animating: _animating,
                    blockCount: _blockCount,
                    perBlock: _wipePerBlock,
                    stagger: _wipeStagger,
                    child: Center(
                      child: Text(
                        _isHindi ? _threeLayersTaglineHi : _threeLayersTaglineEn,
                        style: (_isHindi
                                ? GoogleFonts.notoSansDevanagari
                                : GoogleFonts.playfairDisplay)(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: _terracotta,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),  // closes AnimatedBuilder child Padding
    );
  }

  // Single role row inside the Three Layers card — bold name, dash, body.
  Widget _roleLine(String name, String desc) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: name,
            style: (_isHindi
                    ? GoogleFonts.notoSansDevanagari
                    : GoogleFonts.inter)(
              fontSize: 13.5, fontWeight: FontWeight.w700,
              color: _greenDark, height: 1.55,
            ),
          ),
          TextSpan(
            text: '  —  ',
            style: GoogleFonts.inter(
              fontSize: 13.5, color: _border, height: 1.55,
            ),
          ),
          TextSpan(
            text: desc,
            style: (_isHindi
                    ? GoogleFonts.notoSansDevanagari
                    : GoogleFonts.inter)(
              fontSize: 13.5, color: _body, height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ══ Home-screen info card — used for Banners and Weather ═══════════════════
  // Slim card with an icon + title row, then body paragraph. No illustration
  // zone — these features are already visible on the home screen, so the About
  // copy just names them and explains their purpose.
  Widget _homeScreenInfoCard({
    required int titleIdx,
    required int bodyIdx,
    required String titleEn,
    required String titleHi,
    required String bodyEn,
    required String bodyHi,
    required IconData icon,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + title row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WipeText(
                    blockIdx: titleIdx,
                    controller: _wipeCtrl,
                    isHindi: _isHindi,
                    animating: _animating,
                    blockCount: _blockCount,
                    perBlock: _wipePerBlock,
                    stagger: _wipeStagger,
                    child: Text(
                      _isHindi ? titleHi : titleEn,
                      style: (_isHindi
                              ? GoogleFonts.notoSansDevanagari
                              : GoogleFonts.playfairDisplay)(
                        fontSize: 16.5, fontWeight: FontWeight.w600, color: _ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Body paragraph (animated)
            _WipeText(
              blockIdx: bodyIdx,
              controller: _wipeCtrl,
              isHindi: _isHindi,
              animating: _animating,
              blockCount: _blockCount,
              perBlock: _wipePerBlock,
              stagger: _wipeStagger,
              child: Text(
                _isHindi ? bodyHi : bodyEn,
                style: (_isHindi
                        ? GoogleFonts.notoSansDevanagari
                        : GoogleFonts.inter)(
                  fontSize: 13.5, height: 1.72, color: _body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══ Locked English + Hindi text — all approved by Raushan ══════════════════

  static const String _introEn =
      'This app is built for the people of Durbe — to make your life '
      'easier, to keep you informed, and to help you use technology to '
      'solve your own problems. Each feature here helps with a real '
      'problem. Below is a short guide to what each one does for you.';

  static const String _introHi =
      'यह ऐप दुर्बे के लोगों के लिए बनाया गया है — आपका जीवन आसान बनाने '
      'के लिए, आपको जानकारी देते रहने के लिए, और तकनीक की मदद से आप '
      'अपनी समस्याएँ ख़ुद हल कर सकें, इसके लिए। यहाँ का हर फ़ीचर किसी '
      'असली समस्या में मदद करता है। नीचे एक छोटी जानकारी दी गई है कि हर '
      'फ़ीचर आपके लिए क्या करता है।';

  static const String _closingEn =
      'Thank you for reading this far. Each of these features grows '
      'stronger as more people of Durbe take part.';

  static const String _closingHi =
      'यहाँ तक पढ़ने के लिए धन्यवाद। दुर्बे के जितने ज़्यादा लोग साथ आएँगे, '
      'इनमें से हर सुविधा उतनी ही मज़बूत होगी।';

  // ══ Three Layers section text — locked copy ════════════════════════════════
  // Foundation section explaining the User / Verified Villager / Admin
  // permission system. Sits between intro and the 8 features.

  static const String _threeLayersTitleEn   = 'Three roles. One reason.';
  static const String _threeLayersTitleHi   = 'तीन रोल. एक वजह.';

  static const String _threeLayersIntroEn =
      'Anyone in India can install this app. Verification keeps your '
      'village\'s voice yours — not someone else\'s.';
  static const String _threeLayersIntroHi =
      'कोई भी इस ऐप को install कर सकता है। Verification सुनिश्चित करती है '
      'कि गाँव की आवाज़ गाँव की रहे — बाहर वालों की नहीं।';

  // Role lines render as a tight bilingual list inside the card.
  // Each list item is "Role — action description".
  static const List<List<String>> _threeLayersRolesEn = [
    ['Admin',             'Moderates content. Chosen from Durbe itself, not appointed from outside.'],
    ['Verified Villager', 'Files complaints, signs petitions, rates netas, lists crops.'],
    ['User',              'Reads everything. Cannot post.'],
  ];
  static const List<List<String>> _threeLayersRolesHi = [
    ['Admin',         'Moderate करते हैं। दुर्बे के अंदर से चुने गए, बाहर से नहीं।'],
    ['Verified गाँववाला', 'शिकायत डालते हैं, याचिका पर हस्ताक्षर, नेता को rating, फसल listing।'],
    ['User',          'सब पढ़ सकते हैं। post नहीं कर सकते।'],
  ];

  static const String _threeLayersTaglineEn = 'Apna gaon, apne log.';
  static const String _threeLayersTaglineHi = 'अपना गाँव, अपने लोग।';

  // ══ Banners section text — locked copy ═════════════════════════════════════
  static const String _bannersTitleEn = 'What\'s on the banner?';
  static const String _bannersTitleHi = 'यह banner क्या दिखाता है?';

  static const String _bannersBodyEn =
      'The card at the top of your home screen. When something matters right '
      'now — a blood need, power outage, festival drive, tournament, weather '
      'warning — it lives here until it\'s done. Then it\'s gone.';
  static const String _bannersBodyHi =
      'Home screen पर सबसे ऊपर वाला card। जब कुछ अभी ज़रूरी हो — blood की '
      'ज़रूरत, बिजली कटौती, त्योहार चंदा, टूर्नामेंट, मौसम चेतावनी — तब तक यहाँ '
      'रहता है जब तक ज़रूरत है। फिर हट जाता है।';

  // ══ Weather section text — locked copy ═════════════════════════════════════
  static const String _weatherTitleEn = 'Today\'s weather, right above.';
  static const String _weatherTitleHi = 'आज का मौसम, सबसे ऊपर।';

  static const String _weatherBodyEn =
      'Temperature, rain probability, day\'s high and low. Plan your farming '
      'and your day around it.';
  static const String _weatherBodyHi =
      'तापमान, बारिश की संभावना, अधिकतम-न्यूनतम। अपनी खेती और अपना दिन '
      'इसी हिसाब से plan करें।';

  // ══ The 8 feature sections — locked copy in BOTH languages ═════════════════
  static final List<_Feature> _features = [
    _Feature(
      titleEn: 'Schemes',
      titleHi: 'सरकारी योजनाएँ',
      subtitleHi: 'सरकारी योजनाएँ',
      zoneLight: const Color(0xFFDCEFE6),
      zoneDark:  const Color(0xFFC3E3D4),
      illustrationAsset: 'assets/illustrations/schemes.svg',
      paragraphsEn: const [
        'Most of us do not even know how many government schemes are running '
        'for us right now. And these are not for one kind of person — there '
        'is something for farmers, for students, for women, for the elderly '
        'above 70.',
        'Jagruk Durbe and its volunteers work to make sure every scheme '
        'reaches every person in the village. These schemes are added by the '
        'admins. For each scheme you will see what it is, who it is for, what '
        'you get, and what papers you need. The feature also shows the list '
        'of people who are already availing it.',
      ],
      paragraphsHi: const [
        'हममें से ज़्यादातर लोगों को तो यह भी पता नहीं कि इस वक़्त हमारे लिए '
        'कितनी सरकारी योजनाएँ चल रही हैं। और ये किसी एक तरह के इंसान के '
        'लिए नहीं हैं — किसान के लिए, छात्र के लिए, महिलाओं के लिए, और '
        '70 साल से ऊपर के बुज़ुर्गों के लिए, सबके लिए कुछ न कुछ है।',
        'जागरूक दुर्बे और इसके लोग यह कोशिश करते हैं कि हर योजना गाँव के '
        'हर इंसान तक पहुँचे। ये योजनाएँ एडमिन के द्वारा जोड़ी जाती हैं। हर '
        'योजना के बारे में आपको दिखेगा — वह क्या है, किसके लिए है, आपको '
        'क्या मिलेगा, और कौन-से कागज़ चाहिए। यह भी दिखता है कि कौन-कौन '
        'लोग पहले से इसका लाभ ले रहे हैं।',
      ],
    ),
    _Feature(
      titleEn: 'Job Alerts',
      titleHi: 'नौकरी की सूचना',
      subtitleHi: 'नौकरी की सूचना',
      zoneLight: const Color(0xFFDCE6F5),
      zoneDark:  const Color(0xFFB9CFE6),
      illustrationAsset: 'assets/illustrations/job_alerts.svg',
      paragraphsEn: const [
        'Often we miss a job simply because we did not know the last date to '
        'apply — or we were unsure whether we are even eligible. And '
        'sometimes we do not even know that a vacancy has come out, and its '
        'last date passes by. That will not happen anymore.',
        'The app lists job openings, private or government, along with the '
        'number of vacancies. The ones with a deadline coming soon show up '
        'at the top. It also shows the list of candidates from the village '
        'who have already applied, added by the admin.',
      ],
      paragraphsHi: const [
        'अक्सर हमसे नौकरी इसलिए छूट जाती है क्योंकि हमें आवेदन की आख़िरी '
        'तारीख़ का पता ही नहीं चलता — या यह पता नहीं होता कि हम उसके लिए '
        'योग्य हैं या नहीं। और कभी-कभी तो हमें यह पता ही नहीं चलता कि कोई '
        'बहाली निकली हुई है, और उसकी आख़िरी तारीख़ भी निकल जाती है। '
        'अब ऐसा नहीं होगा।',
        'यह ऐप नौकरियों की सूचना देता है — चाहे प्राइवेट हो या सरकारी — और '
        'कितनी जगहें खाली हैं यह भी बताता है। जिनकी आख़िरी तारीख़ नज़दीक '
        'होती है, वे सबसे ऊपर दिखती हैं। यह उन लोगों की सूची भी दिखाता है '
        'जो गाँव से पहले ही आवेदन कर चुके हैं, जिसे एडमिन द्वारा ही जोड़ा '
        'जाता है।',
      ],
    ),
    _Feature(
      titleEn: 'Gram Awaaz',
      titleHi: 'ग्राम आवाज़',
      subtitleHi: 'ग्राम आवाज़',
      zoneLight: const Color(0xFFF5E0D6),
      zoneDark:  const Color(0xFFE6B79E),
      illustrationAsset: 'assets/illustrations/gram_awaaz.svg',
      paragraphsEn: const [
        'A broken road, a blocked drain — a problem everyone talks about, '
        'but no record of it stays anywhere. Good roads, clean drainage — '
        'these are not favours. They are your right.',
        'Here you can report any problem in the village with a photo and its '
        'location. When others mark that it affects them too, it becomes a '
        'record — proof that it is not one person complaining, but the whole '
        'village asking.',
        'And even if no action is taken, the problem stays on record — '
        'recorded and kept by the people of Jagruk Durbe, including since '
        'when it has existed. The Durbe Dak Sthan ground, for example, was '
        'promised long ago. It is still needed, and to this day it has not '
        'been built.',
      ],
      paragraphsHi: const [
        'टूटी सड़क, बंद पड़ी नाली — ऐसी समस्या जिसकी बात तो सब करते हैं, पर '
        'उसका रिकॉर्ड कहीं नहीं रहता। अच्छी सड़कें, साफ़ नालियाँ — ये कोई '
        'एहसान नहीं हैं। ये आपका हक़ हैं।',
        'यहाँ आप गाँव की किसी भी समस्या की तस्वीर और जगह के साथ शिकायत '
        'दर्ज कर सकते हैं। जब और लोग बताते हैं कि उन्हें भी यही दिक्कत है, '
        'तो यह एक रिकॉर्ड बन जाता है — सबूत कि यह एक इंसान की शिकायत '
        'नहीं, पूरे गाँव की माँग है।',
        'और अगर कार्रवाई न भी हो, तब भी समस्या रिकॉर्ड में रहती है — '
        'जागरूक दुर्बे के लोग इसे रिकॉर्ड करके रखते हैं, यह भी कि समस्या कब '
        'से चली आ रही है। जैसे दुर्बे डाक स्थान का मैदान — बहुत पहले इसका '
        'वादा हुआ था। आज भी इसकी ज़रूरत है, और आज तक भी यह नहीं बन पाया।',
      ],
    ),
    _Feature(
      titleEn: 'Vikas Prastav',
      titleHi: 'विकास प्रस्ताव',
      subtitleHi: 'विकास प्रस्ताव',
      zoneLight: const Color(0xFFE5DCF2),
      zoneDark:  const Color(0xFFCBB9E6),
      illustrationAsset: 'assets/illustrations/vikas_prastav.svg',
      paragraphsEn: const [
        'No one knows your village better than you. The Samuday Bhawan that '
        'lie empty could be put to some other use. As one suggestion — one '
        'could be turned into a library, so that students do not have to '
        'travel to Delha or Katari to study. That would save them both time '
        'and money. This is just one idea — many more such suggestions can '
        'be given, so that the village can move forward.',
        'Vikas Prastav is for ideas like these. If you have a proposal for '
        'the village\'s future, put it here — and support what others have '
        'proposed. By the time elections come in five years, the village '
        'will have a full list of proposals and problems — ready to show, '
        'and to demand that each one is fixed.',
      ],
      paragraphsHi: const [
        'आपके गाँव को आपसे बेहतर कोई नहीं जानता। जो समुदाय भवन यूँ ही '
        'ख़ाली पड़े हैं, उनको किसी और काम में लाया जा सकता है। जैसे — '
        'सुझाव के तौर पर — उनको पुस्तकालय में बदला जा सकता है, जिससे '
        'पढ़ने वाले छात्रों को डेल्हा या कटारी न जाना पड़े। इससे उनका समय '
        'और पैसा दोनों बचेंगे। यह बस एक सुझाव है — ऐसे और भी सुझाव दिए '
        'जा सकते हैं, जिससे गाँव आगे बढ़ सके।',
        'विकास प्रस्ताव ऐसे ही सुझावों के लिए है। अगर गाँव के भविष्य के लिए '
        'आपके पास कोई प्रस्ताव है, तो उसे यहाँ रखिए, और दूसरे लोगों का '
        'समर्थन करिए। पाँच साल बाद जब चुनाव आएँगे, तब गाँव के पास सारे '
        'प्रस्ताव और समस्याएँ तैयार होंगी — दिखाने के लिए, और हर एक को '
        'ठीक कराने की माँग करने के लिए।',
      ],
    ),
    _Feature(
      titleEn: 'Neta Report Card',
      titleHi: 'नेता रिपोर्ट कार्ड',
      subtitleHi: 'नेता रिपोर्ट कार्ड',
      zoneLight: const Color(0xFFF6E6C8),
      zoneDark:  const Color(0xFFE6CC92),
      illustrationAsset: 'assets/illustrations/neta_report_card.svg',
      paragraphsEn: const [
        'At election time, many promises are made. By the next election, '
        'most are forgotten — by the people who made them, and sometimes by '
        'us too.',
        'Here, the promises made by your representatives are kept on record, '
        'added by the admins. When the next election comes, you can look '
        'back: what was promised, and how much was actually done. So the '
        'choice in your hand is an informed one.',
      ],
      paragraphsHi: const [
        'चुनाव के समय बहुत सारे वादे किए जाते हैं। अगले चुनाव तक उनमें से '
        'ज़्यादातर भुला दिए जाते हैं — उन लोगों के द्वारा भी जिन्होंने वादे किए '
        'थे, और कभी-कभी हमारे द्वारा भी।',
        'यहाँ आपके नेताओं के किए गए वादे एडमिन के द्वारा जोड़े जाते हैं। जब '
        'अगला चुनाव आता है, तो आप पीछे मुड़कर देख सकते हैं — क्या वादा '
        'हुआ था, और सचमुच कितना काम हुआ। ताकि आपके हाथ में जो फ़ैसला '
        'है, वह सोच-समझकर लिया गया हो।',
      ],
    ),
    _Feature(
      titleEn: 'Documents Guide',
      titleHi: 'दस्तावेज़ कैसे बनवाएँ',
      subtitleHi: 'दस्तावेज़ कैसे बनवाएँ',
      zoneLight: const Color(0xFFD4ECEA),
      zoneDark:  const Color(0xFFA9D6D2),
      illustrationAsset: 'assets/illustrations/documents_guide.svg',
      paragraphsEn: const [
        'Aadhaar card, birth certificate, khatiyan, caste certificate, '
        'income certificate, residence certificate, voter ID — getting any '
        'of these made often means many trips and a lot of confusion.',
        'You will not need to ask anyone. Just open the document section and '
        'read. Here you will find out how to get it made — online or '
        'offline — where to go, and how much the fee should be.',
        'Keeping your documents ready also keeps you ahead. With the right '
        'papers in hand, you can apply for the jobs in Job Alerts or claim '
        'the schemes in the Schemes section.',
      ],
      paragraphsHi: const [
        'आधार कार्ड, जन्म प्रमाण पत्र, खतियान, जाति प्रमाण पत्र, आय प्रमाण '
        'पत्र, निवास प्रमाण पत्र, वोटर आईडी — इनमें से कोई भी बनवाने के लिए '
        'अक्सर कई चक्कर लगाने पड़ते हैं और बहुत उलझन होती है।',
        'आपको किसी से पूछने की ज़रूरत नहीं पड़ेगी। बस दस्तावेज़ सेक्शन '
        'खोलकर पढ़िए। यहाँ आपको पता चलेगा कि यह कैसे बनवाते हैं — '
        'ऑनलाइन या ऑफ़लाइन — कहाँ जाना है, और कितनी फ़ीस लगनी चाहिए।',
        'अपने दस्तावेज़ तैयार रखना आपको आगे भी रखता है। सही कागज़ात हाथ '
        'में हों, तो आप \'नौकरी की सूचना\' में दी गई नौकरियों के लिए आवेदन '
        'कर सकते हैं या \'सरकारी योजनाएँ\' सेक्शन में दी गई योजनाओं का लाभ '
        'ले सकते हैं।',
      ],
    ),
    _Feature(
      titleEn: 'Crop Prices',
      titleHi: 'फसल भाव',
      subtitleHi: 'फसल भाव',
      zoneLight: const Color(0xFFDDEAD7),
      zoneDark:  const Color(0xFFBCD6B0),
      illustrationAsset: 'assets/illustrations/crop_prices.svg',
      paragraphsEn: const [
        'To know today\'s crop rate, a farmer often has to travel all the '
        'way to a shop just to ask. That is time and money spent on a single '
        'question.',
        'We have added some vendors and sellers to the app, and they update '
        'their prices from their end. Each listing shows the time it was '
        'last updated. You can see the rates from your phone, without '
        'travelling — and because there are multiple sellers, you can '
        'compare and see who is offering a better price.',
      ],
      paragraphsHi: const [
        'आज की फ़सल का भाव जानने के लिए, किसान को अक्सर सिर्फ़ पूछने के '
        'लिए दुकान तक का चक्कर लगाना पड़ता है। यह सिर्फ़ एक सवाल के लिए '
        'लगाया गया समय और पैसा है।',
        'हमने ऐप में कुछ विक्रेताओं और दुकानदारों को जोड़ा है, और वे अपनी '
        'तरफ़ से दाम अपडेट करते हैं। हर दाम के साथ यह भी दिखता है कि वह '
        'आख़िरी बार कब अपडेट हुआ। आप अपने फ़ोन पर ही दाम देख सकते हैं, '
        'बिना कहीं गए — और क्योंकि कई विक्रेता हैं, आप तुलना करके देख सकते '
        'हैं कि कौन बेहतर दाम दे रहा है।',
      ],
    ),
    _Feature(
      titleEn: 'Contacts',
      titleHi: 'संपर्क सूची',
      subtitleHi: 'संपर्क सूची',
      zoneLight: const Color(0xFFF3DEE3),
      zoneDark:  const Color(0xFFDBB3BC),
      illustrationAsset: 'assets/illustrations/contacts.svg',
      paragraphsEn: const [
        'This feature keeps important numbers in one place. It includes some '
        'emergency numbers — please use those carefully, only when truly '
        'needed.',
        'Apart from that, it has the numbers of local service providers — '
        'the electrician, the plumber, the doctor in our village — for quick '
        'help. It may also include some officials\' numbers, where they are '
        'willing to share them.',
      ],
      paragraphsHi: const [
        'यह सुविधा ज़रूरी नंबरों को एक जगह रखती है। इसमें कुछ इमरजेंसी '
        'नंबर भी हैं — कृपया उनका इस्तेमाल सोच-समझकर करें, सिर्फ़ तभी जब '
        'सचमुच ज़रूरत हो।',
        'इसके अलावा, इसमें स्थानीय सेवा देने वालों के नंबर हैं — हमारे गाँव '
        'के बिजली मिस्त्री, प्लंबर, डॉक्टर — जल्दी मदद के लिए। इसमें कुछ '
        'अधिकारियों के नंबर भी हो सकते हैं, जहाँ वे अपना नंबर देने को तैयार '
        'हों।',
      ],
    ),
  ];
}

// ── Feature data model — bilingual ─────────────────────────────────────────
class _Feature {
  final String titleEn;
  final String titleHi;
  final String subtitleHi;
  final Color  zoneLight;
  final Color  zoneDark;
  final String? illustrationAsset;
  final List<String> paragraphsEn;
  final List<String> paragraphsHi;

  const _Feature({
    required this.titleEn,
    required this.titleHi,
    required this.subtitleHi,
    required this.zoneLight,
    required this.zoneDark,
    required this.paragraphsEn,
    required this.paragraphsHi,
    this.illustrationAsset,
  });
}

// ══ _WipeText — the simultaneous wipe reveal widget ════════════════════════
// Each text block on the page is wrapped in one of these. The widget reads
// the master animation progress and animates a left-to-right wipe revealing
// the new text. The wipe is a horizontal opacity mask — letters are always
// fully formed (Devanagari conjuncts don't break), never partially drawn
// character-by-character.
//
// All blocks animate SIMULTANEOUSLY (stagger = 0). This was a deliberate
// fix: top-to-bottom cascading meant that if the user was scrolled to the
// bottom, they'd see nothing for ~1s while the top animated, making the app
// feel stuck. Now whichever block they're looking at responds immediately.
//
// When not animating, just renders the child as-is.
class _WipeText extends StatelessWidget {
  final int blockIdx;
  final AnimationController controller;
  final bool isHindi;     // current target language (used as key for the swap)
  final bool animating;
  final int blockCount;
  final Duration perBlock;
  final Duration stagger;
  final Widget child;

  const _WipeText({
    required this.blockIdx,
    required this.controller,
    required this.isHindi,
    required this.animating,
    required this.blockCount,
    required this.perBlock,
    required this.stagger,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!animating) {
      // Render the final text plainly. Use a Key keyed to language so that
      // any internal Text widget rebuilds cleanly between languages.
      return KeyedSubtree(
        key: ValueKey('block-$blockIdx-$isHindi'),
        child: child,
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Compute this block's own progress slice (0..1) based on the
        // overall controller progress (which runs 0..1 across the whole
        // duration), the block's index, and the stagger.
        final totalMs   = controller.duration!.inMilliseconds;
        final elapsedMs = controller.value * totalMs;
        final startMs   = blockIdx * stagger.inMilliseconds.toDouble();
        final localMs   = (elapsedMs - startMs).clamp(0, perBlock.inMilliseconds.toDouble());
        final t         = (localMs / perBlock.inMilliseconds).clamp(0.0, 1.0);

        // The wipe: from x=0 reveal up to x = width * t. Use a ShaderMask
        // with a sharp left-to-right gradient that exposes only the
        // revealed portion. A small soft edge keeps it feeling natural.
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            final width = bounds.width;
            final edge  = (width * 0.06).clamp(8.0, 28.0);
            final cut   = (width * t).clamp(0.0, width);
            // Stops: revealed area is opaque, then a small soft edge,
            // then transparent.
            final stop1 = (cut / width).clamp(0.0, 1.0);
            final stop2 = ((cut + edge) / width).clamp(0.0, 1.0);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, stop1, stop2],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: child,
        );
      },
    );
  }
}

// ══ _RevealOnScroll — fade+slide for the card, sweep for the illustration ═══
// Wraps each feature card. Uses two animations driven by one controller:
//
//   cardProgress  →  card opacity 0→1 and slide-up 16→0 (first ~40%)
//   illoSweep     →  the illustration's diagonal sweep (35%→100%)
//
// Fires ONCE when the card first crosses into the lower 85% of the viewport,
// based on the parent ScrollController. After it fires, the state is locked
// to revealed — so re-scrolling past, or toggling Hindi/English, will NOT
// retrigger the reveal. (Confusing UX otherwise.)
//
// The implementation deliberately avoids the visibility_detector package —
// pure Flutter, no new dependency. Uses RenderBox.localToGlobal +
// MediaQuery to compute its own on-screen position after each scroll event.
//
// Reveal duration: 1800ms. The "drawing itself in" feeling Raushan loved
// during the original SVG streaming preview — approximated as a diagonal
// wipe over the illustration. Not stroke-by-stroke (that would need per-SVG
// path manipulation), but visually the same emotional read: you watch the
// illustration become.
class _RevealOnScroll extends StatefulWidget {
  final ScrollController scrollController;
  final Widget Function(
    Animation<double> cardProgress,
    Animation<double> illoSweep,
  ) builder;

  const _RevealOnScroll({
    required this.scrollController,
    required this.builder,
  });

  @override
  State<_RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<_RevealOnScroll>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;
  late final Animation<double>  _cardProgress;   // 0..0.4 slice of the master
  late final Animation<double>  _illoSweep;      // 0.35..1.0 slice
  bool _revealed = false;

  // Reveal triggers when the widget's top edge sits above this fraction of
  // the screen height. 0.85 = trigger when the top is in the upper 85%
  // of the screen (i.e. clearly visible, not just barely peeking).
  static const double _triggerFraction = 0.85;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _cardProgress = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic),
    );
    _illoSweep = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );

    widget.scrollController.addListener(_maybeReveal);
    // Also check after first layout — top cards may already be on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReveal());
  }

  void _maybeReveal() {
    if (_revealed || !mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final topY = renderObject.localToGlobal(Offset.zero).dy;
    final screenH = MediaQuery.of(context).size.height;

    if (topY < screenH * _triggerFraction) {
      _revealed = true;
      _ctrl.forward();
      // Once revealed, stop listening — no need for repeated checks.
      widget.scrollController.removeListener(_maybeReveal);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_maybeReveal);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_cardProgress, _illoSweep);
  }
}