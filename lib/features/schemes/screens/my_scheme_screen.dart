// lib/features/schemes/screens/my_scheme_screen.dart
// ──────────────────────────────────────────────────────────────────
// MyScheme WebView — embeds myscheme.gov.in directly in the app.
// Zero backend work — just a WebView wrapper.
//
// Features:
//   - Full-screen WebView of myscheme.gov.in
//   - Loading progress bar at top
//   - Error state with retry button
//   - Back/Forward/Refresh controls at bottom
//   - Opens external links in browser
// ──────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';

class MySchemeScreen extends StatefulWidget {
  const MySchemeScreen({super.key});

  @override
  State<MySchemeScreen> createState() => _MySchemeScreenState();
}

class _MySchemeScreenState extends State<MySchemeScreen> {

  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _hasError      = false;

  static const String _url = 'https://myscheme.gov.in';

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() { _hasError = false; _loadingProgress = 10; });
        },
        onProgress: (progress) {
          if (mounted) setState(() => _loadingProgress = progress);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loadingProgress = 100);
        },
        onWebResourceError: (_) {
          if (mounted) setState(() => _hasError = true);
        },
      ))
      ..loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('सरकारी योजनाएं',
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 18, fontWeight: FontWeight.w600,
                color: Colors.white)),
            Text('myscheme.gov.in',
              style: GoogleFonts.inter(
                fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _controller.reload(),
            tooltip: 'Refresh',
          ),
        ],
        // ── Loading progress bar ──────────────────────────────
        bottom: _loadingProgress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : null,
      ),

      body: _hasError ? _buildError() : WebViewWidget(controller: _controller),

      // ── Bottom navigation bar ─────────────────────────────────
      bottomNavigationBar: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Back
            IconButton(
              icon: Icon(Icons.arrow_back_ios,
                size: 18, color: AppColors.textSecondary),
              onPressed: () async {
                if (await _controller.canGoBack()) {
                  _controller.goBack();
                }
              },
            ),
            // Forward
            IconButton(
              icon: Icon(Icons.arrow_forward_ios,
                size: 18, color: AppColors.textSecondary),
              onPressed: () async {
                if (await _controller.canGoForward()) {
                  _controller.goForward();
                }
              },
            ),
            // Home — go back to myscheme.gov.in root
            IconButton(
              icon: Icon(Icons.home_outlined,
                size: 22, color: AppColors.primary),
              onPressed: () => _controller.loadRequest(Uri.parse(_url)),
              tooltip: 'Go to home',
            ),
            // Share current URL
            IconButton(
              icon: Icon(Icons.open_in_browser,
                size: 22, color: AppColors.textSecondary),
              onPressed: () async {
                final url = await _controller.currentUrl();
                if (url != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(url,
                      style: GoogleFonts.inter(fontSize: 12)),
                    action: SnackBarAction(
                      label: 'OK',
                      onPressed: () {},
                    ),
                  ));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error state ──────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 72,
              color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('No internet connection',
              style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'myscheme.gov.in needs an internet\nconnection to load.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textHint, height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _hasError = false);
                _controller.reload();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text('Try again',
                style: GoogleFonts.inter(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}