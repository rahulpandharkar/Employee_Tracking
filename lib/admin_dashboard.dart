import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'maps.dart';
import 'notifications.dart';
import 'login_register.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Check if the logged-in user is the admin
  Future<void> checkAdminAccess() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email != 'admin@admin.com') {
      // If not an admin, show dialog and redirect to login screen
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Access Denied'),
            content: Text('You are not authorized to access this page. Redirecting to login screen.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginRegister()), // Redirect to LoginRegister screen
                  );
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  // Function to fetch all document IDs in the 'users/' collection
  Future<List<DocumentSnapshot>> fetchUserDocuments() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      final querySnapshot = await firestore.collection('users').get();
      return querySnapshot.docs;
    } catch (e) {
      print('Error fetching user documents: $e');
      return [];
    }
  }

  // Function to fetch and display check-in or check-out history
  Future<List<Map<String, dynamic>>> fetchHistory(String email, String historyType) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      final historyRef = firestore
          .collection('users')
          .doc(email)
          .collection('timestamps')
          .where('action', isEqualTo: historyType);

      final historySnapshot = await historyRef.get();
      return historySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print('Error fetching $historyType: $e');
      return [];
    }
  }

  // Show a modal with history details (Check-in/Check-out)
  void showHistoryModal(BuildContext context, String email, String historyType) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>( 
          future: fetchHistory(email, historyType),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
              return AlertDialog(
                title: Text('No $historyType records found'),
                content: Text('There are no $historyType records available for this user.'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close'),
                  ),
                ],
              );
            }

            List<Map<String, dynamic>> historyData = snapshot.data!;

            return AlertDialog(
              title: Text('Location History'),
              content: SingleChildScrollView(
                child: Column(
                  children: historyData.map((data) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5),
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Action: ${data['action']}', style: TextStyle(fontWeight: FontWeight.bold)),
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
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Function to sign out the user
  Future<void> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginRegister()), // Redirect to LoginRegister screen
      );
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // UI to show user data with clickable cards
  @override
  void initState() {
    super.initState();
    checkAdminAccess(); // Check if the user is admin on dashboard load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          // Bell icon with static count (0)
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications, size: 30),
                Positioned(
                  right: 0,
                  top: 0,
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
                      '0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsScreen(),
                ),
              );
            },
          ),
          // Sign-out icon
          IconButton(
            icon: Icon(Icons.exit_to_app, size: 30),
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Sign Out'),
                    content: Text('Do you really want to sign out?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          signOut(context); // Sign out and redirect
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: fetchUserDocuments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 200,
                  height: 20,
                  color: Colors.grey,
                ),
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No users found.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          List<DocumentSnapshot> users = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // "View Map" button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.greenAccent,
                  ),
                  child: Text(
                    'View Map',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      String email = users[index].id;
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Select History'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        showHistoryModal(context, email, 'checkin');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        backgroundColor: Colors.blueAccent,
                                      ),
                                      child: Text('Check-in History'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        showHistoryModal(context, email, 'checkout');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      child: Text('Check-out History'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Text(email, style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('User ID: ${users[index].id}'),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
