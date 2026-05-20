import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _passFormKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _userFormKey = GlobalKey<FormState>();
  final _oldUsernameController = TextEditingController();
  final _newUsernameController = TextEditingController();

  bool _isPassLoading = false;
  bool _isUserLoading = false;
  
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _oldUsernameController.dispose();
    _newUsernameController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _isPassLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance.collection('admin_credentials').get();
      if (snapshot.docs.isEmpty) throw Exception("Admin credentials not found.");

      final docRef = snapshot.docs.first.reference;
      final currentDbPassword = snapshot.docs.first.data()['password']?.toString() ?? '';

      if (_oldPasswordController.text != currentDbPassword) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect current password.'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isPassLoading = false);
        return;
      }

      await docRef.update({'password': _newPasswordController.text});

      if (mounted) {
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPassLoading = false);
    }
  }

  void _changeUsername() async {
    if (!_userFormKey.currentState!.validate()) return;
    setState(() => _isUserLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance.collection('admin_credentials').get();
      if (snapshot.docs.isEmpty) throw Exception("Admin credentials not found.");

      final docRef = snapshot.docs.first.reference;
      final currentDbUsername = snapshot.docs.first.data()['username']?.toString() ?? '';

      if (_oldUsernameController.text.trim() != currentDbUsername) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect current username.'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isUserLoading = false);
        return;
      }

      await docRef.update({'username': _newUsernameController.text.trim()});

      if (mounted) {
        _oldUsernameController.clear();
        _newUsernameController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUserLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your Superadmin portal preferences.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 40),
          
          SizedBox(
            width: 500,
            child: Column(
              children: [
                // Change Username Accordion
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    leading: const Icon(Icons.person, color: Color(0xFF0D47A1)),
                    title: const Text('Change Username', style: TextStyle(fontWeight: FontWeight.bold)),
                    childrenPadding: const EdgeInsets.all(24),
                    children: [
                      Form(
                        key: _userFormKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _oldUsernameController,
                              decoration: const InputDecoration(
                                labelText: 'Current Username',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _newUsernameController,
                              decoration: const InputDecoration(
                                labelText: 'New Username',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isUserLoading ? null : _changeUsername,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0D47A1),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: _isUserLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Update Username', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Change Password Accordion
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    leading: const Icon(Icons.security, color: Color(0xFF0D47A1)),
                    title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
                    childrenPadding: const EdgeInsets.all(24),
                    children: [
                      Form(
                        key: _passFormKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _oldPasswordController,
                              obscureText: _obscureOld,
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                                ),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: _obscureNew,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                ),
                              ),
                              validator: (val) => val != null && val.length < 3 ? 'Too short' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                labelText: 'Confirm New Password',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: (val) => val != _newPasswordController.text ? 'Passwords do not match' : null,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isPassLoading ? null : _changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0D47A1),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: _isPassLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
