// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../home_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _loadingLocation = false;
  bool _otpSent = false;
  bool _emailVerified = false;
  String? _sentOtp; // Simulating a sent OTP

  Future<void> _sendVerification() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email first')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Simulate sending OTP
      await Future.delayed(const Duration(seconds: 1));
      _sentOtp = "1234"; // Fixed OTP for prototype/demo
      setState(() {
        _otpSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification OTP (1234) sent to $email.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send OTP: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text == _sentOtp) {
      setState(() {
        _emailVerified = true;
        _otpSent = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified successfully!'), backgroundColor: AppTheme.primaryGreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);

        String village = '';
        String district = '';

        if (kIsWeb) {
          final url = Uri.parse(
              'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1');
          final response = await http.get(url, headers: {'User-Agent': 'AgroScanApp'});
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final addr = data['address'] as Map<String, dynamic>;
            
            // Try many possible keys for the most local identifier
            village = addr['village'] ?? addr['hamlet'] ?? addr['suburb'] ?? addr['neighbourhood'] ?? 
                      addr['town'] ?? addr['city_district'] ?? addr['road'] ?? '';
            
            // Try many possible keys for the district/city
            district = addr['state_district'] ?? addr['county'] ?? addr['city'] ?? addr['state'] ?? '';
          }
        } else {
          List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            village = place.subLocality ?? place.locality ?? place.name ?? place.thoroughfare ?? '';
            district = place.subAdministrativeArea ?? place.administrativeArea ?? '';
          }
        }

        if (village.isNotEmpty || district.isNotEmpty) {
          // Clean up string
          String result = "";
          if (village.isNotEmpty) result += village;
          if (district.isNotEmpty) {
            if (result.isNotEmpty) result += ", ";
            result += district;
          }
          _locationCtrl.text = result;
        } else if (kIsWeb) {
           // Extreme fallback for web
           _locationCtrl.text = "Lat: ${position.latitude.toStringAsFixed(2)}, Lon: ${position.longitude.toStringAsFixed(2)}";
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().register(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            location: _locationCtrl.text.trim(),
          );
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? type, bool obscure = false, Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
        ),
        validator: (v) => v!.isNotEmpty ? null : 'Required',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Join AgroScan AI 🌱',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Start detecting crop diseases instantly',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 28),
              _field('Full Name', _nameCtrl, Icons.person_outline),
              _field('Email', _emailCtrl, Icons.email_outlined,
                  type: TextInputType.emailAddress,
                  suffix: _emailVerified
                      ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                      : TextButton(
                          onPressed: _loading || _otpSent ? null : _sendVerification,
                          child: Text(_otpSent ? 'Sent' : 'Verify'),
                        )),
              
              if (_otpSent && !_emailVerified)
                Column(
                  children: [
                    _field('Enter 4-Digit OTP', _otpCtrl, Icons.lock_clock_outlined,
                        type: TextInputType.number,
                        suffix: IconButton(
                          icon: const Icon(Icons.check, color: AppTheme.primaryGreen),
                          onPressed: _verifyOtp,
                        )),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('Hint: Use 1234 for demo', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                  ],
                ),

              if (_emailVerified)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user_outlined, size: 20, color: AppTheme.primaryGreen),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Email successfully verified with OTP. You can now complete your profile.',
                            style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              _field('Phone Number', _phoneCtrl, Icons.phone_outlined,
                  type: TextInputType.phone),
              _field('Village / District', _locationCtrl, Icons.location_on_outlined,
                  suffix: IconButton(
                    icon: _loadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, color: AppTheme.primaryGreen),
                    onPressed: _loadingLocation ? null : _getCurrentLocation,
                  )),
              _field('Password', _passCtrl, Icons.lock_outline, obscure: true),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loading || (!_emailVerified) ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
