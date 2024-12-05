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
  bool _dialogShown = false;

  Future<bool> _isLocationEnabled() async {
    return await _location.serviceEnabled();
  }

  Future<bool> _enableLocationService() async {
    return await _location.requestService();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _monitorLocation();

    // Listen for location changes continuously.
    _location.onLocationChanged.listen((event) async {
      bool serviceEnabled = await _isLocationEnabled();
      if (!serviceEnabled && !_dialogShown) {
        _showLocationDialog();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _monitorLocation();
    }
  }

  void _monitorLocation() async {
    if (!mounted) return;

    bool serviceEnabled = await _isLocationEnabled();
    if (!serviceEnabled && !_dialogShown) {
      _showLocationDialog();
    }
  }

  void _showLocationDialog() {
    if (!mounted || _dialogShown) return;

    setState(() {
      _dialogShown = true;
    });

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
                Navigator.pop(context); // Close the dialog temporarily
                bool serviceEnabled = await _enableLocationService();
                if (serviceEnabled) {
                  setState(() {
                    _dialogShown = false;
                  });
                } else {
                  _showLocationDialog(); // Show the dialog again if still disabled
                }
              },
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Color(0xFFE0AA3E), // Gold hex color
                  fontWeight: FontWeight.bold, // Optional: Bold text
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _dialogShown = false; // Reset dialog state when dismissed
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
