import 'package:bussiness_management/screens/startup/user_registration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/startup/splash_screen.dart';
import 'screens/startup/whoami_screen.dart';
import 'screens/owner/owner_dash.dart';
import 'screens/admin_web/admin_login.dart';
import 'screens/admin_web/admin_dashboard.dart';
import 'theme/app_theme.dart';
import 'screens/manager/manager_dashboard.dart';
import 'screens/employee/employee_dashboard.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My App',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => kIsWeb ? const AdminLoginScreen() : const SplashView(),
        '/home': (context) => const WhoAmIView(),
        '/register': (context) => const RegisterView(),
        '/owner_dash': (context) => const OwnerView(),
        '/admin_login': (context) => const AdminLoginScreen(),
        '/admin_dashboard': (context) => const SuperAdminDashboard(),
        '/manager_dash': (context) => const ManagerDashboard(),
        '/employee_dash': (context) => const EmployeeDashboard(),
      },
    );
  }
}
