import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:papa_pro_vision/UI/home_screen.dart';
import 'package:papa_pro_vision/Helper/DatabaseHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:papa_pro_vision/enums.dart';

class RegistrationPage extends StatefulWidget {
  final String? phoneNumber;
  final String userUID;
  const RegistrationPage({super.key, required this.phoneNumber, required this.userUID});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _referralKeyController = TextEditingController();

  String _selectedGender = 'Male';
  bool _isLoading = false;
  bool _isOrganizationVerified = false;
  late TabController _tabController;

  DocumentReference? _orgRef;
  DocumentReference? _referralKeyRef;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPhoneNumber();
  }

  Future<void> _loadPhoneNumber() async {
    // Prioritize widget parameter, fallback to SharedPreferences
    if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      setState(() {
        _phoneController.text = widget.phoneNumber!.startsWith('+91')
            ? widget.phoneNumber!
            : '+91${widget.phoneNumber!}';
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('contactNumber') ?? '+91';
      final formattedPhoneNumber = phoneNumber.startsWith('+91')
          ? phoneNumber
          : '+91${phoneNumber}';
      setState(() {
        _phoneController.text = formattedPhoneNumber;
      });
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
      referralKeyName: _referralKeyController.text,
    );
    if (!result.success) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'Something went wrong. Please try again later.',
            ),
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

    print('Navigating to Payment Page');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
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
      userUID: widget.userUID,
      age: int.parse(_ageController.text),
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
            content: Text(
              result.message ?? 'Something went wrong. Please try again later.',
            ),
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

    // Navigate to Payment Page
    print('Navigating to Payment Page');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          // builder: (context) => PaymentGateway(isFirstPayment: true, userUID: widget.userUID, phoneNumber: _phoneController.text),
          builder: (context) => HomeScreen(),
        ),
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
    bool isDisabled = false,
    bool isNumeric = false,
    required double fontSizeSmall,
    required double fontSizeMedium,
    required double iconSizeMedium,
    required double borderRadiusMedium,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !isDisabled,
      textCapitalization: isNumeric ? TextCapitalization.none : TextCapitalization.words,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: TextStyle(
        fontSize: fontSizeMedium,
        color: isDisabled ? Colors.grey[600] : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(fontSize: fontSizeSmall, color: Colors.grey[400]),
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, size: iconSizeMedium, color: Colors.grey),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: iconSizeMedium * 0.9, color: Colors.grey)
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: fontSizeMedium,
          vertical: fontSizeSmall,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadiusMedium)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: Color(0xFFFCB853), width: 2),
        ),
        filled: true,
        fillColor: isDisabled ? Colors.grey[100] : Colors.grey[50],
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      validator: validator,
      onTap: () => HapticFeedback.selectionClick(),
    );
  }

  Widget _buildUserDetailsForm({
    required double spacingSmall,
    required double spacingMedium,
    required double spacingLarge,
    required double spacingXSmall,
    required double fontSizeSmall,
    required double fontSizeMedium,
    required double fontSizeLarge,
    required double iconSizeMedium,
    required double iconSizeSmall,
    required double borderRadiusMedium,
    required double paddingSmall,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Change Organization Button - only show when organization is verified
        if (_isOrganizationVerified) ...[
          SizedBox(height: spacingXSmall),
          Center(
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isOrganizationVerified = false;
                  _referralKeyController.clear();
                  _orgRef = null;
                  _referralKeyRef = null;
                });
              },
              icon: Icon(Icons.edit, size: iconSizeSmall, color: Colors.grey[600]),
              label: Text(
                'Change Organization',
                style: TextStyle(
                  fontSize: fontSizeSmall,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: spacingMedium),
        // Name Field - Required
        _buildFormField(
          labelText: 'Name',
          hintText: 'Enter your name',
          prefixIcon: Icons.person,
          controller: _nameController,
          validator: (value) => value.isEmpty ? 'Please enter your name' : null,
          fontSizeSmall: fontSizeSmall,
          fontSizeMedium: fontSizeMedium,
          iconSizeMedium: iconSizeMedium,
          borderRadiusMedium: borderRadiusMedium,
        ),
        SizedBox(height: spacingMedium),

        _buildFormField(
          labelText: 'Phone Number',
          hintText: 'Enter your phone number',
          prefixIcon: Icons.phone,
          isNumeric: true,
          controller: _phoneController,
          validator: (value) =>
              value.isEmpty ? 'Please enter your phone number' : null,
          isDisabled: _phoneController.text.isNotEmpty && _phoneController.text != '+91',
          fontSizeSmall: fontSizeSmall,
          fontSizeMedium: fontSizeMedium,
          iconSizeMedium: iconSizeMedium,
          borderRadiusMedium: borderRadiusMedium,
        ),
        SizedBox(height: spacingMedium),

        // Gender Field - Required
        DropdownButtonFormField<String>(
          value: _selectedGender,
          style: TextStyle(fontSize: fontSizeMedium, color: Colors.black),
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            labelText: 'Gender',
            labelStyle: TextStyle(fontSize: fontSizeSmall),
            prefixIcon: Icon(
              Icons.person_outline,
              size: iconSizeMedium,
              color: Colors.black87,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: fontSizeMedium,
              vertical: fontSizeSmall,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadiusMedium)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadiusMedium),
              borderSide: const BorderSide(color: Color(0xFFFCB853), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: [
            DropdownMenuItem(
              value: 'Male',
              child: Semantics(
                label: '',
                child: Text(
                  'Male',
                  style: TextStyle(fontSize: fontSizeMedium, color: Colors.black),
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'Female',
              child: Semantics(
                label: '',
                child: Text(
                  'Female',
                  style: TextStyle(fontSize: fontSizeMedium, color: Colors.black),
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'Other',
              child: Semantics(
                label: '',
                child: Text(
                  'Other',
                  style: TextStyle(fontSize: fontSizeMedium, color: Colors.black),
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
        SizedBox(height: spacingMedium),

        // Date of Birth Field - Optional
       _buildFormField(
          labelText: 'Age',
          hintText: 'Enter your age',
          isNumeric: true,
          prefixIcon: Icons.person,
          controller: _ageController,
          validator: (value) => null,
          fontSizeSmall: fontSizeSmall,
          fontSizeMedium: fontSizeMedium,
          iconSizeMedium: iconSizeMedium,
          borderRadiusMedium: borderRadiusMedium,
        ),
        SizedBox(height: spacingMedium),

        // Occupation Field - Optional
        _buildFormField(
          labelText: 'Occupation',
          hintText: 'Enter your occupation',
          prefixIcon: Icons.work_outline,
          controller: _occupationController,
          validator: (value) => null,
          fontSizeSmall: fontSizeSmall,
          fontSizeMedium: fontSizeMedium,
          iconSizeMedium: iconSizeMedium,
          borderRadiusMedium: borderRadiusMedium,
        ),
        SizedBox(height: spacingLarge),

        // Submit Button
        ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFCB853),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: paddingSmall),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusMedium),
            ),
            elevation: 3,
          ),
          child: Text(
            'Register',
            style: TextStyle(fontSize: fontSizeLarge, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: spacingSmall),
      ],
    );
  }

  Widget _buildOrganizationForm({
    required double spacingSmall,
    required double spacingMedium,
    required double spacingLarge,
    required double fontSizeSmall,
    required double fontSizeMedium,
    required double fontSizeLarge,
    required double fontSizeXLarge,
    required double iconSizeLarge,
    required double borderRadiusMedium,
    required double paddingSmall,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Organization Info
        Container(
          padding: EdgeInsets.all(paddingSmall),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(borderRadiusMedium),
            border: Border.all(color: Colors.blue[200]!, width: 1),
          ),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: iconSizeLarge, color: Colors.blue[700]),
              SizedBox(height: spacingSmall),
              Text(
                'About Organizations',
                style: TextStyle(
                  fontSize: fontSizeXLarge,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacingSmall * 0.7),
              Text(
                'Organizations are meant for NGO or institutional groups where an admin oversees funding and user access. Register as a Single User if you handle payments yourself.',
                style: TextStyle(
                  fontSize: fontSizeSmall,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        SizedBox(height: spacingSmall),

        // Referral Key Field
        Semantics(
          label: 'Organization key field',
          hint: 'Enter your organization key',
          child: _buildFormField(
            labelText: 'Organization Key',
            hintText: 'Enter your organization key',
            prefixIcon: Icons.vpn_key,
            controller: _referralKeyController,
            validator: (value) =>
                value.isEmpty ? 'Please enter your organization key' : null,
            fontSizeSmall: fontSizeSmall,
            fontSizeMedium: fontSizeMedium,
            iconSizeMedium: fontSizeMedium * 1.25,
            borderRadiusMedium: borderRadiusMedium,
          ),
        ),
        SizedBox(height: spacingSmall),

        // Verify Button
        ElevatedButton(
          onPressed: _verifyReferralKey,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: paddingSmall),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusMedium),
            ),
            elevation: 3,
          ),
          child: Text(
            'Join Organization',
            style: TextStyle(fontSize: fontSizeLarge, fontWeight: FontWeight.bold),
          ),
        ),

        SizedBox(height: spacingSmall),

        // Contact Support
        Container(
          padding: EdgeInsets.all(paddingSmall),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(borderRadiusMedium),
            border: Border.all(color: Colors.green[200]!, width: 1),
          ),
          child: Column(
            children: [
              Icon(Icons.email_outlined, size: iconSizeLarge, color: Colors.green[700]),
              SizedBox(height: spacingSmall * 0.8),
              Text(
                'Need an Organization Key?',
                style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacingSmall * 0.5),
              Text(
                'Contact us to create your organization:',
                style: TextStyle(fontSize: fontSizeSmall, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacingSmall * 0.5),
              SelectableText(
                'help.letsee@google.com',
                style: TextStyle(
                  fontSize: fontSizeSmall,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        SizedBox(height: spacingSmall),
      ],
    );
  }

  Future<void> _skipRegistration() async {
    // Haptic feedback
    HapticFeedback.mediumImpact();

    if(_phoneController.text.isEmpty || _phoneController.text == '+91') {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = true;
    });

    print('Skipping registration - creating minimal user');

    CreateUserResponse result = await DatabaseHelper.createUser(
      userUID: FirebaseAuth.instance.currentUser?.uid ?? '',
      age: -1,
      gender: '',
      name: '',
      phoneNumber: _phoneController.text,
      occupation: '',
      userType: UserType.single,
      referralKeyRef: null,
      orgRef: null,
    );

    print('Skip registration result: $result');

    if (!result.success) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'Something went wrong. Please try again later.',
            ),
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Navigate to Payment Page
    print('Navigating to Payment Page');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          // builder: (context) => PaymentGateway(isFirstPayment: true, userUID: widget.userUID, phoneNumber: _phoneController.text),
          builder: (context) => HomeScreen(),

        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Define responsive constants
    // Spacing
    final spacingXSmall = screenHeight * 0.008; // ~6px on standard phone
    final spacingSmall = screenHeight * 0.015; // ~12px
    final spacingMedium = screenHeight * 0.020; // ~16px
    final spacingLarge = screenHeight * 0.030; // ~24px
    
    // Font sizes
    final fontSizeSmall = screenWidth * 0.035; // ~13px
    final fontSizeMedium = screenWidth * 0.040; // ~16px
    final fontSizeLarge = screenWidth * 0.045; // ~18px
    final fontSizeXLarge = screenWidth * 0.055; // ~22px
    final fontSizeTitle = screenWidth * 0.070; // ~28px
    
    // Icon sizes
    final iconSizeSmall = screenWidth * 0.040; // ~16px
    final iconSizeMedium = screenWidth * 0.050; // ~20px
    final iconSizeLarge = screenWidth * 0.090; // ~36px
    
    // Border radius
    final borderRadiusSmall = screenWidth * 0.025; // ~10px
    final borderRadiusMedium = screenWidth * 0.030; // ~12px
    final borderRadiusLarge = screenWidth * 0.050; // ~20px
    
    // Padding
    final paddingHorizontal = screenWidth * 0.060; // ~24px
    final paddingVertical = screenHeight * 0.020; // ~16px
    final paddingSmall = screenWidth * 0.040; // ~16px
    
    // Container constraints
    final maxContainerWidth = screenWidth * 0.95 > 550 ? 550.0 : screenWidth * 0.95;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFCB853),
      appBar: AppBar(
        title: const Text('', semanticsLabel: 'Registration Page'),
        backgroundColor: const Color(0xFFFCB853),
        elevation: 0,
        actions: [
          // Skip button - only show for single users
          if (_tabController.index == 0 && !_isOrganizationVerified)
            Semantics(
              label: 'Skip button',
              child: TextButton.icon(
                  onPressed: _skipRegistration,
                  icon: Icon(Icons.arrow_forward, 
                    color: Colors.white,
                    size: iconSizeMedium,
                  ),
                  label: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ),
        ],
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
                  constraints: BoxConstraints(maxWidth: maxContainerWidth),
                  margin: EdgeInsets.symmetric(
                    horizontal: paddingHorizontal,
                    vertical: paddingVertical,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadiusLarge),
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
                        padding: EdgeInsets.all(spacingLarge),
                        child: Column(
                          children: [
                            // Organization indicator when verified
                            if (_isOrganizationVerified) ...[
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacingMedium,
                                  vertical: spacingXSmall,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(borderRadiusLarge),
                                  border: Border.all(
                                    color: Colors.green[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.business,
                                      size: iconSizeSmall,
                                      color: Colors.green[700],
                                    ),
                                    SizedBox(width: spacingXSmall),
                                    Text(
                                      'Organization Registration',
                                      style: TextStyle(
                                        fontSize: fontSizeSmall,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: spacingMedium),
                            ],
                            Text(
                              'Welcome!',
                              style: TextStyle(
                                fontSize: fontSizeTitle,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFCB853),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: spacingXSmall),
                            // Text(
                            //   _isOrganizationVerified
                            //       ? 'Complete your organization registration'
                            //       : 'Choose your registration type',
                            //   style: const TextStyle(
                            //     fontSize: 14,
                            //     color: Colors.grey,
                            //   ),
                            //   textAlign: TextAlign.center,
                            // ),
                          ],
                        ),
                      ),

                      // Tab Bar - Only show when organization is not verified
                      if (!_isOrganizationVerified) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(borderRadiusMedium),
                          ),
                          margin: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                          padding: EdgeInsets.all(spacingXSmall * 0.5),
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
                              borderRadius: BorderRadius.circular(borderRadiusSmall),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey[700],
                            labelStyle: TextStyle(
                              fontSize: fontSizeSmall,
                              fontWeight: FontWeight.bold,
                            ),
                            tabs: [
                              Tab(
                                text: 'Single User',
                                icon: Icon(
                                  Icons.person,
                                  size: iconSizeMedium,
                                  color: Colors.black87,
                                ),
                              ),
                              Tab(
                                text: 'Organization',
                                icon: Icon(
                                  Icons.business,
                                  size: iconSizeMedium,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacingSmall),
                      ],

                      // Content Area
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                          child: Form(
                            key: _formKey,
                            child: _isOrganizationVerified
                                ? SingleChildScrollView(
                                    child: _buildUserDetailsForm(
                                      spacingSmall: spacingSmall,
                                      spacingMedium: spacingMedium,
                                      spacingLarge: spacingLarge,
                                      spacingXSmall: spacingXSmall,
                                      fontSizeSmall: fontSizeSmall,
                                      fontSizeMedium: fontSizeMedium,
                                      fontSizeLarge: fontSizeLarge,
                                      iconSizeMedium: iconSizeMedium,
                                      iconSizeSmall: iconSizeSmall,
                                      borderRadiusMedium: borderRadiusMedium,
                                      paddingSmall: paddingSmall,
                                    ),
                                  )
                                : TabBarView(
                                    controller: _tabController,
                                    children: [
                                      // Single User Tab
                                      SingleChildScrollView(
                                        child: _buildUserDetailsForm(
                                          spacingSmall: spacingSmall,
                                          spacingMedium: spacingMedium,
                                          spacingLarge: spacingLarge,
                                          spacingXSmall: spacingXSmall,
                                          fontSizeSmall: fontSizeSmall,
                                          fontSizeMedium: fontSizeMedium,
                                          fontSizeLarge: fontSizeLarge,
                                          iconSizeMedium: iconSizeMedium,
                                          iconSizeSmall: iconSizeSmall,
                                          borderRadiusMedium: borderRadiusMedium,
                                          paddingSmall: paddingSmall,
                                        ),
                                      ),

                                      // Organization Tab
                                      SingleChildScrollView(
                                        child: _buildOrganizationForm(
                                          spacingSmall: spacingSmall,
                                          spacingMedium: spacingMedium,
                                          spacingLarge: spacingLarge,
                                          fontSizeSmall: fontSizeSmall,
                                          fontSizeMedium: fontSizeMedium,
                                          fontSizeLarge: fontSizeLarge,
                                          fontSizeXLarge: fontSizeXLarge,
                                          iconSizeLarge: iconSizeLarge,
                                          borderRadiusMedium: borderRadiusMedium,
                                          paddingSmall: paddingSmall,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacingMedium),
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
