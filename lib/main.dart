import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'login_register.dart';
import 'home_page.dart';
import 'admin_dashboard.dart'; // Make sure to create this file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
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

class LocationMonitor extends StatefulWidget {
  final Widget child;

  const LocationMonitor({Key? key, required this.child}) : super(key: key);

  @override
  _LocationMonitorState createState() => _LocationMonitorState();
}

class _LocationMonitorState extends State<LocationMonitor> with WidgetsBindingObserver {
  final Location _location = Location();

  Future<bool> _isLocationEnabled() async {
    return await _location.serviceEnabled();
  }

  Future<bool> _enableLocationService() async {
    return await _location.requestService();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _monitorLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _monitorLocation();
    }
  }

  void _monitorLocation() async {
    bool serviceEnabled = await _isLocationEnabled();

    if (!serviceEnabled) {
      _showLocationDialog();
    }
  }

  void _showLocationDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Location Service Off'),
          content: const Text('Location services are off. Please enable them.'),
          actions: [
            TextButton(
              onPressed: () async {
                bool serviceEnabled = await _enableLocationService();
                if (serviceEnabled) {
                  Navigator.pop(context);
                } else {
                  _showLocationDialog();
                }
              },
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}