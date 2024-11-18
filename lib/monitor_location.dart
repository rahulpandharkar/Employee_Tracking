import 'package:flutter/material.dart';
import 'package:location/location.dart';

class LocationMonitor extends StatefulWidget {
  final Widget child;

  const LocationMonitor({Key? key, required this.child}) : super(key: key);

  @override
  _LocationMonitorState createState() => _LocationMonitorState();
}

class _LocationMonitorState extends State<LocationMonitor> with WidgetsBindingObserver {
  final Location _location = Location();

  // Check if location services are enabled
  Future<bool> _isLocationEnabled() async {
    return await _location.serviceEnabled();
  }

  // Request location services to be turned on
  Future<bool> _enableLocationService() async {
    return await _location.requestService();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register observer
    _monitorLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _monitorLocation(); // Recheck location when app is resumed
    }
  }

  // Monitor location services and show dialog if turned off
  void _monitorLocation() async {
    bool serviceEnabled = await _isLocationEnabled();

    if (!serviceEnabled) {
      _showLocationDialog();
    }
  }

  // Show dialog to prompt user to enable location services
  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Location Service Off'),
          content: const Text('Location services are off. Please enable them.'),
          actions: [
            TextButton(
              onPressed: () async {
                bool serviceEnabled = await _enableLocationService();
                if (serviceEnabled) {
                  Navigator.pop(context); // Dismiss dialog if location is enabled
                } else {
                  // Keep the dialog open if the service is still disabled
                  _showLocationDialog();
                }
              },
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child; // Display the child widget (whole app)
  }
}
