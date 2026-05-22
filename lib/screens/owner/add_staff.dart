import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../services/location_service.dart';
import '../../models/employee_model.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();

  String _selectedRole = 'Employee';
  String? _selectedBusinessId;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusinessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a business'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final owner = FirebaseAuth.instance.currentUser;
      if (owner == null) throw Exception("Owner not logged in");

      // 1. Create a secondary Firebase App instance to register the user without logging the Owner out
      FirebaseApp? secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }

      UserCredential? credential;
      try {
        credential = await FirebaseAuth.instanceFor(app: secondaryApp)
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } finally {
        // Clean up the secondary app instance
        await secondaryApp.delete();
      }

      if (credential == null || credential.user == null) {
        throw Exception("Failed to create user account");
      }

      // Fetch location
      final locData = await LocationService.fetchIpAndLocation();

      // 2. Save the staff member to the 'employees' collection using the MAIN app instance
      final employee = EmployeeModel(
        id: credential.user!.uid,
        ownerId: owner.uid,
        businessId: _selectedBusinessId!,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
        salary: _salaryController.text.trim(),
        ip: locData['ip'] ?? 'Unknown',
        location: locData['location'] ?? 'Unknown',
        isActive: true,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('employees')
          .doc(employee.id)
          .set(employee.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff member added successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Authentication error'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding staff: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = FirebaseAuth.instance.currentUser;
    final primaryColor = Theme.of(context).appBarTheme.backgroundColor ?? Colors.blue.shade500;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Add Staff Member', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.only(bottom: 30, top: 10),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  'New Staff Details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Business Selection
                        if (owner != null)
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('businesses')
                                .where('owner_id', isEqualTo: owner.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }
                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return const Text(
                                  'You need to create a business first before adding staff.',
                                  style: TextStyle(color: Colors.red),
                                );
                              }
                              return DropdownButtonFormField<String>(
                                value: _selectedBusinessId,
                                decoration: InputDecoration(
                                  labelText: 'Assign to Business',
                                  prefixIcon: Icon(Icons.storefront, color: Colors.blue.shade300),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: docs.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return DropdownMenuItem<String>(
                                    value: doc.id,
                                    child: Text(data['name'] ?? 'Unknown'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedBusinessId = val);
                                },
                                validator: (v) => v == null ? 'Select a business' : null,
                              );
                            },
                          ),
                        const SizedBox(height: 16),

                        // Role Selection
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Role',
                            prefixIcon: Icon(Icons.badge, color: Colors.blue.shade300),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: ['Employee', 'Cashier', 'Manager'].map((role) {
                            return DropdownMenuItem<String>(value: role, child: Text(role));
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedRole = val!);
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person,
                          action: TextInputAction.next,
                          validator: (v) => v!.trim().isEmpty ? 'Enter full name' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          action: TextInputAction.next,
                          validator: (v) {
                            if (v!.trim().isEmpty) return 'Enter email';
                            if (!v.contains('@')) return 'Enter valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock, color: Colors.blue.shade300),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          action: TextInputAction.next,
                          validator: (v) => v!.trim().isEmpty ? 'Enter phone number' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _salaryController,
                          label: 'Salary (Monthly/Hourly)',
                          icon: Icons.monetization_on,
                          keyboardType: TextInputType.number,
                          action: TextInputAction.done,
                          validator: (v) => v!.trim().isEmpty ? 'Enter salary' : null,
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveStaff,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Add Staff', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? action,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: action,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade300),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
