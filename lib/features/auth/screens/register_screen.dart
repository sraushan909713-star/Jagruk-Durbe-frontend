// lib/features/auth/screens/register_screen.dart
// ─────────────────────────────────────────────────────────────
// Register screen — new villagers create their Gram Seva account.
//
// Flow (3 steps):
//   Step 1: Enter full name, phone, password → tap "Send OTP"
//           → POST /auth/send-otp
//   Step 2: Enter the 6-digit OTP received on phone
//           → POST /auth/register
//   Step 3: Account created → token saved → navigate to Home
//
// Design (Screen 3 from design sprint):
//   Same warm off-white background as Login
//   Green primary button, step indicator at top
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import '../../home/screens/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  // — Step tracking ─────────────────────────────────────────
  // Step 1 = enter details, Step 2 = enter OTP
  int _currentStep = 1;

  // — Controllers ───────────────────────────────────────────
  final _nameController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController      = TextEditingController();
  final _formKey            = GlobalKey<FormState>();

  // — State ─────────────────────────────────────────────────
  bool _passwordVisible = false;
  bool _isLoading       = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ── STEP 1: Send OTP ──────────────────────────────────────
  void _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.sendOtp(
        _phoneController.text.trim(),
      );
      setState(() => _isLoading = false);

      // ✅ OTP sent successfully — move to Step 2
      if (result['message'] != null) {
        setState(() => _currentStep = 2);
        if (mounted) {
          final otp = result['otp'] ?? 'Check backend terminal';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'OTP: $otp (dev only)',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 10),
            ),
          );
        }
      } else {
        // ❌ Error from backend
        _showError(result['detail'] ?? 'Could not send OTP. Try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Cannot connect to server. Check your connection.');
    }
  }

  // ── STEP 2: Verify OTP & Register ─────────────────────────
  void _handleRegister() async {
    if (_otpController.text.trim().length != 6) {
      _showError('Please enter the 6-digit OTP.');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.register(
        phone:    _phoneController.text.trim(),
        fullName: _nameController.text.trim(),
        otpCode:  _otpController.text.trim(),
        password: _passwordController.text.trim(),
      );
      setState(() => _isLoading = false);

      if (result['statusCode'] == 200 && result['access_token'] != null) {
        // ✅ Registered successfully — save token and go to Home
        await ApiService.saveToken(result['access_token']);
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,   // Clear entire back stack
          );
        }
      } else {
        _showError(result['detail'] ?? 'Registration failed. Try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Cannot connect to server. Check your connection.');
    }
  }

  // — Helper: show error snackbar ───────────────────────────
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: AppColors.error,
      ),
    );
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
            if (_currentStep == 2) {
              // ✅ Go back to Step 1 instead of leaving screen
              setState(() => _currentStep = 1);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // — Step indicator ────────────────────────────
              _buildStepIndicator(),

              const SizedBox(height: 24),

              // — Step 1 or Step 2 content ──────────────────
              _currentStep == 1
                  ? _buildStep1()
                  : _buildStep2(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step indicator UI ─────────────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepDot(1, 'Details'),
        Expanded(
          child: Container(
            height: 1,
            color: _currentStep == 2
                ? AppColors.primary
                : AppColors.border,
          ),
        ),
        _stepDot(2, 'Verify OTP'),
      ],
    );
  }

  Widget _stepDot(int step, String label) {
    final isActive   = _currentStep == step;
    final isComplete = _currentStep > step;
    return Column(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isActive || isComplete)
                ? AppColors.primary
                : AppColors.border,
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text(
                    '$step',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.textHint,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isActive ? AppColors.primary : AppColors.textHint,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ── STEP 1: Enter details ─────────────────────────────────
  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Heading
          Text(
            'Create Account',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Join Durbe\'s civic community',
            style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 28),

          // Full name
          _fieldLabel('Full Name'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(
              fontSize: 15, color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter your full name',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your full name';
              }
              if (val.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Phone number
          _fieldLabel('Mobile Number'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            style: GoogleFonts.inter(
              fontSize: 15, color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '10-digit mobile number',
              prefixText: '+91  ',
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

          // Password
          _fieldLabel('Password'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            style: GoogleFonts.inter(
              fontSize: 15, color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Create a password (min 6 characters)',
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textHint, size: 20,
                ),
                onPressed: () => setState(
                    () => _passwordVisible = !_passwordVisible),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please create a password';
              }
              if (val.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 8),

          // Info note about OTP
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'An OTP will be sent to verify your mobile number.',
                    style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Send OTP button
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

  // ── STEP 2: Enter OTP ─────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Heading
        Text(
          'Verify OTP',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the 6-digit code sent to',
          style: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textSecondary,
          ),
        ),
        Text(
          '+91 ${_phoneController.text.trim()}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 32),

        // OTP field
        _fieldLabel('6-Digit OTP'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '• • • • • •',
            hintStyle: GoogleFonts.inter(
              fontSize: 22,
              letterSpacing: 8,
              color: AppColors.textHint,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 12),

        // Resend OTP
        Center(
          child: TextButton(
            onPressed: _handleSendOtp,
            child: Text(
              'Resend OTP',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Create Account button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            child: _isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Create Account',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
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