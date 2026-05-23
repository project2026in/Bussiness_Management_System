import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_staff.dart';
import 'edit_staff.dart';

class StaffView extends StatefulWidget {
  const StaffView({super.key});

  @override
  State<StaffView> createState() => _StaffViewState();
}

class _StaffViewState extends State<StaffView> {
  String? _selectedBusinessId;
  String _selectedRole = 'All';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStaffScreen()),
          );
        },
        tooltip: 'Add Staff Member',
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: Container(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -20,
                    top: -40,
                    child: Icon(Icons.people_alt, size: 160, color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people_alt, color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          const Text(
                            'Team & Staff',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('owner_id', isEqualTo: user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox();
                          }
                          final count = snapshot.data!.docs.length;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.groups, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '$count Total Employees',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [

          // Business Filter Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 24, top: 24, bottom: 8),
                  child: Text(
                    'Filter by Business',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ),
                _buildBusinessesSection(user.uid),
              ],
            ),
          ),

          // Role Filter Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 24, top: 8, bottom: 8),
                  child: Text(
                    'Filter by Role',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ),
                _buildRoleFilter(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Employees Content
          if (_selectedBusinessId != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, top: 24, bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.storefront, size: 20, color: Color(0xFF0D47A1)),
                    const SizedBox(width: 8),
                    Text(
                      'Filtered Roster',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade800),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildEmployeeList(user.uid, businessId: _selectedBusinessId),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Divider(height: 32, color: Colors.grey.shade300),
              ),
            ),
          ],

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 24, top: _selectedBusinessId == null ? 16 : 8, bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.groups, size: 20, color: Color(0xFF0D47A1)),
                  const SizedBox(width: 8),
                  Text(
                    'Complete Roster',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade800),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildEmployeeList(user.uid),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
          ),
        ],
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
          height: 110,
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                  width: 140,
                  margin: const EdgeInsets.only(right: 12, bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade200,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? const Color(0xFF0D47A1).withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.storefront, 
                          color: isSelected ? Colors.white : const Color(0xFF0D47A1), 
                          size: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.blueGrey.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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

  Widget _buildRoleFilter() {
    final roles = ['All', 'Manager', 'Cashier', 'Employee'];
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: roles.length,
        itemBuilder: (context, index) {
          final role = roles[index];
          final isSelected = _selectedRole == role;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedRole = role;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                role,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.blueGrey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeList(String ownerId, {String? businessId}) {
    Query query = FirebaseFirestore.instance
        .collection('users')
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

        if (_selectedRole != 'All') {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['role'] ?? 'Employee') == _selectedRole;
          }).toList();
        }

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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unknown';
            final email = data['email'] ?? 'No email';
            final role = data['role'] ?? 'Employee';
            final isActive = data['is_active'] ?? true;
            final empBusinessId = data['business_id'] ?? '';

            final statusColor = isActive ? Colors.green : Colors.red;
            final roleColor = role == 'Manager' 
                ? const Color(0xFF8B5CF6) 
                : role == 'Cashier' 
                    ? const Color(0xFF10B981) // Emerald Green
                    : const Color(0xFF3B82F6); // Blue

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditStaffScreen(
                          staffId: docs[index].id,
                          staffData: data,
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: roleColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: roleColor,
                      radius: 28,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name, 
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 6),
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
                              Icon(Icons.storefront, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  busName,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (val) async {
                      if (val == 'toggle_status') {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(docs[index].id)
                            .update({'is_active': !isActive});
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle_status',
                        child: Row(
                          children: [
                            Icon(isActive ? Icons.block : Icons.check_circle, size: 18, color: isActive ? Colors.orange : Colors.green),
                            const SizedBox(width: 12),
                            Text(isActive ? 'Suspend Staff' : 'Activate Staff', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      ],
                  ),
                ),
              ),
            ),
          );
        },
        );
      },
    );
  }
}
