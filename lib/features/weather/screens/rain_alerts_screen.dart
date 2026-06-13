// lib/features/weather/screens/rain_alerts_screen.dart
// ──────────────────────────────────────────────────────────────────
// Rain Alerts — Live weather + 7-day forecast for Durbe village.
//
// Layout (matches original design mockup):
//   - Full green header: location, big temp, condition, max/min/rain
//   - Rain warning banner at very top if rain predicted
//   - 7-day forecast list with day, warning badge, max/min temp
//   - IMD disclaimer at bottom
//
// Data source: Open-Meteo API via GET /weather/rain-alert
// No login required.
// ──────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';

class RainAlertsScreen extends StatefulWidget {
  const RainAlertsScreen({super.key});

  @override
  State<RainAlertsScreen> createState() => _RainAlertsScreenState();
}

class _RainAlertsScreenState extends State<RainAlertsScreen> {

  Map<String, dynamic>? _data;
  bool   _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService.getRainAlerts();
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ─── Warning level helpers ────────────────────────────────────
  Color _warningBgColor(String level) {
    switch (level.toLowerCase()) {
      case 'heavy': return const Color(0xFFFEE2E2);
      case 'low':   return const Color(0xFFFEF3C7);
      default:      return const Color(0xFFDCFCE7);
    }
  }

  Color _warningTextColor(String level) {
    switch (level.toLowerCase()) {
      case 'heavy': return const Color(0xFF991B1B);
      case 'low':   return const Color(0xFF92400E);
      default:      return const Color(0xFF166534);
    }
  }

  String _warningLabel(String level) {
    switch (level.toLowerCase()) {
      case 'heavy': return '🌧️ Heavy Rain';
      case 'low':   return '🌦️ Low Rain';
      default:      return '☀️ Clear';
    }
  }

  String _conditionText(String level) {
    switch (level.toLowerCase()) {
      case 'heavy': return 'Heavy Rain Warning';
      case 'low':   return 'Low Rain Warning';
      default:      return 'Clear Sky';
    }
  }

  // ─── Day label from date string ───────────────────────────────
  String _dayLabel(String dateStr, int index) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    try {
      final d = DateTime.parse(dateStr);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[d.weekday - 1];
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  // ─── Loading ──────────────────────────────────────────────────
  Widget _buildLoading() {
    return Container(
      color: AppColors.primary,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  // ─── Error ────────────────────────────────────────────────────
  Widget _buildError() {
    return SafeArea(
      child: Column(
        children: [
          // Back button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ]),
          ),
          const Spacer(),
          const Icon(Icons.cloud_off, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Could not load weather data',
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Check your connection and try again',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchWeather,
            icon: const Icon(Icons.refresh),
            label: Text('Retry', style: GoogleFonts.inter()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ─── Main content ─────────────────────────────────────────────
  Widget _buildContent() {
    final warningLevel = _data?['warning_level'] as String? ?? 'None';
    final hasRain      = warningLevel.toLowerCase() != 'none';
    final forecast     = _data?['forecast'] as List<dynamic>? ?? [];

    return Column(
      children: [

        // ─── GREEN HEADER ──────────────────────────────────────
        _buildHeader(warningLevel, hasRain),

        // ─── RAIN WARNING BANNER ───────────────────────────────
        // Shows ONLY when rain is predicted — "at the very beginning"
        if (hasRain)
          _buildRainBanner(warningLevel),

        // ─── 7-DAY FORECAST ───────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchWeather,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text('7-Day Forecast',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
                const SizedBox(height: 12),

                // Forecast rows
                ...forecast.asMap().entries.map((entry) =>
                  _buildForecastRow(entry.value, entry.key)),

                const SizedBox(height: 20),

                // ─── IMD Disclaimer ──────────────────────────
                Text(
                  'Data sourced from Open-Meteo · For official forecasts visit IMD (mausam.imd.gov.in)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textHint,
                    fontStyle: FontStyle.italic, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Green header ─────────────────────────────────────────────
  Widget _buildHeader(String warningLevel, bool hasRain) {
    final tempMax   = _data?['today_temp_max_c'];
    final tempMin   = _data?['today_temp_min_c'];
    final rainfall  = _data?['today_rainfall_mm'] ?? 0.0;
    final location  = _data?['location'] ?? 'Durbe, Bihar';
    final todayTemp = (_data?['current_temp_c'] as num?)?.toDouble();

    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        20, MediaQuery.of(context).padding.top + 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Back button + location row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Text('$location · Today',
                style: GoogleFonts.inter(
                  color: Colors.white70, fontSize: 13)),
              const Spacer(),
              GestureDetector(
                onTap: _fetchWeather,
                child: const Icon(Icons.refresh, color: Colors.white70, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Big temperature
          Text(
            todayTemp != null
                ? '${todayTemp.toStringAsFixed(0)}°C'
                : '--°C',
            style: GoogleFonts.inter(
              fontSize: 72, fontWeight: FontWeight.w200,
              color: Colors.white, height: 1),
          ),

          const SizedBox(height: 8),

          // Condition text
          Text(
            _conditionText(warningLevel),
            style: GoogleFonts.inter(
              fontSize: 16, color: Colors.white70,
              fontWeight: FontWeight.w400),
          ),

          const SizedBox(height: 12),

          // Max / Min / Rain row
          Row(children: [
            if (tempMax != null) ...[
              const Icon(Icons.arrow_upward, color: Colors.white70, size: 14),
              Text(' Max ${(tempMax as num).toStringAsFixed(0)}°',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              const SizedBox(width: 16),
            ],
            if (tempMin != null) ...[
              const Icon(Icons.arrow_downward, color: Colors.white70, size: 14),
              Text(' Min ${(tempMin as num).toStringAsFixed(0)}°',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              const SizedBox(width: 16),
            ],
            if (hasRain) ...[
              const Text('💧', style: TextStyle(fontSize: 13)),
              Text(' ${(rainfall as num).toStringAsFixed(1)}mm rain',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
            ],
          ]),
        ],
      ),
    );
  }

  // ─── Rain warning banner ──────────────────────────────────────
  Widget _buildRainBanner(String warningLevel) {
    final isHeavy = warningLevel.toLowerCase() == 'heavy';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isHeavy
          ? const Color(0xFFB91C1C)
          : const Color(0xFFF59E0B),
      child: Row(children: [
        Text(isHeavy ? '⛈️' : '🌦️',
          style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHeavy
                  ? 'Heavy Rain Warning — Stay Safe'
                  : 'Rain Expected Today',
              style: GoogleFonts.inter(
                color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w700),
            ),
            Text(
              isHeavy
                  ? 'Avoid travel · Keep cattle indoors · Check drainage'
                  : 'Carry an umbrella · Good for crops',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
            ),
          ],
        )),
      ]),
    );
  }

  // ─── Forecast row ─────────────────────────────────────────────
  Widget _buildForecastRow(dynamic point, int index) {
    final level   = (point['warning_level'] as String?) ?? 'None';
    final tempMax = (point['temp_max_c'] as num?)?.toStringAsFixed(0) ?? '--';
    final tempMin = (point['temp_min_c'] as num?)?.toStringAsFixed(0) ?? '--';
    final date    = point['date'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [

        // Day label
        SizedBox(
          width: 80,
          child: Text(
            _dayLabel(date, index),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: index == 0
                  ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.textPrimary),
          ),
        ),

        // Warning badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _warningBgColor(level),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _warningLabel(level),
            style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: _warningTextColor(level)),
          ),
        ),

        const Spacer(),

        // Temp range
        Text(
          '$tempMax° / $tempMin°',
          style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: AppColors.textPrimary),
        ),
      ]),
    );
  }
}