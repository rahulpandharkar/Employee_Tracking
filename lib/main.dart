import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_register.dart';
import 'home_page.dart';
import 'admin_dashboard.dart'; // Make sure to create this file
import 'location_setting_monitor.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
  await Permission.locationWhenInUse.request(); 
  await Permission.locationAlways.request(); 
  await Permission.location.request(); 
  await Permission.notification.request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Tracking Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LocationMonitor(
        child: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String adminEmail = 'admin@admin.com';

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Check if the current user's email is admin@admin.com
          final User currentUser = snapshot.data!;
          if (currentUser.email?.toLowerCase() == adminEmail.toLowerCase()) {
            return const AdminDashboard();
          }
          return const HomePage();
        }
        return const LoginRegister();
      },
    );
  }
}