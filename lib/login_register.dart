import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart'; // Import the HomePage widget
import 'admin_dashboard.dart'; // Import AdminDashboard widget

class LoginRegister extends StatefulWidget {
  const LoginRegister({super.key});

  @override
  _LoginRegisterState createState() => _LoginRegisterState();
}

class _LoginRegisterState extends State<LoginRegister> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isRegistering = false;

  // Handle email/password sign-in or registration
  Future<void> _emailSignIn() async {
    try {
      String enteredEmail = _emailController.text.trim();

      // Check if the entered email is "admin", and automatically append "@admin.com"
      if (enteredEmail == "admin") {
        enteredEmail = "admin@admin.com";
      } else {
        enteredEmail +=
            "@gmail.com"; // You can change this to other domain if needed
      }

      if (_isRegistering) {
        // Registration logic
        await _auth.createUserWithEmailAndPassword(
          email: enteredEmail,
          password: _passwordController.text.trim(),
        );
        _showSuccessDialog('Registration successful');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // Login logic
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: enteredEmail,
          password: _passwordController.text.trim(),
        );

        // Check if the user is admin after login
        if (enteredEmail == "admin@admin.com") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else {
          _showSuccessDialog('Login successful');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Failed: ' + e.toString());
    }
  }

  // Show success dialog
  void _showSuccessDialog(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  // Toggle between login and register
  void _toggleForm() {
    setState(() {
      _isRegistering = !_isRegistering;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
  alignment: Alignment.topCenter, // Aligns the box to the top center
  child: ClipRRect(
    borderRadius: BorderRadius.circular(20), // Adjust the curvature as needed
    child: Container(
      height: 150, // Height of the rectangle
      width: 200, // Width of the rectangle
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/icon/icon.png'),
          fit: BoxFit.cover, // Ensures the image covers the rectangle
        ),
      ),
    ),
  ),
),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: _emailSignIn,
              child: Text(_isRegistering ? 'Register' : 'Login'),
            ),
            TextButton(
              onPressed: _toggleForm,
              child: Text(_isRegistering
                  ? 'Already have an account? Login'
                  : 'Don’t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
