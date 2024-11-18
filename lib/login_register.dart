import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';  // Import local_auth
import 'home_page.dart'; // Import the HomePage widget
import 'admin_dashboard.dart'; // Import AdminDashboard widget

class LoginRegister extends StatefulWidget {
  const LoginRegister({super.key});

  @override
  _LoginRegisterState createState() => _LoginRegisterState();
}

class _LoginRegisterState extends State<LoginRegister> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final LocalAuthentication _localAuth = LocalAuthentication();  // Create a LocalAuthentication instance

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isRegistering = false;

  // Handle email/password sign-in or registration
  Future<void> _emailSignIn() async {
    try {
      if (_isRegistering) {
        // Registration logic
        if (_emailController.text.trim() == "admin") {
          // Skip email validation for "admin" user
          await _auth.createUserWithEmailAndPassword(
            email: "admin@admin.com", // Set a dummy valid email
            password: _passwordController.text.trim(),
          );
          _showSuccessDialog('Registration successful');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          await _auth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          _showSuccessDialog('Registration successful');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        // Login logic
        if (_emailController.text.trim() == "admin" &&
            _passwordController.text.trim() == "admin") {
          // Skip email validation for "admin"
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else {
          UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
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

  // Handle Google Sign-In
  Future<void> _googleSignInMethod() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
        _showSuccessDialog('Google Sign-In successful');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      _showErrorDialog('Google Sign-In failed: ' + e.toString());
    }
  }

  // Fingerprint authentication
  Future<void> _authenticateWithFingerprint() async {
    try {
      bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          useErrorDialogs: true, // Use error dialogs if authentication fails
          stickyAuth: true, // Keep authentication active until completed
        ),
      );
      if (isAuthenticated) {
        _showSuccessDialog('Fingerprint authentication successful');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        _showErrorDialog('Authentication failed');
      }
    } catch (e) {
      _showErrorDialog('Fingerprint authentication failed: ' + e.toString());
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
        title: const Text('Login/Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _googleSignInMethod,
              icon: const Icon(Icons.account_circle), // Simple Google icon
              label: const Text('Sign in with Google'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authenticateWithFingerprint,
              child: const Text('Login with Fingerprint'),
            ),
          ],
        ),
      ),
    );
  }
}
