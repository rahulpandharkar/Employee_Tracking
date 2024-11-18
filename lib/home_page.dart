import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  // For Firebase Auth
import 'location_service.dart';
import 'firestore_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _location = "Press the button to get location";
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
      appBar: AppBar(title: const Text('Home Page')),
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
