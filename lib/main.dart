import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core
import 'package:location/location.dart'; // Import location package
import 'login_register.dart'; // Import the login_register.dart file

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter binding is initialized before Firebase
  try {
    await Firebase.initializeApp(); // Initialize Firebase
    runApp(const MyApp()); // Run the app if Firebase initialization is successful
  } catch (e) {
    runApp(MyApp(errorMessage: e.toString())); // Show error message if initialization fails
  }
}

class MyApp extends StatelessWidget {
  final String? errorMessage;

  const MyApp({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Tracking Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LocationMonitor(
        child: FirebaseStatusPage(errorMessage: errorMessage),
      ),
    );
  }
}

class FirebaseStatusPage extends StatelessWidget {
  final String? errorMessage;

  const FirebaseStatusPage({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Tracking Application'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            if (errorMessage != null) {
              // If error message exists, show the error
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Error'),
                  content: Text('No it isn\'t, here is the error: $errorMessage'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            } else {
              // If no error, Firebase is working
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Success'),
                  content: const Text('Yes, it\'s working!'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        // Navigate to LoginRegister page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginRegister(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }
          },
          child: const Text('Check Firebase Status'),
        ),
      ),
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

  // Check if location services are enabled
  Future<bool> _isLocationEnabled() async {
    return await _location.serviceEnabled();
  }

  // Request location services to be turned on
  Future<bool> _enableLocationService() async {
    return await _location.requestService();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register observer
    _monitorLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _monitorLocation(); // Recheck location when app is resumed
    }
  }

  // Monitor location services and show dialog if turned off
  void _monitorLocation() async {
    bool serviceEnabled = await _isLocationEnabled();

    if (!serviceEnabled) {
      _showLocationDialog();
    }
  }

  // Show dialog to prompt user to enable location services
  void _showLocationDialog() {
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
                  Navigator.pop(context); // Dismiss dialog if location is enabled
                } else {
                  // Keep the dialog open if the service is still disabled
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
  Widget build(BuildContext context) {
    return widget.child; // Display the child widget (whole app)
  }
}
