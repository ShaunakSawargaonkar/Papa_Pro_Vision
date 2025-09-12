import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:papa_pro_vision/Helper/DeviceHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:papa_pro_vision/UI/home_screen.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _referralKeyController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedGender = 'Male';
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final deviceId = await Devicehelper.getDeviceId();

      // Check if device is already registered
      final existingUsers = await FirebaseFirestore.instance
          .collection('Users')
          .where('deviceId', isEqualTo: deviceId)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This device is already registered. Please contact owner if you need assistance.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      var keyCollection =
          (await FirebaseFirestore.instance
                  .collection('Referral Key')
                  .doc('kLpFasXX3A5g9cpJsi6E')
                  .get())
              .data();

      var keyData = keyCollection![_referralKeyController.text];
      if (keyData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid Referral Key'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      } else {
        var keyDataMaxCount =
            keyCollection[_referralKeyController.text]['MaxCount'];
        var keyDataCount = keyCollection[_referralKeyController.text]['Count'];
        if (keyDataCount >= keyDataMaxCount) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Referral Key usage limit reached'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        } else {
          // Increment the count
          await FirebaseFirestore.instance
              .collection('Referral Key')
              .doc('kLpFasXX3A5g9cpJsi6E')
              .update({
                '${_referralKeyController.text}.Count': FieldValue.increment(1),
              });
        }
      }

      // Create userif(ketDara) document in Firestore
      await FirebaseFirestore.instance.collection('Users').add({
        'name': _nameController.text,
        'contactNumber': _contactController.text,
        'email': _emailController.text,
        'gender': _selectedGender,
        'dob': Timestamp.fromDate(_selectedDate!),
        'occupation': _occupationController.text,
        'referralKey': _referralKeyController.text,
        'deviceId': deviceId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'Analytics': {
          'ResponseCount': 0,
          'TTSErrorCount': 0,
          'STTErrorCount': 0,
          'PromptErrorCount': 0,
          'CancelledRequestCount': 0,
          'ImageCaptureCount': 0,
          'LLMInteractionWithImageCount': 0,
          'JustLLMInteractionCount': 0,
          'SmartViewModeCount': 0,
          'ReaderModeCount': 0,
          'TranslationCount': 0,
          'MarathiResponseCount': 0,
          'EnglishResponseCount': 0,
        },
      });

      // Set registration status in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isRegistered', true);

      // Navigate to home screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e, stackTrace) {
      print('Error saving to Firestore: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error registering user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name/नाव *',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number/संपर्क क्रमांक *',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Contact number is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return null;
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value!)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender/लिंग *',
                      ),
                      items: ['Male', 'Female', 'Other']
                          .map(
                            (gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        _selectedDate == null
                            ? 'Select Date of Birth/जन्मतारीख निवडा'
                            : 'DoB: ${_selectedDate.toString().split(' ')[0]}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _occupationController,
                      decoration: const InputDecoration(
                        labelText: 'Occupation/व्यवसाय',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _referralKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Referral Key/ संदर्भ कोड *',
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Referral Key is required'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _occupationController.dispose();
    _referralKeyController.dispose();
    super.dispose();
  }
}
