import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final TextEditingController _phoneController = TextEditingController(
    text: '+91',
  );
  final TextEditingController _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _verificationId;
  bool _codeSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _setLoading(bool loading, {String? error}) {
    if (mounted) {
      setState(() {
        _loading = loading;
        _error = error;
      });
    }
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    if (!mounted) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      // Context no longer valid, ignore
    }
  }

  Future<void> _handleSignIn(UserCredential cred) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('UserUId', cred.user?.uid ?? '');
    HapticFeedback.lightImpact();
  }

  String _getFirebaseErrorMessage(String code) {
    return switch (code) {
      'invalid-phone-number' =>
        'Invalid phone number format. Please include country code (e.g., +911234567890)',
      'too-many-requests' =>
        'Too many attempts. Please try again after some time.',
      'app-not-authorized' =>
        'App not authorized. Please check Firebase configuration.',
      _ => 'Verification failed. Please try again.',
    };
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    _setLoading(true);
    HapticFeedback.mediumImpact();

    final phone = _phoneController.text.trim();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;
          _setLoading(true);
          try {
            UserCredential cred = await FirebaseAuth.instance
                .signInWithCredential(credential);
            if (!mounted) return;
            await _handleSignIn(cred);
            setState(() => _codeSent = false);
            _setLoading(false);
            _showSnackBar('Phone automatically verified and user signed in.');
          } catch (e) {
            if (!mounted) return;
            _setLoading(false, error: e.toString());
            HapticFeedback.heavyImpact();
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          _setLoading(false, error: _getFirebaseErrorMessage(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _loading = false;
            _error = null;
          });
          SharedPreferences.getInstance().then(
            (prefs) => prefs.setString('contactNumber', phone),
          );
          HapticFeedback.lightImpact();
          _showSnackBar('OTP sent successfully! Please check your messages.');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;
          _verificationId = verificationId;
          _setLoading(
            false,
            error: 'Code verification timed out. Please try again.',
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      _setLoading(false, error: e.toString());
    }
  }

  Future<void> _verifyCode() async {
    HapticFeedback.mediumImpact();
    _setLoading(true);

    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _setLoading(false, error: 'Please enter the OTP code');
      HapticFeedback.heavyImpact();
      return;
    }

    if (_verificationId == null) {
      _setLoading(false, error: 'OTP session expired. Please send a new code.');
      HapticFeedback.heavyImpact();
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      UserCredential cred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      if (!mounted) return;
      await _handleSignIn(cred);
      _setLoading(false);
      _showSnackBar('Verification successful.');
    } catch (e) {
      if (!mounted) return;
      _setLoading(false, error: e.toString());
      HapticFeedback.heavyImpact();
    }
  }

  Widget _buildFormField({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 16, color: Colors.black),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, size: 20, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFCB853), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        counterText: "",
      ),
      validator: validator,
      onTap: () => HapticFeedback.selectionClick(),
      onChanged: controller == _phoneController
          ? (value) {
              if (!value.startsWith('+91')) {
                controller.value = controller.value.copyWith(
                  text: '+91',
                  selection: const TextSelection.collapsed(offset: 3),
                );
              }
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCB853),
      appBar: AppBar(
        title: const Text('', semanticsLabel: 'Phone Authentication Page'),
        backgroundColor: const Color(0xFFFCB853),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.yellow,
                semanticsLabel: 'Loading, please wait',
              ),
            )
          : SafeArea(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 550),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Column(
                              children: [
                                Icon(
                                  _codeSent
                                      ? Icons.security
                                      : Icons.phone_android,
                                  size: 60,
                                  color: const Color(0xFFFCB853),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _codeSent
                                      ? 'Verify OTP'
                                      : 'Phone Verification',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFCB853),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _codeSent
                                      ? 'Enter the 6-digit code sent to\n${_phoneController.text}'
                                      : 'Enter your phone number to receive\na verification code',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Form Fields
                            if (!_codeSent) ...[
                              _buildFormField(
                                labelText: 'Phone Number / फोन नंबर *',
                                hintText: '+911234567890',
                                prefixIcon: Icons.phone,
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  if (!value.startsWith('+') ||
                                      value.length < 8) {
                                    return 'Enter valid number with country code';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Send OTP Button
                              ElevatedButton(
                                onPressed: _loading ? null : _sendCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFCB853),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Send OTP',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ] else ...[
                              _buildFormField(
                                labelText: 'Enter OTP / OTP दाखल करा *',
                                hintText: '123456',
                                prefixIcon: Icons.lock_outline,
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the OTP code';
                                  }
                                  if (value.length != 6) {
                                    return 'OTP must be 6 digits';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Verify Button
                              ElevatedButton(
                                onPressed: _loading ? null : _verifyCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFCB853),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.purple,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Verify & Continue',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),

                              // Resend Code Button
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () {
                                        setState(() {
                                          _codeSent = false;
                                          _codeController.clear();
                                          _error = null;
                                          _verificationId = null;
                                        });
                                        HapticFeedback.lightImpact();
                                      },
                                child: Text(
                                  'Didn\'t receive code? Try again',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],

                            // Error Message
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Help Text
                            Text(
                              '* Required fields',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
