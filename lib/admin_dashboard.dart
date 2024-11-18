import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
      final historyRef = firestore.collection('users').doc(email).collection(historyType);
      final historySnapshot = await historyRef.get();
      return historySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
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

            // History records data
            List<Map<String, dynamic>> historyData = snapshot.data!;

            return AlertDialog(
              title: Text('$historyType History'),
              content: SingleChildScrollView(
                child: Column(
                  children: historyData.map((data) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Action: ${data['action']}'),
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

  // UI to show user data with clickable cards
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: fetchUserDocuments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(child: Text('No users found.'));
          }

          List<DocumentSnapshot> users = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                String email = users[index].id;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    title: Text(email),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      // Show options for checkin or checkout history
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
                                    showHistoryModal(context, email, 'checkinhistory');
                                  },
                                  child: Text('View Check-in History'),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    showHistoryModal(context, email, 'checkouthistory');
                                  },
                                  child: Text('View Check-out History'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: AdminDashboard()));
