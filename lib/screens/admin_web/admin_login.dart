import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      // Dynamic Foolproof Scan
      final snapshot = await FirebaseFirestore.instance
          .collection('admin_credentials')
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'The admin_credentials collection is completely empty or missing in newproject-52066!';
            _isLoading = false;
          });
        }
        return;
      }

      bool foundMatch = false;
      String lastChecked = '';

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Convert to string and trim spaces to prevent ANY typos or Number vs String issues!
        final dbUser = data['username']?.toString().trim() ?? '';
        final dbPass = data['password']?.toString().trim() ?? '';
        final inputUser = _idController.text.trim();
        final inputPass = _passController.text.trim();

        lastChecked = "Database: '$dbUser' / '$dbPass'\nYou typed: '$inputUser' / '$inputPass'";

        if (dbUser == inputUser && dbPass == inputPass) {
          foundMatch = true;
          break;
        }
      }

      if (foundMatch) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "No Match Found!\nLast checked account:\n$lastChecked";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Database Error. Check Firebase Rules.\n$e';
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
                  labelText: 'Admin ID',
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
