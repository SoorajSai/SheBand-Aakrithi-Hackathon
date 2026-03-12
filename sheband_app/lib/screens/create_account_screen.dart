import 'dart:io';
import 'dart:async'; // Added for the countdown timer
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _otpController = TextEditingController();
  
  File? _profileImage;
  
  List<Map<String, TextEditingController>> _contacts = [
    {'name': TextEditingController(), 'number': TextEditingController()}
  ];

  bool _isLoading = false;
  bool _otpSent = false;
  
  // Timer variables for Resend OTP
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void dispose() {
    _resendTimer?.cancel(); // Clean up timer when screen is closed
    super.dispose();
  }

  // Starts the 60-second countdown
  void _startResendTimer() {
    setState(() => _resendSeconds = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50,
    );
    
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _addContact() {
    setState(() {
      _contacts.add({'name': TextEditingController(), 'number': TextEditingController()});
    });
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an email')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: _emailController.text.trim(),
      );
      
      setState(() => _otpSent = true);
      _startResendTimer(); // Start the cooldown timer
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to your email!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndCreateAccount() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.email,
      );

      if (res.user != null) {
        String? avatarUrl;

        if (_profileImage != null) {
          final fileExt = _profileImage!.path.split('.').last;
          final fileName = '${res.user!.id}.$fileExt';
          
          await Supabase.instance.client.storage
              .from('avatars')
              .upload(fileName, _profileImage!, fileOptions: const FileOptions(upsert: true));
              
          avatarUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
        }

        List<Map<String, String>> contactsJson = _contacts.map((c) => {
          'name': c['name']!.text.trim(),
          'number': c['number']!.text.trim(),
        }).toList();

        await Supabase.instance.client.from('profiles').insert({
          'id': res.user!.id,
          'email': _emailController.text.trim(),
          'full_name': _nameController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'age': _ageController.text.trim(),
          'blood_group': _bloodGroupController.text.trim(),
          'emergency_contacts': contactsJson,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        });

        if (mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP or Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: _otpSent ? null : _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null 
                          ? const Icon(Icons.person, size: 50, color: Colors.white54) 
                          : null,
                    ),
                    if (!_otpSent)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildTextField('Email', _emailController, keyboardType: TextInputType.emailAddress, enabled: !_otpSent),
            _buildTextField('Full Name', _nameController, enabled: !_otpSent),
            _buildTextField('Your Phone Number', _phoneController, keyboardType: TextInputType.phone, enabled: !_otpSent),
            Row(
              children: [
                Expanded(child: _buildTextField('Age', _ageController, keyboardType: TextInputType.number, enabled: !_otpSent)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField('Blood Group', _bloodGroupController, enabled: !_otpSent)),
              ],
            ),
            const Divider(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Emergency contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (!_otpSent)
                  IconButton(
                    icon: const Icon(Icons.add_box, color: Colors.pinkAccent, size: 32),
                    onPressed: _addContact,
                  )
              ],
            ),
            const SizedBox(height: 16),
            
            ...List.generate(_contacts.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.pinkAccent.withOpacity(0.5), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phone ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                    const SizedBox(height: 8),
                    TextField(controller: _contacts[index]['name'], enabled: !_otpSent, decoration: const InputDecoration(hintText: 'Name', isDense: true)),
                    const SizedBox(height: 8),
                    TextField(controller: _contacts[index]['number'], enabled: !_otpSent, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Number', isDense: true)),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            if (_otpSent) ...[
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'Enter 6-digit OTP', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyAndCreateAccount,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Verify & Create Account'),
              ),
              const SizedBox(height: 12),
              
              // NEW RESEND OTP BUTTON
              TextButton(
                onPressed: _resendSeconds == 0 && !_isLoading ? _sendOtp : null,
                child: Text(
                  _resendSeconds == 0 
                      ? 'Resend OTP' 
                      : 'Resend OTP in $_resendSeconds s',
                  style: TextStyle(
                    color: _resendSeconds == 0 ? Colors.pinkAccent : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send OTP'),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: keyboardType,
      ),
    );
  }
}