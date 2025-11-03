import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:papa_pro_vision/UI/home_screen.dart';
import 'package:intl/intl.dart';
import 'package:papa_pro_vision/Helper/DatabaseHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:papa_pro_vision/enums.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _referralKeyController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedGender = 'Male';
  bool _isLoading = false;
  bool _isOrganizationVerified = false;
  late TabController _tabController;

  DocumentReference? _orgRef;
  DocumentReference? _referralKeyRef;

  // Format date in Indian format (DD/MM/YYYY)
  String _formatDateIndian(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPhoneNumber();
  }

  Future<void> _loadPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('contactNumber') ?? '+91 9876543210';
    setState(() {
      _phoneController.text = phoneNumber;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    // Provide haptic feedback for accessibility
    HapticFeedback.mediumImpact();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFCB853)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _verifyReferralKey() async {
    if (_referralKeyController.text.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a referral key'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    ReferralKeyResponse result = await DatabaseHelper.verifyReferralKey(
      referralKey: _referralKeyController.text,
    );
    if (!result.success) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Something went wrong. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }
    _orgRef = result.orgRef;
    _referralKeyRef = result.referralKeyRef;

    setState(() {
      _isOrganizationVerified = true;
      _isLoading = false;
    });
  }

  Future<void> _submitForm() async {
    // Haptic feedback for form submission
    HapticFeedback.mediumImpact();

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print('Creating user');

    CreateUserResponse result = await DatabaseHelper.createUser(
      userUID: FirebaseAuth.instance.currentUser?.uid ?? '',
      dob: _selectedDate ?? DateTime(2000),
      gender: _selectedGender,
      name: _nameController.text,
      phoneNumber: _phoneController.text,
      occupation: _occupationController.text,
      userType: _tabController.index == 0
          ? UserType.single
          : UserType.organization,
      referralKeyRef: _referralKeyRef,
      orgRef: _orgRef,
    );

    print('User created result: $result');

    if (!result.success) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Something went wrong. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
    });

    // Success haptic feedback
    HapticFeedback.lightImpact();

    // Navigate to home screen
    print('Navigating to home screen');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
    return;
  }

  Widget _buildFormField({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
    required TextEditingController controller,
    required validator,
    isDisabled = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !isDisabled,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(
        fontSize: 16,
        color: isDisabled ? Colors.grey[600] : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, size: 20, color: Colors.grey),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: 18, color: Colors.grey)
            : null,
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
        fillColor: isDisabled ? Colors.grey[100] : Colors.grey[50],
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      validator: validator,
      onTap: () => HapticFeedback.selectionClick(),
    );
  }

  Widget _buildUserDetailsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        // Name Field - Required
        _buildFormField(
          labelText: 'Name / नाव *',
          hintText: 'Enter your name',
          prefixIcon: Icons.person,
          controller: _nameController,
          validator: (value) => value.isEmpty ? 'Please enter your name' : null,
        ),
        const SizedBox(height: 16),

        _buildFormField(
          labelText: 'Phone Number / फोन नंबर',
          hintText: 'Enter your phone number',
          prefixIcon: Icons.phone,
          controller: _phoneController,
          validator: (value) =>
              value.isEmpty ? 'Please enter your phone number' : null,
          isDisabled: true,
        ),
        const SizedBox(height: 16),

        // Gender Field - Required
        DropdownButtonFormField<String>(
          value: _selectedGender,
          style: const TextStyle(fontSize: 16, color: Colors.black),
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            labelText: 'Gender / लिंग *',
            labelStyle: const TextStyle(fontSize: 14),
            prefixIcon: const Icon(
              Icons.person_outline,
              size: 20,
              color: Colors.black87,
            ),
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
          ),
          items: [
            DropdownMenuItem(
              value: 'Male',
              child: Semantics(
                label: 'Male',
                child: const Text(
                  'Male / पुरुष',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'Female',
              child: Semantics(
                label: 'Female',
                child: const Text(
                  'Female / स्त्री',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'Other',
              child: Semantics(
                label: 'Other',
                child: const Text(
                  'Other / इतर',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
          ],
          onChanged: (value) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedGender = value!;
            });
          },
        ),
        const SizedBox(height: 16),

        // Date of Birth Field - Optional
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date of Birth / जन्मतारीख (Optional)',
              labelStyle: const TextStyle(fontSize: 14),
              prefixIcon: const Icon(Icons.cake, size: 20, color: Colors.grey),
              suffixIcon: const Icon(
                Icons.calendar_today,
                size: 18,
                color: Colors.grey,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFCB853),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            child: Text(
              _selectedDate == null
                  ? 'Tap to select'
                  : _formatDateIndian(_selectedDate!),
              style: TextStyle(
                fontSize: 16,
                color: _selectedDate == null ? Colors.grey[600] : Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Occupation Field - Optional
        _buildFormField(
          labelText: 'Occupation / व्यवसाय (Optional)',
          hintText: 'Enter your occupation',
          prefixIcon: Icons.work_outline,
          controller: _occupationController,
          validator: (value) => null,
        ),
        const SizedBox(height: 24),

        // Submit Button
        ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFCB853),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
          child: const Text(
            'Register',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),

        // Helper Text
        Text(
          '* Required fields',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOrganizationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Organization Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!, width: 1),
          ),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 40, color: Colors.blue[700]),
              const SizedBox(height: 12),
              Text(
                'What is an Organization?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Organizations are for groups associated with NGOs or institutions where a head administrator manages funding and user access. If you can pay independently, register as a Single User. If you\'re part of a group supported by an NGO or organization, use this option.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Referral Key Field
        Semantics(
          label: 'Organization key field',
          hint: 'Enter your organization key',
          child: _buildFormField(
            labelText: 'Organization Key *',
            hintText: 'Enter your organization key',
            prefixIcon: Icons.vpn_key,
            controller: _referralKeyController,
            validator: (value) =>
                value.isEmpty ? 'Please enter your organization key' : null,
          ),
        ),
        const SizedBox(height: 12),

        // Verify Button
        ElevatedButton(
          onPressed: _verifyReferralKey,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
          child: const Text(
            'Join Organization',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 12),

        // Contact Support
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!, width: 1),
          ),
          child: Column(
            children: [
              Icon(Icons.email_outlined, size: 36, color: Colors.green[700]),
              const SizedBox(height: 10),
              Text(
                'Need an Organization Key?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Contact us to create your organization:',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              SelectableText(
                'support.letsee@google.com',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCB853),
      appBar: AppBar(
        title: const Text('', semanticsLabel: 'Registration Page'),
        backgroundColor: const Color(0xFFFCB853),
        elevation: 0,
      ),
      body: _isLoading
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        child: const Column(
                          children: [
                            Text(
                              'Welcome!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFCB853),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Choose your registration type',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // Tab Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _tabController,
                          onTap: (index) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _isOrganizationVerified = false;
                            });
                          },
                          indicator: BoxDecoration(
                            color: const Color(0xFFFCB853),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[700],
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          tabs: const [
                            Tab(
                              text: 'Single User',
                              icon: Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.black87,
                              ),
                            ),
                            Tab(
                              text: 'Organization',
                              icon: Icon(
                                Icons.business,
                                size: 20,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tab Bar View
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Form(
                            key: _formKey,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Single User Tab
                                SingleChildScrollView(
                                  child: _buildUserDetailsForm(),
                                ),

                                // Organization Tab
                                SingleChildScrollView(
                                  child: !_isOrganizationVerified
                                      ? _buildOrganizationForm()
                                      : _buildUserDetailsForm(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _referralKeyController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
