import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEmployeesView extends StatelessWidget {
  const AdminEmployeesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Employee Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage all staff members across businesses.',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          // Employees Table
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
                stream: FirebaseFirestore.instance.collection('employees').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading employees.\nCheck your Firebase Security Rules.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No employees found in the database.'),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                        columns: const [
                          DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Business', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Salary', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Unknown';
                          final role = data['role'] ?? 'Employee';
                          final email = data['email'] ?? 'No email';
                          final phone = data['phone'] ?? 'N/A';
                          final salary = data['salary'] ?? 'N/A';
                          final ip = data['ip'] ?? 'N/A';
                          final location = data['location'] ?? 'N/A';
                          final ownerId = data['owner_id'];
                          final businessId = data['business_id'];
                          final createdAtData = data['created_at'];
                          String createdAt = 'Unknown';
                          if (createdAtData != null) {
                            if (createdAtData is Timestamp) {
                              createdAt = createdAtData.toDate().toString().split(' ')[0];
                            } else {
                              createdAt = DateTime.tryParse(createdAtData.toString())?.toString().split(' ')[0] ?? 'Unknown';
                            }
                          }
                          final isActive = data['is_active'] ?? true;
                          final statusColor = isActive ? Colors.green : Colors.red;
                          final statusText = isActive ? 'Active' : 'Inactive';

                          return DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>((states) => 
                                isActive ? Colors.green.shade50 : Colors.red.shade50),
                            cells: [
                              DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(role)),
                              DataCell(
                                businessId != null
                                    ? FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance.collection('businesses').doc(businessId).get(),
                                        builder: (context, snap) {
                                          if (snap.connectionState == ConnectionState.waiting) return const Text('Loading...');
                                          if (snap.hasData && snap.data!.exists) {
                                            return Text((snap.data!.data() as Map<String, dynamic>)['name'] ?? 'Unknown');
                                          }
                                          return const Text('Unknown');
                                        },
                                      )
                                    : const Text('N/A'),
                              ),
                              DataCell(
                                ownerId != null
                                    ? FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
                                        builder: (context, snap) {
                                          if (snap.connectionState == ConnectionState.waiting) return const Text('Loading...');
                                          if (snap.hasData && snap.data!.exists) {
                                            return Text((snap.data!.data() as Map<String, dynamic>)['name'] ?? 'Unknown');
                                          }
                                          return const Text('Unknown');
                                        },
                                      )
                                    : const Text('N/A'),
                              ),
                              DataCell(Text(email)),
                              DataCell(Text(phone)),
                              DataCell(Text(salary)),
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
                                    if (value == 'toggle_status') {
                                      await FirebaseFirestore.instance.collection('employees').doc(doc.id).update({
                                        'is_active': !isActive,
                                      });
                                    } else if (value == 'delete') {
                                      _showDeleteDialog(context, doc.id);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'toggle_status',
                                      child: Row(
                                        children: [
                                          Icon(isActive ? Icons.block : Icons.check_circle, size: 18),
                                          const SizedBox(width: 8),
                                          Text(isActive ? 'Suspend' : 'Activate'),
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

  void _showDeleteDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: const Text('Are you sure you want to delete this employee? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('employees').doc(docId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
