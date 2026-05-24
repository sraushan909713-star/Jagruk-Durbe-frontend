// lib/features/auth/screens/forgot_password_screen.dart
// ─────────────────────────────────────────────────────────────
// Forgot Password screen — 2-step reset flow.
//
//   Step 1: enter phone number → backend sends OTP
//            (POST /auth/send-otp, purpose = "reset_password")
//   Step 2: enter OTP + new password → password is reset
//            (POST /auth/reset-password) → returns JWT, user
//            is logged in immediately and sent to Home.
//
// Reuses the existing OTP system. No backend changes needed.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import '../../home/screens/home_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  // ── Controllers ───────────────────────────────────────────
  final _phoneController       = TextEditingController();
  final _otpController         = TextEditingController();
  final _newPasswordController = TextEditingController();

  final _phoneFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  // ── State ─────────────────────────────────────────────────
  // _step 1 = enter phone | _step 2 = enter OTP + new password
  int  _step            = 1;
  bool _isLoading       = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: error ? AppColors.error : AppColors.primary,
      ),
    );
  }

  // ══ Step 1 — send OTP ════════════════════════════════════
  void _handleSendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.sendOtp(
        _phoneController.text.trim(),
        purpose: 'reset_password',                       // ✅ reset purpose
      );
      setState(() => _isLoading = false);

      // send-otp returns a message; treat presence of 'otp' or
      // 'message' as success. Backend returns 'otp' in dev mode.
      if (result['otp'] != null || result['message'] != null) {
        setState(() => _step = 2);
        // ⚠️ TEST ONLY — shows OTP on screen. REMOVE before Play Store launch.
        _snack(
          result['otp'] != null
              ? 'OTP sent. (TEST: ${result['otp']})'
              : 'OTP sent to your mobile number.',
          error: false,
        );
      } else {
        _snack(result['detail'] ?? 'Could not send OTP. Try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Cannot connect to server. Check your connection.');
    }
  }

  // ══ Step 2 — reset password ══════════════════════════════
  void _handleResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.resetPassword(
        phone:       _phoneController.text.trim(),
        otpCode:     _otpController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );
      setState(() => _isLoading = false);

      if (result['statusCode'] == 200 && result['access_token'] != null) {
        // Backend logs the user in right after reset — save the token.
        await ApiService.saveToken(result['access_token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', result['role'] ?? '');
        await prefs.setBool('is_verified', result['is_verified'] ?? false);
        await prefs.setString('full_name', result['full_name'] ?? '');
        await prefs.setString('badge', result['badge'] ?? 'none');
        await prefs.setString('user_id', result['id']?.toString() ?? '');

        _snack('Password reset successful.', error: false);
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        _snack(result['detail'] ?? 'Could not reset password. Try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Cannot connect to server. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            // From step 2, back goes to step 1; from step 1, leave screen.
            if (_step == 2) {
              setState(() => _step = 1);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: _step == 1 ? _buildPhoneStep() : _buildResetStep(),
        ),
      ),
    );
  }

  // ══ Step 1 UI ════════════════════════════════════════════
  Widget _buildPhoneStep() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Reset password',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your mobile number and we will send you an OTP to reset your password.',
            style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'पासवर्ड बदलने के लिए अपना मोबाइल नंबर डालें',
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 12, color: AppColors.textHint,
            ),
          ),

          const SizedBox(height: 32),

          _fieldLabel('Mobile Number'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            autofillHints: const [AutofillHints.telephoneNumber],
            style: GoogleFonts.inter(
              fontSize: 15, color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '10-digit mobile number',
              prefixText: '+91  ',
              prefixStyle: GoogleFonts.inter(
                fontSize: 15, color: AppColors.textPrimary,
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please enter your mobile number';
              }
              if (val.length != 10) {
                return 'Enter a valid 10-digit number';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendOtp,
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Send OTP',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ══ Step 2 UI ════════════════════════════════════════════
  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Enter OTP & new password',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'We sent an OTP to +91 ${_phoneController.text.trim()}. Enter it below with your new password.',
            style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // — OTP field ───────────────────────────────────────
          _fieldLabel('OTP'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: GoogleFonts.inter(
              fontSize: 15, color: AppColors.textPrimary,
              letterSpacing: 4,
            ),
            decoration: const InputDecoration(
              counterText: '',
              hintText: 'Enter the OTP',
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please enter the OTP';
              }
              if (val.length < 4) {
                return 'Enter the full OTP';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // — New password field ──────────────────────────────
          _fieldLabel('New Password'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _newPasswordController,
            obscureText: !_passwordVisible,
            autofillHints: const [AutofillHints.newPassword],
            style: GoogleFonts.inter(
              fontSize: 15, color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Enter a new password',
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textHint,
                  size: 20,
                ),
                onPressed: () => setState(
                    () => _passwordVisible = !_passwordVisible),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please enter a new password';
              }
              if (val.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Reset Password',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // — Resend OTP ──────────────────────────────────────
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _handleSendOtp,
              child: Text(
                'Did not get the OTP? Resend',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // — Helper: field label ───────────────────────────────────
  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}
