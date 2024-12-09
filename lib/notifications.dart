import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'firestore_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFFE0AA3E),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('timestamps') // Listen to all timestamps subcollections across users
            .where('notification_read', isEqualTo: false) // Only unread notifications
            .orderBy('timestamp', descending: true) // Sort by timestamp in descending order
            .snapshots(), // Real-time updates
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No unread notifications.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index];
              var userEmail = notification.reference.parent.parent?.id;
              var notificationId = notification.id;
              var timestamp = notification['timestamp'].toDate(); // Firebase timestamp
              var action = notification['action'] == 'checkin'
                  ? "Checked In"
                  : (notification['action'] == 'checkout' ? "Checked Out" : "");
              var latitude = notification['latitude'];
              var longitude = notification['longitude'];

              // Format the timestamp to human-readable format
              String formattedTimestamp =
                  DateFormat('EEEE, MMM dd, yyyy, hh:mm:ss a').format(timestamp);

              // Reverse geocoding to get the detailed location
              Future<String> getLocation(double lat, double lng) async {
                try {
                  List<Placemark> placemarks =
                      await placemarkFromCoordinates(lat, lng);
                  if (placemarks.isNotEmpty) {
                    Placemark place = placemarks[0];
                    return '${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
                  } else {
                    return 'Unknown Location';
                  }
                } catch (e) {
                  return 'Location Error';
                }
              }

              return FutureBuilder<String?>(
                future: FirestoreService().getNameFromFirestore(userEmail ?? ""),
                builder: (context, nameSnapshot) {
                  if (nameSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  String userName = nameSnapshot.data ?? 'Unknown User';

                  return FutureBuilder<String>(
                    future: getLocation(latitude, longitude),
                    builder: (context, locationSnapshot) {
                      if (locationSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      String location = locationSnapshot.data ?? 'Unknown Location';
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text('$userName $action'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: $userEmail'),
                              Text('Timestamp: $formattedTimestamp'),
                              Text('Location: $location'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.check, color: Color(0xFFE0AA3E)),
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userEmail)
                                  .collection('timestamps')
                                  .doc(notificationId)
                                  .update({'notification_read': true});
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
