import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/formatters.dart';

class EditStaffScreen extends StatefulWidget {
  final String staffId;
  final Map<String, dynamic> staffData;

  const EditStaffScreen({super.key, required this.staffId, required this.staffData});

  @override
  State<EditStaffScreen> createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _salaryController;
  
  String _selectedRole = 'Employee';
  String? _selectedBusinessId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staffData['name']);
    _phoneController = TextEditingController(text: widget.staffData['phone']);
    _salaryController = TextEditingController(text: widget.staffData['salary']);
    _selectedRole = widget.staffData['role'] ?? 'Employee';
    _selectedBusinessId = widget.staffData['business_id'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _updateStaff() async {
    if (!_formKey.currentState!.validate() || _selectedBusinessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a business')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.staffId).update({
        'name': Formatters.capitalizeWords(_nameController.text),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'salary': _salaryController.text.trim(),
        'business_id': _selectedBusinessId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff details updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating staff: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Edit Staff Details', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
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
                    child: const Icon(Icons.edit_document, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Update Information',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            Padding(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assign Business', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('businesses')
                              .where('owner_id', isEqualTo: owner?.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const LinearProgressIndicator();
                            final businesses = snapshot.data!.docs;

                            if (businesses.isEmpty) {
                              return const Text('No businesses found. Please create a business first.', style: TextStyle(color: Colors.red));
                            }

                            // Check if selected business still exists, else reset
                            if (_selectedBusinessId != null && !businesses.any((b) => b.id == _selectedBusinessId)) {
                              _selectedBusinessId = null;
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: const Text('Select Business'),
                                  value: _selectedBusinessId,
                                  items: businesses.map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    return DropdownMenuItem<String>(
                                      value: doc.id,
                                      child: Text(data['name'] ?? 'Unknown'),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedBusinessId = val;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        const Text('Assign Role', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedRole,
                              items: ['Manager', 'Cashier', 'Employee']
                                  .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedRole = val!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          action: TextInputAction.next,
                          validator: (v) => v!.trim().isEmpty ? 'Enter full name' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          action: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _salaryController,
                          label: 'Salary Amount',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                          action: TextInputAction.done,
                          validator: (v) => v!.trim().isEmpty ? 'Enter salary' : null,
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateStaff,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Update Staff', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
