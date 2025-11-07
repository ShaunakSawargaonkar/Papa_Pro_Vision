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

  Future<void> _sendCode() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    final phone = _phoneController.text.trim();
    // Check if phone number starts with + and contains only digits after that
    if (!phone.startsWith('+') || phone.length < 8) {
      setState(() {
        _error =
            'Please enter a valid phone number with country code (e.g., +911234567890)';
        _loading = false;
      });
      HapticFeedback.heavyImpact();
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          setState(() {
            _loading = true;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _error = switch (e.code) {
              'invalid-phone-number' =>
                'Invalid phone number format. Please include country code (e.g., +911234567890)',
              'too-many-requests' =>
                'Too many attempts. Please try again after some time.',
              'app-not-authorized' =>
                'App not authorized. Please check Firebase configuration.',
              _ => e.message ?? 'Verification failed. Please try again.',
            };
            _loading = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _loading = false;
            _error = null;
          });
          // Save phone number to shared preferences
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('contactNumber', phone);
          });
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'OTP sent successfully! Please check your messages.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (mounted) {
            setState(() {
              _error = 'Code verification timed out. Please try again.';
              _loading = false;
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    setState(() {
      _loading = true;
      _error = null;
    });

    final code = _codeController.text.trim();
    if (code.isEmpty || _verificationId == null) {
      setState(() {
        _error = 'Please enter the OTP code';
        _loading = false;
      });
      HapticFeedback.heavyImpact();
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
        counterText: "", // Hide character counter
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
                color: Colors.white,
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
                                          color: Colors.white,
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
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
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
                            ],

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
