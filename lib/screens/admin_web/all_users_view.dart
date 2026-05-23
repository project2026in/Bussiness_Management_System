import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllUsersLocationView extends StatefulWidget {
  const AllUsersLocationView({super.key});

  @override
  State<AllUsersLocationView> createState() => _AllUsersLocationViewState();
}

class _AllUsersLocationViewState extends State<AllUsersLocationView> {
  List<Map<String, dynamic>> _usersDocs = [];
  bool _loading = true;
  StreamSubscription? _usersSub;

  @override
  void initState() {
    super.initState();
    _usersSub = FirebaseFirestore.instance.collection('users').snapshots().listen((snap) {
      _usersDocs = snap.docs.map((d) {
        var data = d.data();
        data['uid'] = d.id;
        return data;
      }).toList();
      _updateList();
    });
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _allUsers = [];

  void _updateList() {
    _allUsers = List.from(_usersDocs);
    
    // Sort by name for consistency since createdAt formats might differ
    _allUsers.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

    if (mounted) setState(() => _loading = false);
  }

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
            'All Users (IP & Location)',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View tracking data for all users across the system (Owners, Managers, Employees, etc).',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          // Table
          Expanded(
            child: Container(
              width: double.infinity,
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
              child: _loading 
                ? const Center(child: CircularProgressIndicator())
                : _allUsers.isEmpty 
                  ? const Center(child: Text('No users found in the database.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                          columns: const [
                            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('IP Address', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _allUsers.map((data) {
                            final name = data['name'] ?? 'Unknown User';
                            final role = data['role'] ?? 'User';
                            final email = data['email'] ?? 'No email';
                            final ip = data['ip'] ?? 'Unknown';
                            final location = data['location'] ?? 'Unknown';

                            return DataRow(
                              cells: [
                                DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        color: Colors.blue.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(email)),
                                DataCell(Text(ip)),
                                DataCell(
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                                      const SizedBox(width: 4),
                                      Text(location),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

