import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'maps.dart';
import 'notifications.dart';
import 'login_register.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; 


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _unreadNotificationsCount = 0;
  List<DocumentSnapshot> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    try {
      // Check admin access
      await _checkAdminAccess();
      
      // Fetch users
      await _fetchUserDocuments();

      //Update Device Token
      await _checkAndUpdateDeviceToken();
      
      // Start listening for notification count
      _startNotificationCountListener();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAdminAccess() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email != 'admin@admin.com') {
      await FirebaseAuth.instance.signOut();
      throw 'Unauthorized Access';
    }
  }

Future<void> _checkAndUpdateDeviceToken() async {
  try {
    // Step 1: Get the device token
    String? deviceToken = await FirebaseMessaging.instance.getToken();
    
    if (deviceToken == null) {
      print("Device token is null.");
      return;
    }

    print("Device Token: $deviceToken");

    // Step 2: Reference to the Firestore collection path
    final deviceTokensRef = FirebaseFirestore.instance
        .collection('admin') // The root collection
        .doc('device-tokens'); // The document for device tokens

    // Check if the 'device-tokens' document exists
    DocumentSnapshot deviceTokensDoc = await deviceTokensRef.get();

    // If it doesn't exist, create it
    if (!deviceTokensDoc.exists) {
      await deviceTokensRef.set({});
      print("Device tokens document created.");
    }

    // Now access the 'timestamps' subcollection
    final timestampsRef = deviceTokensRef.collection('timestamps');

    // Step 3: Check if the token already exists in the 'timestamps' collection
    final querySnapshot = await timestampsRef.get();

    bool tokenExists = false;
    
    // Iterate through all existing tokens to check for a match
    for (var doc in querySnapshot.docs) {
      if (doc.data()['token-value'] == deviceToken) {
        tokenExists = true;
        break;
      }
    }

    // Step 4: If token doesn't exist, create a new document using current timestamp
    if (!tokenExists) {
      // Get current timestamp as document name (DateTime formatted as string)
      String timestamp = DateFormat('yyyy-dd-MM HH:mm:ss').format(DateTime.now());
      
      // Save token and timestamp under the collection named 'timestamps'
      await timestampsRef
          .doc(timestamp) // Use the timestamp as the document name
          .set({
            'token-value': deviceToken,
            'timestamp': Timestamp.now(),
          });

      print("Device token saved successfully.");
    } else {
      print("Device token already exists in the collection.");
    }

  } catch (e) {
    print("Error: $e");
  }
}

  Future<void> _fetchUserDocuments() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      setState(() {
        _users = querySnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching users: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startNotificationCountListener() {
    FirebaseFirestore.instance
        .collectionGroup('timestamps')
        .where('notification_read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = snapshot.docs.length;
        });
      }
    }, onError: (error) {
      print('Notification count error: $error');
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = 0;
        });
      }
    });
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginRegister()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: ${e.toString()}')),
      );
    }
  }

  void _showHistoryModal(BuildContext context, String email, String historyType) {
    showDialog(
      context: context,
      builder: (context) => _buildHistoryDialog(email, historyType),
    );
  }

  Widget _buildHistoryDialog(String email, String historyType) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchHistory(email, historyType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || 
            snapshot.data == null || 
            snapshot.data!.isEmpty) {
          return AlertDialog(
            title: Text('No $historyType records found'),
            content: Text('There are no $historyType records available for this user.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: Text('Location History'),
          content: SingleChildScrollView(
            child: Column(
              children: snapshot.data!.map((data) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    title: Text('Action: ${data['action']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Latitude: ${data['latitude']}'),
                        Text('Longitude: ${data['longitude']}'),
                        Text('Timestamp: ${data['timestamp'].toDate()}'),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchHistory(String email, String historyType) async {
    try {
      final historySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .collection('timestamps')
          .where('action', isEqualTo: historyType)
          .get();

      return historySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching $historyType history: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor:  const Color.fromARGB(255, 144, 29, 167),
        actions: [
             IconButton(
            icon: const Icon(Icons.refresh, size: 30),
            onPressed: () {
            setState(() {
              _isLoading = true; // Show loading while fetching
            });
            _initializeDashboard(); // Fetch the data again
          },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(),
                    ),
                  );
                },
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$_unreadNotificationsCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          
          // Sign Out Icon
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirm Sign Out'),
                  content: Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _signOut();
                      },
                      child: Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 200,
                  height: 20,
                  color: Colors.grey,
                ),
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 209, 3, 236),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'View Map',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: _users.isEmpty
                ? Center(child: Text('No users found'))
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      String email = _users[index].id;
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text(email),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Select History'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _showHistoryModal(context, email, 'checkin');
                                      },
                                      child: Text('Check-in History'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _showHistoryModal(context, email, 'checkout');
                                      },
                                      child: Text('Check-out History'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}