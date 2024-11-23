import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  // For Firebase Auth
import 'location_service.dart';
import 'firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _location = "Press the button to check-in";
  String _statusMessage = "Status: Ready to check in";
  bool _hasCheckedIn = false;
  String _email = '';  // Placeholder email
  String _profileImageUrl = "https://www.example.com/default_profile_image.png";  // Default profile image URL

  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();  // Fetch user info when the page is initialized
    _fetchLatestTimestamp();  // Fetch the latest timestamp on init
  }

  // Fetch user email and profile picture from Firebase Authentication
  Future<void> _fetchUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;  // Get the current authenticated user

    if (user != null) {
      setState(() {
        _email = user.email ?? 'No email';  // Fetch email from Firebase Auth
        _profileImageUrl = user.photoURL ?? 'https://www.example.com/default_profile_image.png';  // Fetch profile picture URL
      });
    } else {
      setState(() {
        _email = 'User not logged in';  // Handle the case where the user is not logged in
      });
    }
  }

  // Fetch the latest timestamp and set check-in/check-out status accordingly
  Future<void> _fetchLatestTimestamp() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.email);

      // Query to get the latest timestamp
      QuerySnapshot snapshot = await userDoc.collection('timestamps').orderBy('timestamp', descending: true).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        String action = snapshot.docs.first['action'];

        setState(() {
          // Set check-in/check-out status based on the latest action
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

  // Check-in logic
  Future<void> _getCurrentLocation() async {
    var position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _location = "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
        _statusMessage = "Status: Checked in!";
        _hasCheckedIn = true; // Enable checkout
      });
      await _firestoreService.saveCheckIn(position);
    } else {
      setState(() {
        _statusMessage = "Status: Failed to get location. Please try again.";
      });
    }
  }

  // Check-out logic
  Future<void> _getCheckoutLocation() async {
    var position = await _locationService.getCurrentLocation();
    if (position != null) {
      await _firestoreService.saveCheckout(position);
      setState(() {
        _statusMessage = "Status: Checked out!";
        _hasCheckedIn = false; // Disable checkout after check out
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
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(  // Ensure the content is always centered
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,  // Center align content
            crossAxisAlignment: CrossAxisAlignment.center,  // Center align content
            children: [
              // Profile Card
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
                        radius: 50,  // Adjust size for profile image
                        backgroundImage: NetworkImage(_profileImageUrl),
                        onBackgroundImageError: (_, __) => Icon(Icons.error),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _email,  // Display user email (fetched from Firebase Auth)
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              
              // Location and Check-in/Check-out Section
              Text(_location, style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _hasCheckedIn ? null : _getCurrentLocation,
                child: const Text('Check In'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _hasCheckedIn ? _getCheckoutLocation : null,
                child: const Text('Check Out'),
              ),
              SizedBox(height: 20),
              Text(_statusMessage, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
