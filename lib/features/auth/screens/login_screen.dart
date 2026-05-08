// lib/features/auth/screens/login_screen.dart
// ─────────────────────────────────────────────────────────────
// Login screen — villagers enter phone + password to log in.
//
// Design (Screen 2 from design sprint):
//   - "Welcome back" heading in Playfair Display
//   - Hindi subtitle
//   - Phone number input field
//   - Password input field with show/hide toggle
//   - "Forgot password?" link
//   - Green "Log In" button
//   - Divider + "Register with OTP" outline button
//   - "New to Gram Seva? Create account" footer
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'register_screen.dart';
import '../../../core/network/api_service.dart';
import '../../home/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  // — Controllers ───────────────────────────────────────────
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // — State ─────────────────────────────────────────────────
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // — Login action ──────────────────────────────────────────

void _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);

  try {
    final result = await ApiService.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result['statusCode'] == 200 && result['access_token'] != null) {
      // ✅ Save token to device storage
      await ApiService.saveToken(result['access_token']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', result['role'] ?? '');
      await prefs.setBool('is_verified', result['is_verified'] ?? false);
      // ✅ ADD — save extra fields from updated login response
      await prefs.setString('full_name', result['full_name'] ?? '');
      await prefs.setString('badge', result['badge'] ?? 'none');
      await prefs.setString('user_id', result['id']?.toString() ?? '');

      // ✅ Navigate to Home (placeholder for now)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      // ❌ Show error from backend
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['detail'] ?? 'Login failed. Please try again.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  } catch (e) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot connect to server. Check your connection.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 24),

                // — Heading ───────────────────────────────
                Text(
                  'Welcome back',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Log in to your Gram Seva account',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'अपने खाते में लॉग इन करें',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),

                const SizedBox(height: 32),

                // — Phone field ───────────────────────────
                _fieldLabel('Mobile Number'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
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
                    suffixIcon: _phoneController.text.length == 10
                        ? Icon(Icons.check_circle,
                            color: AppColors.primary, size: 18)
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
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

                // — Password field ─────────────────────────
                _fieldLabel('Password'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  style: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
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
                      return 'Please enter your password';
                    }
                    if (val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                // — Forgot password ────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Navigate to forgot password screen
                    },
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // — Login button ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Log In',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // — Divider ────────────────────────────────
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textHint,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),

                const SizedBox(height: 20),

                // — Register button ────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Register with OTP',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // — Footer ─────────────────────────────────
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textHint,
                      ),
                      children: [
                        const TextSpan(text: 'New to Gram Seva? '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: Text(
                              'Create account',
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
                  ),
                ),
              ],
            ),
          ),
        ),
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