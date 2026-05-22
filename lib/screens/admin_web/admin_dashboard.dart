import 'package:flutter/material.dart';
import 'users_view.dart'; // Re-using the users list we built
import 'all_users_view.dart';
import 'businesses_view.dart';
import 'employees_view.dart';
import 'settings_view.dart';
import 'reports_view.dart';
import 'notifications_view.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminUsersView(),
    const AllUsersLocationView(),
    const AdminBusinessesView(),
    const AdminEmployeesView(),
    const AdminReportsView(),
    const AdminNotificationsView(),
    const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          // Left Sidebar (Navigation)
          Container(
            width: 260,
            color: Colors.white,
            child: _buildSidebar(),
          ),
          
          VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade300),
          
          // Right Main Content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        // Sidebar Header
        Container(
          height: 120,
          width: double.infinity,
          color: const Color(0xFF0D47A1),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(24),
          child: const Text(
            'SUPERADMIN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Navigation Items
        _buildSidebarItem(icon: Icons.people_alt, title: 'Owners', index: 0),
        _buildSidebarItem(icon: Icons.public, title: 'All Users', index: 1),
        _buildSidebarItem(icon: Icons.business, title: 'Business', index: 2),
        _buildSidebarItem(icon: Icons.badge, title: 'Employees', index: 3),
        _buildSidebarItem(icon: Icons.analytics, title: 'Reports', index: 4),
        _buildSidebarItem(icon: Icons.notifications_active, title: 'Broadcasts', index: 5),
        _buildSidebarItem(icon: Icons.settings, title: 'Settings', index: 6),
        
        const Spacer(),
        
        // Logout Button
        const Divider(),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          title: const Text(
            'Log Out',
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            // Navigate back to Admin Login without Firebase Auth (since it's hardcoded)
            Navigator.pushReplacementNamed(context, '/admin_login');
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0D47A1).withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade600,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0D47A1) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// A simple placeholder widget for tabs that aren't built yet
class _PlaceholderView extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderView({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '$title\n(Coming Soon)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
