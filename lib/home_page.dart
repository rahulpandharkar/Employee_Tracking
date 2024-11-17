import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import the intl package for formatting

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _location = "Press the button to get location";
  String _statusMessage = "Status: Ready to check in";
  FirebaseAuth auth = FirebaseAuth.instance;
  bool _hasCheckedIn = false; // Track if the user has checked in

  // Function to get current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = "Location services are disabled.";
      });
      return;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = "Location permission denied.";
        });
        return;
      }
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _location = "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
    });

    // Save check-in to Firestore
    await _saveCheckIn(position);
  }

  // Function to save the check-in data to Firestore
  Future<void> _saveCheckIn(Position position) async {
    User? user = auth.currentUser;

    if (user == null) {
      setState(() {
        _statusMessage = "Please log in to check in.";
      });
      return;
    }

    try {
      // Firestore document path using email as primary key
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.email);

      // Create timestamp in the format 'yyyy-MM-dd-HH:mm'
      String formattedTimestamp = DateFormat('yyyy-MM-dd-HH:mm').format(DateTime.now());

      // Add check-in data to Firestore with formatted timestamp as ID
      await userDoc.collection('checkinhistory').doc(formattedTimestamp).set({
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'action': 'checkin', // Mark this as checkin
      });

      setState(() {
        _statusMessage = "Check-in successful!";
        _hasCheckedIn = true; // Set the flag to true after successful check-in
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error saving check-in data: $e";
      });
    }
  }

  // Function to save the checkout data to Firestore
  Future<void> _saveCheckout(Position position) async {
    User? user = auth.currentUser;

    if (user == null) {
      setState(() {
        _statusMessage = "Please log in to checkout.";
      });
      return;
    }

    try {
      // Firestore document path using email as primary key
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.email);

      // Create timestamp in the format 'yyyy-MM-dd-HH:mm'
      String formattedTimestamp = DateFormat('yyyy-MM-dd-HH:mm').format(DateTime.now());

      // Add checkout data to Firestore with formatted timestamp as ID
      await userDoc.collection('checkouthistory').doc(formattedTimestamp).set({
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'action': 'checkout', // Mark this as checkout
      });

      setState(() {
        _statusMessage = "Checkout successful!";
        _hasCheckedIn = false; // Reset check-in flag after checkout
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error saving checkout data: $e";
      });
    }
  }

  // Function to handle checkout
  Future<void> _getCheckoutLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = "Location services are disabled.";
      });
      return;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = "Location permission denied.";
        });
        return;
      }
    }

    // Get current position for checkout
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Save checkout to Firestore
    await _saveCheckout(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _location,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _hasCheckedIn ? null : _getCurrentLocation, // Disable button if checked in
                child: const Text('Check In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasCheckedIn ? Colors.grey : Colors.blue, // Correct property for background color
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _hasCheckedIn ? _getCheckoutLocation : null, // Disable unless check-in is done
                child: const Text('Check Out'),
              ),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
