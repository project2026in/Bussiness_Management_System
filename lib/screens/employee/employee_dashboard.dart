import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'daily_report_screen.dart';
import 'report_history_screen.dart';

class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Employee Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) async {
              if (value == 'change_password') {
                _showChangePasswordDialog(context);
              } else if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Change Password'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not authenticated.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('employees').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading profile data.', style: TextStyle(color: Colors.red)));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Profile not found in database.'));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final name = data['name'] ?? 'Unknown';
                final email = data['email'] ?? 'No email';
                final phone = data['phone'] ?? 'No phone';
                final role = data['role'] ?? 'Employee';
                final businessId = data['business_id'] ?? '';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Header
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Profile Details Card
                      Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Profile',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                              const Divider(height: 32),
                              
                              _buildProfileItem(Icons.person, 'Full Name', name),
                              const SizedBox(height: 16),
                              
                              _buildProfileItem(Icons.email, 'Email Address', email),
                              const SizedBox(height: 16),
                              
                              _buildProfileItem(Icons.phone, 'Phone Number', phone),
                              const SizedBox(height: 16),

                              // Fetch business name
                              FutureBuilder<DocumentSnapshot>(
                                future: businessId.isNotEmpty 
                                  ? FirebaseFirestore.instance.collection('businesses').doc(businessId).get() 
                                  : null,
                                builder: (context, busSnap) {
                                  String busName = 'Loading...';
                                  if (busSnap.connectionState == ConnectionState.done) {
                                    if (busSnap.hasData && busSnap.data!.exists) {
                                      busName = (busSnap.data!.data() as Map<String, dynamic>)['name'] ?? 'Unknown Business';
                                    } else {
                                      busName = 'Unassigned';
                                    }
                                  }
                                  return _buildProfileItem(Icons.storefront, 'Assigned Business', busName);
                                }
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Cashier Specific Actions
                      if (role == 'Cashier') ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade600, Colors.teal.shade500],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                if (businessId.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Error: You must be assigned to a business first!')),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DailyReportScreen(
                                      businessId: businessId,
                                      cashierId: user.uid,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(width: 20),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Submit Daily Report',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Log your daily sales and expenses.',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Your Report History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('daily_reports')
                              .where('cashier_id', isEqualTo: user.uid)
                              .snapshots(),
                          builder: (context, reportSnap) {
                            if (reportSnap.connectionState == ConnectionState.waiting) {
                              return const Center(child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ));
                            }
                            if (reportSnap.hasError) {
                              return const Text('Error loading history.', style: TextStyle(color: Colors.red));
                            }
                            if (!reportSnap.hasData || reportSnap.data!.docs.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'No daily reports submitted yet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                ),
                              );
                            }

                            // Sort documents locally to bypass Firestore missing index error
                            final docs = reportSnap.data!.docs.toList();
                            docs.sort((a, b) {
                              final dataA = a.data() as Map<String, dynamic>;
                              final dataB = b.data() as Map<String, dynamic>;
                              final dateA = (dataA['date'] as Timestamp?)?.toDate() ?? DateTime(2000);
                              final dateB = (dataB['date'] as Timestamp?)?.toDate() ?? DateTime(2000);
                              return dateB.compareTo(dateA); // Descending order
                            });
                            final displayDocs = docs.take(2).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: displayDocs.length,
                                  itemBuilder: (context, index) {
                                    final report = displayDocs[index].data() as Map<String, dynamic>;
                                final date = (report['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                                final dateStr = DateFormat('MMM d, yyyy').format(date);
                                
                                final income = (report['sale'] as num?)?.toDouble() ?? 0.0;
                                final purchase = (report['purchase'] as num?)?.toDouble() ?? 0.0;
                                final expense = (report['expense'] as num?)?.toDouble() ?? 0.0;
                                final salary = (report['salary'] as num?)?.toDouble() ?? 0.0;
                                final other = (report['other_expense'] as num?)?.toDouble() ?? 0.0;
                                final totalExpense = purchase + expense + salary + other;
                                final profit = income - totalExpense;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: profit >= 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                      child: Icon(
                                        profit >= 0 ? Icons.trending_up : Icons.trending_down,
                                        color: profit >= 0 ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Inc: \$${income.toStringAsFixed(0)} | Exp: \$${totalExpense.toStringAsFixed(0)}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${profit.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: profit >= 0 ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        Text(
                                          'Profit',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReportHistoryScreen(cashierId: user.uid),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.history),
                                label: const Text('View All History'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF0D47A1),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.grey.shade600, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter a new password for your account. Minimum 6 characters.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (passwordController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password must be at least 6 characters')),
                            );
                            return;
                          }
                          setState(() => isLoading = true);
                          try {
                            await FirebaseAuth.instance.currentUser?.updatePassword(passwordController.text);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message ?? 'Error updating password'), backgroundColor: Colors.red),
                              );
                            }
                            setState(() => isLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
