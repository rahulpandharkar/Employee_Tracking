import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import the intl package

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Function to fetch notifications for all users in real-time
  Stream<List<Map<String, dynamic>>> fetchNotifications() {
    // Reference to the 'users' collection
    CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

    // Stream to listen for real-time updates
    return usersCollection.snapshots().asyncMap((usersSnapshot) async {
      List<Map<String, dynamic>> allNotifications = [];

      // Iterate over all users and fetch their timestamps in real-time
      for (var userDoc in usersSnapshot.docs) {
        String userEmail = userDoc.id; // Get the email from the user document ID

        // Reference to the 'timestamps' subcollection for each user
        CollectionReference timestampsCollection = userDoc.reference.collection('timestamps');

        // Listen for real-time updates on 'timestamps' subcollection
        var querySnapshot = await timestampsCollection.where('notification_read', isEqualTo: false).get();

        // Extract notifications where notification_read is false
        for (var doc in querySnapshot.docs) {
          var timestampData = doc.data() as Map<String, dynamic>;

          allNotifications.add({
            'doc_id': doc.id,  // Store the document ID for updating
            'email': userEmail,
            'action': timestampData['action'],
            // Convert Timestamp to DateTime for comparison
            'timestamp': (timestampData['timestamp'] as Timestamp).toDate(),
            'latitude': timestampData['latitude'],
            'longitude': timestampData['longitude'],
            'notification_read': timestampData['notification_read'],
          });
        }
      }

      // Sort the notifications by timestamp (in descending order)
      allNotifications.sort((a, b) {
        DateTime timeA = a['timestamp'];
        DateTime timeB = b['timestamp'];
        return timeB.compareTo(timeA);  // Descending order
      });

      return allNotifications;
    });
  }

  // Function to mark the notification as read
  Future<void> markNotificationRead(String docId, String userEmail) async {
    // Reference to the specific notification document
    CollectionReference timestampsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .collection('timestamps');
    
    try {
      await timestampsCollection.doc(docId).update({'notification_read': true});
    } catch (e) {
      print("Error updating notification: $e");
    }
  }

  // Refresh function to trigger the refresh manually
  Future<void> _refreshNotifications() async {
    setState(() {}); // Force a rebuild to reload data from Firestore
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blueAccent,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications, // Trigger the refresh
        child: StreamBuilder<List<Map<String, dynamic>>>( 
          stream: fetchNotifications(),  // Listening to real-time updates
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // Display 'No notifications' if the data is empty
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                children: [
                  Center(child: Text('No notifications found.')),
                ],
              );
            }

            // Data has been successfully fetched, display in a ListView
            var notifications = snapshot.data!;
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                var notification = notifications[index];

                // Format the timestamp to human-readable format
                DateTime timestamp = notification['timestamp'];
                String formattedTimestamp = DateFormat('d MMM yyyy, HH:mm:ss').format(timestamp);

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      notification['action'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${notification['email']}'),
                        Text('Timestamp: $formattedTimestamp'),
                        Text('Location: Lat: ${notification['latitude']}, Long: ${notification['longitude']}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        notification['notification_read']
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: notification['notification_read'] ? Colors.green : Colors.grey,
                      ),
                      onPressed: () {
                        if (!notification['notification_read']) {
                          markNotificationRead(notification['doc_id'], notification['email']);
                          setState(() {}); // Refresh UI after marking as read
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
