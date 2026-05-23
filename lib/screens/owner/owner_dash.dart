import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_business.dart';
import 'staff_view.dart';
import 'home_dash_tab.dart';
import 'reports_tab.dart';
import 'business_details_screen.dart';
import 'owner_notifications_screen.dart';

class OwnerView extends StatefulWidget {
  const OwnerView({super.key});

  @override
  State<OwnerView> createState() => _OwnerViewState();
}

class _OwnerViewState extends State<OwnerView> {
  int _selectedIndex = 2;

  List<Widget> get _widgetOptions => <Widget>[
    const ReportsTab(),
    const StaffView(),
    HomeDashboardTab(onNavigate: _onItemTapped),
    const MyShopsScreen(),
    const OwnerProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data.containsKey('name')) {
            return data['name'];
          }
        }
      } catch (e) {
        // If there's an error fetching from Firestore, fallback below
      }
      return user.displayName ?? 'Owner';
    }
    return 'Owner';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
            builder: (context, userSnap) {
              final userData = userSnap.data?.data() as Map<String, dynamic>?;
              final lastRead = (userData?['last_read_notifications'] as Timestamp?)?.toDate() ?? DateTime(2000);

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('notifications').orderBy('timestamp', descending: true).limit(50).snapshots(),
                builder: (context, notifSnap) {
                  int unreadCount = 0;
                  final docs = notifSnap.data?.docs ?? [];
                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final audience = data['target_audience'] as String?;
                    if (audience == 'all' || audience == 'owners') {
                      final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                      if (timestamp.isAfter(lastRead)) {
                        unreadCount++;
                      }
                    }
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications),
                        tooltip: 'Notifications',
                        onPressed: () {
                          // Update last read time
                          FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).set({
                            'last_read_notifications': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OwnerNotificationsScreen()),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(30),
            right: Radius.circular(30),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get(),
              builder: (context, snapshot) {
                final user = FirebaseAuth.instance.currentUser;
                String name = user?.displayName ?? 'Owner';
                String email = user?.email ?? 'No email';
                
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  name = data['name'] ?? name;
                  email = data['email'] ?? email;
                }

                return Theme(
                  data: Theme.of(context).copyWith(
                    dividerTheme: const DividerThemeData(color: Colors.transparent),
                    dividerColor: Colors.transparent,
                  ),
                  child: DrawerHeader(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: const BoxDecoration(
                    color: Color(0xFF0D47A1),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 28, color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(email, style: TextStyle(color: Colors.blue.shade100, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),
                );
              }
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                leading: const Icon(Icons.storefront),
                title: const Text('My Shops', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  _onItemTapped(3);
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                leading: const Icon(Icons.analytics),
                title: const Text('Reports'),
                selected: _selectedIndex == 0,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(0);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                leading: const Icon(Icons.people),
                title: const Text('Staff'),
                selected: _selectedIndex == 1,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(1);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                selected: _selectedIndex == 2,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(2);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                leading: const Icon(Icons.store),
                title: const Text('My Shops'),
                selected: _selectedIndex == 3,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(3);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                selected: _selectedIndex == 4,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(4);
                },
              ),
            ),
          ],
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            selectedItemColor: const Color(0xFF0D47A1),
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 0 ? Icons.analytics : Icons.analytics_outlined),
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 1 ? Icons.people : Icons.people_outline),
                label: 'Staff',
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 2 ? Icons.home : Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 3 ? Icons.store : Icons.store_outlined),
                label: 'Shops',
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 4 ? Icons.person : Icons.person_outline),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}

class MyShopsScreen extends StatelessWidget {
  const MyShopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBusinessScreen()),
          );
        },
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business),
        label: const Text('Add Business', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('businesses')
            .where('owner_id', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading businesses: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade400),
              ),
            );
          }

          var docs = snapshot.data?.docs.toList() ?? [];
          
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTimeStr = aData['created_at']?.toString() ?? '';
            final bTimeStr = bData['created_at']?.toString() ?? '';
            return bTimeStr.compareTo(aTimeStr);
          });

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 180.0,
                pinned: true,
                automaticallyImplyLeading: false, // Don't show back button
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const ContinuousRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(60),
                    bottomRight: Radius.circular(60),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${docs.length} Active ${docs.length == 1 ? 'Shop' : 'Shops'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'My Businesses',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage and track your entire portfolio',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (docs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(Icons.storefront, size: 64, color: Colors.grey.shade300),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No businesses yet',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button below to add your first shop!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final name = data['name'] ?? 'Unknown Business';
                        final city = data['city'] ?? 'Unknown City';
                        final country = data['country'] ?? '';
                        final phone = data['phone'] ?? 'No phone';
                        final isActive = data['is_active'] ?? true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BusinessDetailsScreen(
                                      businessId: docs[index].id,
                                      businessName: name,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.storefront,
                                              size: 32,
                                              color: Color(0xFF0D47A1),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: -0.5,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(Icons.location_on_rounded, size: 14, color: Colors.blue.shade700),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '$city${country.isNotEmpty ? ', $country' : ''}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey.shade600,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF0D47A1)),
                                        ),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Divider(height: 1),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade500),
                                            const SizedBox(width: 6),
                                            Text(
                                              phone,
                                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.circle, size: 8, color: isActive ? Colors.green.shade500 : Colors.red.shade500),
                                              const SizedBox(width: 6),
                                              Text(
                                                isActive ? 'Active' : 'Inactive',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class OwnerProfileTab extends StatelessWidget {
  const OwnerProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        String name = user.displayName ?? 'Owner';
        String email = user.email ?? 'No email';
        String phone = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? name;
          email = data['email'] ?? email;
          phone = data['phone'] ?? phone;
        }

        return Column(
          children: [
            // Top Section (Primary Color)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 40, bottom: 48, left: 24, right: 24),
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
                      child: Icon(Icons.person, size: 160, color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue.shade100,
                                ),
                              ),
                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  phone,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Options Section
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF0D47A1).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Color(0xFF0D47A1)),
                    ),
                    title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit Profile coming soon!')),
                      );
                    },
                  ),
                  const Divider(indent: 72),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF0D47A1).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, color: Color(0xFF0D47A1)),
                    ),
                    title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const _ChangePasswordDialog(),
                      );
                    },
                  ),
                  const Divider(indent: 72),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout, color: Colors.red),
                    ),
                    title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate
        final cred = EmailAuthProvider.credential(
            email: user.email!, password: _currentPasswordController.text);
        await user.reauthenticateWithCredential(cred);
        
        // Update password
        await user.updatePassword(_newPasswordController.text);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error changing password'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Enter current password' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureNew,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
                validator: (v) {
                  if (v != _newPasswordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Update'),
        ),
      ],
    );
  }
}
