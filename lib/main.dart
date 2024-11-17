import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core
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
      title: 'Firebase Check',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FirebaseStatusPage(errorMessage: errorMessage),
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
        title: const Text('Firebase Status'),
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
