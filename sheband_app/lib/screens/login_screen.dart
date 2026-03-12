import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_account_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;

  Future<void> _sendOtpOrRedirect() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    try {
      // 1. Check if email exists in our profiles table
      final response = await Supabase.instance.client
          .from('profiles')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        // Email not found -> Ask to create account
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account not found. Please create an account.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAccountScreen()));
        }
      } else {
        // Email found -> Send OTP
        await Supabase.instance.client.auth.signInWithOtp(email: email);
        setState(() => _otpSent = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to your email!'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtpAndLogin() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.email,
      );
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.pinkAccent),
              const SizedBox(height: 24),
              const Text('SheBand', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 48),
              
              TextField(
                controller: _emailController,
                enabled: !_otpSent,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              if (_otpSent) ...[
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(labelText: 'Enter 6-digit OTP', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtpAndLogin,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Verify & Login'),
                ),
              ] else ...[
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtpOrRedirect,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login / Send OTP'),
                ),
              ],

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAccountScreen())),
                child: const Text('New User? Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}