import 'package:flutter/material.dart';
import 'package:bussiness_management/screens/logins/login_screen.dart';
import 'user_registration.dart';


class WhoAmIView extends StatelessWidget {
  const WhoAmIView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(
            top: 150, bottom: 12, left: 24, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Who Am I?',
              style: TextStyle(
                fontSize: 28,
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your role to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            _RoleCard(
              icon: Icons.business_center_rounded,
              title: 'Owner',
              subtitle: 'Owner of the business',
              color: Color(0xFF0D47A1),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginView(role: 'Owner'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _RoleCard(
              icon: Icons.manage_accounts_rounded,
              title: 'Manager',
              subtitle: 'Manager of the business',
              color: Color(0xFF0D47A1),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginView(role: 'Manager'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _RoleCard(
              icon: Icons.badge_rounded,
              title: 'Employee',
              subtitle: 'Employee of the business',
              color: Color(0xFF0D47A1),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginView(role: 'Employee'),
                ),
              ),
            ),

            const Spacer(), // pushes register link to bottom

            // ── Register Link ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'New user?',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterView(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: const Text(
                    'Register now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── _RoleCard (unchanged) ────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
