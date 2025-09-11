import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emergencyContactController;
  double _speechRate = 1.0;
  String _selectedLanguage = 'en_IN';
  bool _enableTranslation = true;
  bool _useFrontCamera = false;

  @override
  void initState() {
    super.initState();
    _emergencyContactController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyContactController.text =
          prefs.getString('emergencyContact') ?? '';
      _speechRate = prefs.getDouble('speechRate') ?? 1.0;
      _selectedLanguage = prefs.getString('inputLanguage') ?? 'en_IN';
      _enableTranslation = prefs.getBool('enableTranslation') ?? false;
      _useFrontCamera = prefs.getBool('useFrontCamera') ?? false;
    });
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'emergencyContact',
        _emergencyContactController.text,
      );
      await prefs.setDouble('speechRate', _speechRate);
      await prefs.setString('inputLanguage', _selectedLanguage);
      await prefs.setBool('enableTranslation', _enableTranslation);
      await prefs.setBool('useFrontCamera', _useFrontCamera);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        // Pop the page after successful save
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emergencyContactController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.emergency),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              const Text(
                'Speech Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: const InputDecoration(
                  labelText: 'Input Language',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'en_IN',
                    child: Text('English (India)'),
                  ),
                  DropdownMenuItem(value: 'mr_IN', child: Text('Marathi')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLanguage = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.speed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Speech Rate'),
                        Slider(
                          value: _speechRate,
                          min: 0.25,
                          max: 2.0,

                          divisions: 7,
                          label: _speechRate.toStringAsFixed(2),
                          onChanged: (value) {
                            setState(() {
                              print('yoooooo $value');
                              _speechRate = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enable Translation'),
                subtitle: const Text('Translate text to selected input language'),
                value: _enableTranslation,
                onChanged: (value) {
                  setState(() {
                    _enableTranslation = value;
                  });
                },
                secondary: const Icon(Icons.translate),
              ),
              const SizedBox(height: 24),
              const Text(
                'App Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Use Front Camera'),
                subtitle: const Text('Switch between front and back camera'),
                value: _useFrontCamera,
                onChanged: (value) {
                  setState(() {
                    _useFrontCamera = value;
                  });
                },
                secondary: const Icon(Icons.camera_front),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveUserData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
