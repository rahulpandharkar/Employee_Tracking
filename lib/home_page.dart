import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'location_service.dart';
import 'firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_register.dart'; // Add this import

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _location = "Press the button to check-in";
  String _statusMessage = "Status: Ready to check in";
  bool _hasCheckedIn = false;
  String _email = '';
  String _profileImageUrl = "https://www.example.com/default_profile_image.png";

  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchLatestTimestamp();
  }

  // Updated sign out function with explicit navigation
  Future<void> _signOut() async {
    try {
      // If user is checked in, perform checkout before signing out
      if (_hasCheckedIn) {
        await _getCheckoutLocation();
      }
      
      await FirebaseAuth.instance.signOut();
      
      // Use mounted check before navigation
      if (!mounted) return;
      
      // Navigate to login screen and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginRegister()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        _email = user.email ?? 'No email';
        _profileImageUrl = user.photoURL ?? 'https://www.example.com/default_profile_image.png';
      });
    } else {
      setState(() {
        _email = 'User not logged in';
      });
    }
  }

  Future<void> _fetchLatestTimestamp() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.email);
      QuerySnapshot snapshot = await userDoc.collection('timestamps').orderBy('timestamp', descending: true).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        String action = snapshot.docs.first['action'];

        setState(() {
          if (action == 'checkin') {
            _hasCheckedIn = true;
            _statusMessage = "Status: Checked in!";
            _location = "You are already checked in.";
          } else if (action == 'checkout') {
            _hasCheckedIn = false;
            _statusMessage = "Status: Checked out!";
            _location = "You are checked out.";
          }
        });
      }
    } catch (e) {
      print("Error fetching latest timestamp: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    var position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _location = "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
        _statusMessage = "Status: Checked in!";
        _hasCheckedIn = true;
      });
      await _firestoreService.saveCheckIn(position);
    } else {
      setState(() {
        _statusMessage = "Status: Failed to get location. Please try again.";
      });
    }
  }

  Future<void> _getCheckoutLocation() async {
    var position = await _locationService.getCurrentLocation();
    if (position != null) {
      await _firestoreService.saveCheckout(position);
      setState(() {
        _statusMessage = "Status: Checked out!";
        _hasCheckedIn = false;
      });
    } else {
      setState(() {
        _statusMessage = "Status: Failed to get location. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'signout') {
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        TextButton(
                          child: const Text('Sign Out'),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    );
                  },
                );
                
                if (confirm == true) {
                  await _signOut();
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(_profileImageUrl),
                        onBackgroundImageError: (_, __) => const Icon(Icons.error),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _email,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(_location, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _hasCheckedIn ? null : _getCurrentLocation,
                child: const Text('Check In'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _hasCheckedIn ? _getCheckoutLocation : null,
                child: const Text('Check Out'),
              ),
              const SizedBox(height: 20),
              Text(_statusMessage, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}