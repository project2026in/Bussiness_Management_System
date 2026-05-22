import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_staff.dart';

class StaffView extends StatefulWidget {
  const StaffView({super.key});

  @override
  State<StaffView> createState() => _StaffViewState();
}

class _StaffViewState extends State<StaffView> {
  String? _selectedBusinessId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStaffScreen()),
          );
        },
        tooltip: 'Add Staff Member',
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Businesses Section (Horizontal List)
              _buildBusinessesSection(user.uid),

              const Divider(height: 1, thickness: 1),

              // 2. Filtered Employees (Selected Business)
              if (_selectedBusinessId != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
                  child: Text(
                    'Employees for Selected Business',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                ),
                _buildEmployeeList(user.uid, businessId: _selectedBusinessId),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(height: 32, thickness: 1),
                ),
              ],

              // 3. All Employees Section
              Padding(
                padding: EdgeInsets.only(left: 16, top: _selectedBusinessId == null ? 24 : 8, bottom: 8),
                child: Text(
                  'All Employees',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ),
              _buildEmployeeList(user.uid),
              const SizedBox(height: 80), // Padding for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessesSection(String ownerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .where('owner_id', isEqualTo: ownerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        }
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No businesses found. Please add a business first.', style: TextStyle(color: Colors.grey)),
          );
        }

        return Container(
          height: 90,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unknown Business';
              final isSelected = _selectedBusinessId == doc.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedBusinessId == doc.id) {
                      _selectedBusinessId = null; // Toggle off
                    } else {
                      _selectedBusinessId = doc.id;
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Icon(
                        Icons.storefront, 
                        color: isSelected ? Colors.white : Colors.grey.shade600, 
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmployeeList(String ownerId, {String? businessId}) {
    Query query = FirebaseFirestore.instance
        .collection('employees')
        .where('owner_id', isEqualTo: ownerId);
    
    if (businessId != null) {
      query = query.where('business_id', isEqualTo: businessId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32), 
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16), 
            child: Text('Error loading staff.', style: TextStyle(color: Colors.red)),
          );
        }

        var docs = snapshot.data?.docs.toList() ?? [];

        // Sort by created_at descending
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTimeStr = aData['created_at']?.toString() ?? '';
          final bTimeStr = bData['created_at']?.toString() ?? '';
          return bTimeStr.compareTo(aTimeStr);
        });

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Center(
              child: Text(
                businessId == null 
                    ? 'No staff members found.\nTap the + button to add one!' 
                    : 'No staff assigned to this business.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unknown';
            final email = data['email'] ?? 'No email';
            final role = data['role'] ?? 'Employee';
            final isActive = data['is_active'] ?? true;
            final empBusinessId = data['business_id'] ?? '';

            final statusColor = isActive ? Colors.green : Colors.red;
            final roleColor = role == 'Manager' ? Colors.purple : Colors.blue;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: roleColor.withValues(alpha: 0.1),
                  radius: 28,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(email, style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<DocumentSnapshot>(
                      future: empBusinessId.isNotEmpty
                          ? FirebaseFirestore.instance.collection('businesses').doc(empBusinessId).get()
                          : null,
                      builder: (context, busSnap) {
                        String busName = 'Unknown Business';
                        if (busSnap.hasData && busSnap.data!.exists) {
                          busName = (busSnap.data!.data() as Map<String, dynamic>)['name'] ?? busName;
                        }
                        return Row(
                          children: [
                            Icon(Icons.storefront, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                busName,
                                style: TextStyle(color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (val) async {
                    if (val == 'toggle_status') {
                      await FirebaseFirestore.instance
                          .collection('employees')
                          .doc(docs[index].id)
                          .update({'is_active': !isActive});
                    } else if (val == 'delete') {
                      await FirebaseFirestore.instance
                          .collection('employees')
                          .doc(docs[index].id)
                          .delete();
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
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
