import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _buildingIdController = TextEditingController();
  final _buildingPhoneController = TextEditingController();

  bool _showBuildingIdFallback = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _buildingIdController.dispose();
    _buildingPhoneController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack('Please enter your phone number');
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.requestOtp(phone);
    if (!mounted) return;

    if (ok && auth.skippedOtp) {
      // Returning customer — backend issued token directly, no OTP needed
      context.go('/home');
    } else if (!ok) {
      _showSnack(auth.errorMessage ?? 'Failed to send OTP');
    }
    // If ok && !skippedOtp: OTP was sent, UI will show OTP entry (handled by Consumer rebuild)
  }

  Future<void> _verifyOtp(String otp) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(otp);
    if (ok && mounted) {
      context.go('/home');
    } else if (mounted) {
      _showSnack(auth.errorMessage ?? 'Invalid OTP');
      _otpController.clear();
    }
  }

  Future<void> _buildingIdLogin() async {
    final buildingId = _buildingIdController.text.trim();
    final phone = _buildingPhoneController.text.trim();
    if (buildingId.isEmpty || phone.isEmpty) {
      _showSnack('Please enter both Customer ID and phone number');
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithBuildingId(buildingId, phone);
    if (ok && mounted) {
      context.go('/home');
    } else if (mounted) {
      _showSnack(auth.errorMessage ?? 'Customer ID not found');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 56),
                  // Logo
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _showBuildingIdFallback
                        ? 'Use Customer ID'
                        : auth.otpSent
                            ? 'Enter OTP'
                            : 'Welcome Back',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showBuildingIdFallback
                        ? 'Enter your Customer ID and phone number to access your account'
                        : auth.otpSent
                            ? 'We sent a 6-digit code to ${auth.phone}'
                            : 'Enter your phone number to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Building ID Fallback ──────────────────────────────────
                  if (_showBuildingIdFallback) ...[
                    _buildLabel('Customer ID'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _buildingIdController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDecoration('e.g. LGA-001-R1'),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Phone Number'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _buildingPhoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration('e.g. 08012345678'),
                    ),
                    const SizedBox(height: 32),
                    _buildPrimaryButton(
                      label: auth.state == AuthState.loading
                          ? 'Signing in...'
                          : 'Sign In',
                      onTap: auth.state == AuthState.loading
                          ? null
                          : _buildingIdLogin,
                      loading: auth.state == AuthState.loading,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() => _showBuildingIdFallback = false);
                          auth.resetOtp();
                        },
                        child: const Text('Back to phone login'),
                      ),
                    ),
                  ]

                  // ── OTP Entry ─────────────────────────────────────────────
                  else if (auth.otpSent) ...[
                    Center(
                      child: Pinput(
                        controller: _otpController,
                        length: 6,
                        autofocus: true,
                        defaultPinTheme: PinTheme(
                          width: 52,
                          height: 60,
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        focusedPinTheme: PinTheme(
                          width: 52,
                          height: 60,
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFF1B5E20), width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onCompleted: _verifyOtp,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (auth.state == AuthState.loading)
                      const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          auth.resetOtp();
                          _otpController.clear();
                        },
                        child: const Text('Change phone number'),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: auth.state == AuthState.loading
                            ? null
                            : _requestOtp,
                        child: const Text('Resend OTP'),
                      ),
                    ),
                  ]

                  // ── Phone Entry ───────────────────────────────────────────
                  else ...[
                    _buildLabel('Phone Number'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration('e.g. 08012345678'),
                      onSubmitted: (_) => _requestOtp(),
                    ),
                    const SizedBox(height: 32),
                    _buildPrimaryButton(
                      label: auth.state == AuthState.loading
                          ? 'Sending OTP...'
                          : 'Send OTP',
                      onTap: auth.state == AuthState.loading
                          ? null
                          : _requestOtp,
                      loading: auth.state == AuthState.loading,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _showBuildingIdFallback = true),
                        child: Text(
                          "Don't have your phone? Use Customer ID",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Color(0xFF333333),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
