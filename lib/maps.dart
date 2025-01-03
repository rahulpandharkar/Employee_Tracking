import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Add this for date formatting
import 'firestore_service.dart';
import 'package:permission_handler/permission_handler.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final MapController _mapController = MapController();

  List<Marker> _markers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCheckedInUsers();
  }

  void _fitBounds() {
    if (_markers.isEmpty) return;

    final points = _markers.map((marker) => marker.point).toList();

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    final bounds = LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        maxZoom: 18,
      ),
    );
  }

  void _showUserDetails(
      BuildContext context, String email, DateTime timestamp) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(timestamp);
    final formattedTime = DateFormat('HH:mm:ss').format(timestamp);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(email),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Last Check-in:'),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(formattedDate),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text(formattedTime),
                ],
              ),
            ],
          ),
          actions: [
           TextButton(
  onPressed: () async {
    // Request permission to make a phone call if not granted
    var status = await Permission.phone.status;

    if (!status.isGranted) {
      // Request the permission
      await Permission.phone.request();
      // After requesting permission, check again
      status = await Permission.phone.status;
    }

    // Proceed with calling only if permission is granted
    if (status.isGranted) {
      // Fetch the phone number dynamically from Firestore
      final phoneNumber = await FirestoreService.getPhoneNumberFromFirestore(email);

      // If phone number is found
      if (phoneNumber != null) {
        final Uri url = Uri.parse('tel:$phoneNumber'); // Ensure correct Uri format

        // Check if the phone dialer can be launched
        bool canLaunchPhone = await canLaunchUrl(url);
        print('Can launch: $canLaunchPhone'); // Debugging output

        if (canLaunchPhone) {
          await launchUrl(url); // Launch the dialer
        } else {
          print('Could not launch phone dialer');
        }
      } else {
        print('Phone number not found');
      }
    } else {
      print('Permission denied');
    }
  },
  style: TextButton.styleFrom(
    foregroundColor: Color(0xFFE0AA3E), // Gold color for the text
    textStyle: const TextStyle(
      fontWeight: FontWeight.bold, // Bold text
    ),
  ),
  child: const Text('Call'),
),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFFE0AA3E), // Gold hex color
                  fontWeight: FontWeight.bold, // Optional: Bold text
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadCheckedInUsers() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final usersSnapshot = await firestore.collection('users').get();
      List<Marker> markers = [];

      for (var userDoc in usersSnapshot.docs) {
        final String userEmail = userDoc.id;
        String? userName =
            await FirestoreService().getNameFromFirestore(userEmail);
        // Query the 'timestamps' subcollection and order by timestamp
        final timestampsSnapshot = await userDoc.reference
            .collection('timestamps')
            .orderBy('timestamp', descending: true)
            .limit(1) // Get the most recent timestamp
            .get();

        if (timestampsSnapshot.docs.isNotEmpty) {
          final timestampDoc = timestampsSnapshot.docs.first;
          final timestampData = timestampDoc.data();

          // Check if the last action was a checkin
          final action = timestampData['action'] as String;
          if (action == 'checkin') {
            final latitude = timestampData['latitude'] as double;
            final longitude = timestampData['longitude'] as double;
            final timestamp =
                (timestampData['timestamp'] as Timestamp).toDate();

            markers.add(
              Marker(
                width: 120.0,
                height: 60.0,
                point: LatLng(latitude, longitude),
                child: GestureDetector(
                  onTap: () => _showUserDetails(context, userEmail, timestamp),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          userName ?? userEmail,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.location_on,
                          color: Colors.red, size: 30),
                    ],
                  ),
                ),
              ),
            );
          }
        }
      }

      setState(() {
        _markers = markers;
        _isLoading = false;
      });

      if (_markers.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), _fitBounds);
      }
    } catch (e) {
      print('Error loading checked-in users: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Employees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadCheckedInUsers();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: LatLng(19.0760, 72.8777),
                          initialZoom: 15,
                          minZoom: 3,
                          maxZoom: 18,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          MarkerLayer(markers: _markers),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Number of Users Currently Checked In: ${_markers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _fitBounds,
                    child: const Text(
                      'Reset View',
                      style: TextStyle(
                        color: Color(0xFFE0AA3E), // Gold hex color
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
