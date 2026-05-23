import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/location_service.dart';
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final inputUser = _idController.text.trim();
      final inputPass = _passController.text.trim();

      if (inputUser.isEmpty || inputPass.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter email and password.';
          _isLoading = false;
        });
        return;
      }

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: inputUser,
        password: inputPass,
      );

      final doc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();

      if (doc.exists && doc.data()!['role'] == 'Admin') {
        try {
          final locData = await LocationService.fetchIpAndLocation();
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).update({
            'ip': locData['ip'],
            'location': locData['location'],
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } catch (_) {}

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        }
      } else {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(() {
            _errorMessage = 'Access Denied: You do not have Admin privileges.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Login Failed: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                size: 80,
                color: Color(0xFF0D47A1),
              ),
              const SizedBox(height: 16),
              const Text(
                'Superadmin Portal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: 'Admin Email',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 8),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
