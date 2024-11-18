import 'package:flutter/material.dart';
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
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();

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
