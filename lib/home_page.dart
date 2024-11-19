import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Auth
import 'location_service.dart';
import 'firestore_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _location = "Press the button to check-in";
  String _statusMessage = "Status: Ready to check in";
  String _currentStatus = "Current Status: Not Checked-In";
  String _lastCheckedInTimestamp = ""; // Stores the timestamp of the last check-in
  bool _hasCheckedIn = false;
  String _email = ''; // Placeholder email
  String _profileImageUrl =
      "https://www.example.com/default_profile_image.png"; // Default profile image URL

  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _fetchUserInfo(); // Fetch user info when the page is initialized
    _fetchCheckInStatus(); // Fetch the latest check-in status
  }

  // Fetch user email and profile picture from Firebase Authentication
  Future<void> _fetchUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        _email = user.email ?? 'No email';
        _profileImageUrl = user.photoURL ??
            'https://www.example.com/default_profile_image.png';
      });
    } else {
      setState(() {
        _email = 'User not logged in';
      });
    }
  }

  // Fetch the latest check-in or check-out status from Firestore
  Future<void> _fetchCheckInStatus() async {
    String lastAction = await _firestoreService.getLastAction();
    setState(() {
      if (lastAction == 'checkin') {
        _hasCheckedIn = true;
        _statusMessage = "Status: Already checked in.";
        _currentStatus = "Current Status: Checked-In";
        _lastCheckedInTimestamp = DateTime.now().toString(); // Placeholder timestamp
      } else {
        _hasCheckedIn = false;
        _statusMessage = "Status: Ready to check in.";
        _currentStatus = "Current Status: Not Checked-In";
      }
    });
  }

  // Check-in logic
  Future<void> _getCurrentLocation() async {
    var position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _location = "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
        _statusMessage = "Status: Checked in!";
        _hasCheckedIn = true; // Enable checkout
        _currentStatus = "Current Status: Checked-In";
        _lastCheckedInTimestamp = DateTime.now().toString(); // Update last check-in timestamp
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
        _hasCheckedIn = false; // Disable checkout after check-out
        _currentStatus = "Current Status: Not Checked-In";
        _lastCheckedInTimestamp = ""; // Clear last check-in timestamp on checkout
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const SizedBox(height: 20),
              Text(_currentStatus, style: const TextStyle(fontSize: 16)),
              if (_lastCheckedInTimestamp.isNotEmpty)
                Text(
                  "Last Check-In: $_lastCheckedInTimestamp",
                  style: const TextStyle(fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
