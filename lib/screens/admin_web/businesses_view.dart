import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBusinessesView extends StatelessWidget {
  const AdminBusinessesView({super.key});

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
            'Business Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage all registered businesses in the system.',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          // Businesses Table/List
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
                    .collection('businesses')
                    // Removed orderBy('createdAt') to prevent filtering out businesses without timestamp
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading businesses.\nCheck your Firebase Security Rules.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No businesses found in the database.'),
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
                          DataColumn(label: Text('Owner Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('City', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Country', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Unknown Business';
                          final ownerId = data['ownerId'];
                          final email = data['email'] ?? 'No email';
                          final phone = data['phone'] ?? 'N/A';
                          final address = data['address'] ?? 'N/A';
                          final city = data['city'] ?? 'Unknown City';
                          final country = data['country'] ?? 'Unknown Country';
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
                              DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(
                                ownerId != null
                                    ? FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
                                        builder: (context, userSnap) {
                                          if (userSnap.connectionState == ConnectionState.waiting) return const Text('Loading...');
                                          if (userSnap.hasData && userSnap.data!.exists) {
                                            final userData = userSnap.data!.data() as Map<String, dynamic>?;
                                            return Text(userData?['name'] ?? 'Unknown');
                                          }
                                          return const Text('Unknown');
                                        },
                                      )
                                    : const Text('No Owner'),
                              ),
                              DataCell(Text(email)),
                              DataCell(Text(phone)),
                              DataCell(Text(address)),
                              DataCell(Text(city)),
                              DataCell(Text(country)),
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
                                      _showEditBusinessDialog(context, doc.id, data);
                                    } else if (value == 'toggle_status') {
                                      await FirebaseFirestore.instance.collection('businesses').doc(doc.id).update({
                                        'isActive': !isActive,
                                      });
                                    } else if (value == 'delete') {
                                      _showDeleteBusinessDialog(context, doc.id);
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

  void _showDeleteBusinessDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Business'),
        content: const Text('Are you sure you want to delete this business? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('businesses').doc(docId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditBusinessDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name']);
    final emailController = TextEditingController(text: data['email']);
    final phoneController = TextEditingController(text: data['phone']);
    final addressController = TextEditingController(text: data['address']);
    final cityController = TextEditingController(text: data['city']);
    final countryController = TextEditingController(text: data['country']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Business'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City')),
              TextField(controller: countryController, decoration: const InputDecoration(labelText: 'Country')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('businesses').doc(docId).update({
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
                'address': addressController.text.trim(),
                'city': cityController.text.trim(),
                'country': countryController.text.trim(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
