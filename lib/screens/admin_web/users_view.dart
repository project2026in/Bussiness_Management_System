import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/web_download.dart';

class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Owner Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View and manage all registered owners in the system.',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _downloadJson(context),
                icon: const Icon(Icons.download_for_offline, size: 18),
                label: const Text('Download JSON'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0D47A1),
                  backgroundColor: Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Users Table/List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading users.\nCheck your Firebase Security Rules.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No users found in the database.'),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                        columns: const [
                          DataColumn(label: Text('Avatar', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Unknown User';
                          final email = data['email'] ?? 'No email provided';
                          final phone = data['phone'] ?? 'N/A';
                          final role = data['role'] ?? 'User';
                          final photoUrl = data['photoURL'];
                          final ip = data['ip'] ?? 'N/A';
                          final location = data['location'] ?? 'N/A';
                          final createdAt = data['createdAt'] != null
                              ? (data['createdAt'] as Timestamp).toDate().toString().split(' ')[0]
                              : 'Unknown';
                          final isActive = data['isActive'] ?? true;
                          final statusColor = isActive ? Colors.green : Colors.red;
                          final statusText = isActive ? 'Active' : 'Inactive';

                          return DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>((states) => 
                                isActive ? Colors.green.shade50 : Colors.red.shade50),
                            cells: [
                              DataCell(
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                                  backgroundImage: photoUrl != null && photoUrl.toString().isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl == null || photoUrl.toString().isEmpty
                                      ? Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                              color: Color(0xFF0D47A1), fontWeight: FontWeight.bold, fontSize: 12),
                                        )
                                      : null,
                                ),
                              ),
                              DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(email)),
                              DataCell(Text(phone)),
                              DataCell(Text(role)),
                              DataCell(Text(createdAt)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      _showEditUserDialog(context, doc.id, data);
                                    } else if (value == 'toggle_status') {
                                      await FirebaseFirestore.instance.collection('users').doc(doc.id).update({
                                        'isActive': !isActive,
                                      });
                                    } else if (value == 'delete') {
                                      _showDeleteUserDialog(context, doc.id);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle_status',
                                      child: Row(
                                        children: [
                                          Icon(isActive ? Icons.block : Icons.check_circle, size: 18),
                                          const SizedBox(width: 8),
                                          Text(isActive ? 'Deactivate' : 'Activate'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user? This action cannot be undone and will revoke their access to the system.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(docId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final phoneController = TextEditingController(text: data['phone']);
    String selectedRole = data['role'] ?? 'User';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit User'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: ['Owner', 'Manager', 'Employee', 'Superadmin', 'User'].contains(selectedRole) ? selectedRole : 'User',
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: ['Owner', 'Manager', 'Employee', 'Superadmin', 'User']
                          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedRole = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('users').doc(docId).update({
                      'phone': phoneController.text.trim(),
                      'role': selectedRole,
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _downloadJson(BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final List<Map<String, dynamic>> jsonList = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data.forEach((key, value) {
          if (value is Timestamp) {
            data[key] = value.toDate().toIso8601String();
          }
        });
        jsonList.add(data);
      }
      final jsonString = jsonEncode(jsonList);
      downloadJsonFile(jsonString, 'users.json');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloaded users.json')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading JSON: $e')));
      }
    }
  }
}
