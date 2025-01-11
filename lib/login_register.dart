import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart'; // Import the HomePage widget
import 'admin_dashboard.dart'; // Import AdminDashboard widget
import 'firestore_service.dart';

class LoginRegister extends StatefulWidget {
  const LoginRegister({super.key});

  @override
  _LoginRegisterState createState() => _LoginRegisterState();
}

class _LoginRegisterState extends State<LoginRegister> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  String? _phoneNumberError;
  String? _emailError;

  bool _isRegistering = false;

  // Handle email/password sign-in or registration
  Future<void> _emailSignIn() async {
    try {
      String enteredEmail = _emailController.text.trim();

      // Check if the entered email is "admin", and automatically append "@admin.com"
      if (enteredEmail == "admin") {
        enteredEmail = "admin@cnf.in";
      }
      if (_isRegistering) {
        // Registration logic
        await _auth.createUserWithEmailAndPassword(
          email: enteredEmail,
          password: _passwordController.text.trim(),
        );
        await _firestoreService.saveRegisteredData(
          _nameController.text.trim(),
          enteredEmail,
          _phoneController.text.trim(),
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
        if (enteredEmail == "admin@cnf.in") {
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
        title: const Text('Success', style: TextStyle(color: Color(0xFFE0AA3E))),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white, // Set text color to white
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFFE0AA3E), // Gold color for the button text
                fontWeight: FontWeight.bold, // Bold text
              ),
            ),
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
              child: const Text(
                'Close',
                style: TextStyle(
                    color: Color(0xFFE0AA3E)), // Consistent color styling
              ),
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

Future<void> reset() async {
  String enteredEmail = '';
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address to receive a password reset link.',
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) {
                enteredEmail = value.trim();
              },
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Color(0xFFE0AA3E)),
                hintText: 'example@domain.com',
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE0AA3E)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE0AA3E)),
                ),
              ),
              cursorColor: const Color(0xFFE0AA3E),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFE0AA3E)),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (enteredEmail.isEmpty) {
                _showErrorDialog('Please enter your email address.');
                return;
              }
              try {
                // Send the password reset email directly
                await _auth.sendPasswordResetEmail(email: enteredEmail);
                Navigator.pop(context); // Close the dialog
                _showSuccessDialog('Password reset email sent, would be only received if the user is registered on the system. Please check your inbox.');
              } catch (e) {
                Navigator.pop(context); // Close the dialog
                _showErrorDialog('Error: ${e.toString()}');
              }
            },
            child: const Text(
              'Send',
              style: TextStyle(color: Color(0xFFE0AA3E)),
            ),
          ),
        ],
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Adjust layout when the keyboard appears
      appBar: AppBar(
        title: const Text(
          'Welcome to Chamfers n Fillets!',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Container(
        color: const Color.fromARGB(255, 0, 0, 0),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Minimize unused space
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Header
                  Align(
                    alignment: Alignment.topCenter,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 150,
                        width: 200,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/icon/icon.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Spacing below the logo
                  // Name Field (Visible only during registration)
                  if (_isRegistering)
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: const TextStyle(color: Color(0xFFE0AA3E)),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE0AA3E)),
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE0AA3E)),
                        ),
                      ),
                      cursorColor: const Color(0xFFE0AA3E),
                    ),
                  if (_isRegistering)
                    const SizedBox(height: 10), // Spacing between fields
                  if (_isRegistering)
                    TextField(
                      controller: _phoneController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType:
                          TextInputType.number, // Ensures numeric keyboard
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: const TextStyle(color: Color(0xFFE0AA3E)),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE0AA3E)),
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE0AA3E)),
                        ),
                        errorText:
                            _phoneNumberError, // Display error message dynamically
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                      cursorColor: const Color(0xFFE0AA3E),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty) {
                            _phoneNumberError = 'Phone number is required';
                          } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                            _phoneNumberError =
                                'Enter a valid 10-digit phone number';
                          } else {
                            _phoneNumberError = null; // Clear the error
                          }
                        });
                      },
                    ),
                  const SizedBox(height: 10), // Spacing between fields
                  // Email Field
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType:
                        TextInputType.emailAddress, // Ensures email keyboard
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Color(0xFFE0AA3E)),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE0AA3E)),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE0AA3E)),
                      ),
                      errorText:
                          _emailError, // Display error message dynamically
                      errorStyle: const TextStyle(color: Colors.red),
                    ),
                    cursorColor: const Color(0xFFE0AA3E),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          _emailError = 'Email is required';
                        } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          _emailError = 'Enter a valid email address';
                        } else {
                          _emailError = null; // Clear the error
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10), // Spacing between fields
                  // Password Field
                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Color(0xFFE0AA3E)),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE0AA3E)),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE0AA3E)),
                      ),
                    ),
                    cursorColor: const Color(0xFFE0AA3E),
                  ),
                  const SizedBox(height: 20), // Spacing above the button
                  // Register/Login Button
                  ElevatedButton(
                    onPressed: _emailSignIn,
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(const Color(0xFFE0AA3E)),
                      foregroundColor: MaterialStateProperty.all(Colors.black),
                    ),
                    child: Text(
                      _isRegistering ? 'Register' : 'Login',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 10), // Spacing above the toggle text
                  // Forgot Password (Visible only during login)
                  if (!_isRegistering)
                    TextButton(
                      onPressed: reset,
                      style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.all(const Color(0xFFE0AA3E)),
                      ),
                      child: const Text('Forgot Password?'),
                    ),
                  // Toggle Login/Register Text
                  TextButton(
                    onPressed: _toggleForm,
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all(
                          const Color(0xFFE0AA3E)), // Text color
                    ),
                    child: Text(
                      _isRegistering
                          ? 'Already have an account? Login'
                          : 'Don’t have an account? Register',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
