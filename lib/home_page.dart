import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import 'location_service.dart';
import 'login_register.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';

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
  String _userName = '';

  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchLatestTimestamp();
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Get the FCM token
    String? token = await messaging.getToken();
    print('FCM Token: $token');

    if (token != null) {
      await _saveDeviceToken(token); // Save the token to Firestore
    }
  }

  Future<void> _saveDeviceToken(String token) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Reference to the user document
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.email);

      // Get the current timestamp in the format 'yyyy-MM-dd HH:mm:ss'
      String timestamp =
          DateFormat('yyyy-dd-MM HH:mm:ss').format(DateTime.now());

      // Reference to the device-tokens subcollection
      CollectionReference deviceTokensRef = userDoc.collection('device-tokens');

      // Check if the token already exists in the device-tokens subcollection
      QuerySnapshot tokenSnapshot =
          await deviceTokensRef.where('token-value', isEqualTo: token).get();

      // If the token already exists, no need to add it again
      if (tokenSnapshot.docs.isNotEmpty) {
        print("Token already exists, not saving again.");
        return;
      }

      // Determine the platform (Android/iOS)
      String platform =
          defaultTargetPlatform == TargetPlatform.iOS ? "iOS" : "Android";

      // Save the new token under the timestamp document
      await deviceTokensRef.doc(timestamp).set({
        'token-value': token,
        'platform': platform,
        'timestamp': timestamp,
      });

      print("Token saved successfully");
    } catch (e) {
      print("Error saving device token: $e");
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
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
      // Fetch the name using the getNameFromFirestore function
      String? userName =
          await FirestoreService().getNameFromFirestore(user.email ?? '');

      setState(() {
        _email = user.email ?? 'No email';
        _profileImageUrl = user.photoURL ??
            'https://www.example.com/default_profile_image.png';
        _userName = userName ?? 'No name'; // Use the fetched name
      });
    } else {
      setState(() {
        _email = 'User not logged in';
        _userName = 'No name'; // Default value if user is not logged in
      });
    }
  }

  Future<void> _fetchLatestTimestamp() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.email);
      QuerySnapshot snapshot = await userDoc
          .collection('timestamps')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

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
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          setState(() {
            _location =
                "${place.street}, ${place.subLocality}, ${place.locality}, "
                "${place.administrativeArea}, ${place.country}";
            _statusMessage = "Status: Checked in!";
            _hasCheckedIn = true;
          });
        }
        await _firestoreService.saveCheckIn(position);
      } catch (e) {
        setState(() {
          _location = "Error fetching address. Latitude: ${position.latitude}, "
              "Longitude: ${position.longitude}";
          _statusMessage = "Status: Failed to get address. Please try again.";
        });
      }
    } else {
      setState(() {
        _statusMessage = "Status: Failed to get location. Please try again.";
      });
    }
  }

  Future<void> _getCheckoutLocation() async {
    var position = await _locationService.getCurrentLocation();
    if (position != null) {
      //suspicious checkout
      DateTime checkoutTimestamp = DateTime.now();
      await _firestoreService.checkSuspiciousCheckout(
          position, checkoutTimestamp);
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
        title: const Text(
          'Home',
          style: TextStyle(
              color: Colors.black), // Change title text color to black
        ),
        iconTheme: IconThemeData(
          color: Colors.black, // Change all icons in the app bar to black
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.account_circle,
              color: Colors.black, // Change the icon color to black
            ),
            onSelected: (value) async {
              if (value == 'signout') {
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Sign Out',
                          style: TextStyle(
                              color: Colors
                                  .white)), // Change text color in alert to black
                      content: const Text('Are you sure you want to sign out?',
                          style: TextStyle(
                              color: Colors
                                  .white)), // Change content text color to black
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel',
                              style: TextStyle(
                                  color: Colors
                                      .white)), // Change button text color to black
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        TextButton(
                          child: const Text('Sign Out',
                              style: TextStyle(
                                  color: Colors
                                      .white)), // Change button text color to black
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
                    Icon(
                      Icons.logout,
                      color:
                          Colors.white, // Change the logout icon color to black
                    ),
                    SizedBox(width: 8),
                    Text('Sign Out',
                        style: TextStyle(
                            color: Colors.white)), // Change text color to black
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    AdvancedAvatar(
                      size: 100, // Size of the avatar
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(
                            255, 0, 0, 0), // Background color of the avatar
                        shape: BoxShape.circle, // Circular shape
                      ),
                      child: Text(
                        _userName.isNotEmpty
                            ? _userName[0]
                                .toUpperCase() // Capitalize the first letter
                            : 'U', // Default to 'U' if userName is empty
                        style: const TextStyle(
                          fontSize: 40, // Font size of the letter
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE0AA3E), // Letter color
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _userName.isNotEmpty
                          ? _userName[0].toUpperCase() + _userName.substring(1)
                          : _userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _location,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _hasCheckedIn
                          ? _getCheckoutLocation
                          : _getCurrentLocation,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        backgroundColor: Color(
                            0xFFE0AA3E), // Set the background color to your desired HEX (replace with your HEX value)
                        foregroundColor:
                            Colors.black, // Set the text color to white
                      ),
                      child: Text(_hasCheckedIn ? 'Check Out' : 'Check In'),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
