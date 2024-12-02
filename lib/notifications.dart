import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http; 
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;  
import 'dart:convert'; 
import 'package:flutter/services.dart' show rootBundle;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
    bool isNotificationSent = false;
    //Server token for google fcm
    Future<String> getServerToken() async {
    final jsonString = await rootBundle.loadString('assets/fcm_access_token/service_token.json');
  final serviceAccountJson = jsonDecode(jsonString);

  List<String> scopes = [
    "https://www.googleapis.com/auth/firebase.messaging"
  ];

  // Create an HTTP client
  http.Client client = await auth.clientViaServiceAccount(
    auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
    scopes,
  );

  // Obtain access credentials
  auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount(
    auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
    scopes,
    client,
  );

  client.close();

  // Return the access token
  return credentials.accessToken.data;
  }

  Future<void> sendNotification(String email, String location, String timestamp) async {
    print("**********************************************************SEND NOTIFICATION CALLED****************************************************"); 
    var deviceToken = "e4AmFTEASL6yid_ha__lqd:APA91bE0NttTwBV6expXSRwUWAxHbhPZcxQxqT6lEYa5T9YyPQ6w6h26eWnuKLi85xFs4ujTaVhKuCCcXqD1P7a4I9S-Hreqd0yIU2d1jynrJI5LVA5LQIM";
    final String serverKey = await getServerToken();
    String endpoint = "https://fcm.googleapis.com/v1/projects/employee-app-1fd50/messages:send";

    final Map<String, dynamic> message = {
      'message': {
        'token': deviceToken,
        'notification': {
          'title': "Check-in Notification",
          'body': "$email checked in at $location on $timestamp!",
        },
      },
    };

    final http.Response response = await http.post(
      Uri.parse(endpoint),
      headers: <String, String>{
        'Content-Type': "application/json",
        'Authorization': 'Bearer $serverKey',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print("Notification sent successfully");
    } else {
      print("Failed to send notification: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup(
                'timestamps') // Listen to all timestamps subcollections across users
            .where('notification_read',
                isEqualTo: false) // Only unread notifications
            .orderBy('timestamp',
                descending: true) // Sort by timestamp in descending order
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
              var timestamp =
                  notification['timestamp'].toDate(); // Firebase timestamp
              var action = notification['action'];
              var latitude = notification['latitude'];
              var longitude = notification['longitude'];

              // Format the timestamp to human-readable format
              String formattedTimestamp =
                  DateFormat('EEEE, MMM dd, yyyy, hh:mm:ss a')
                      .format(timestamp);

              // Reverse geocoding to get the location
              // Reverse geocoding to get the detailed location
              Future<String> getLocation(double lat, double lng) async {
                try {
                  List<Placemark> placemarks =
                      await placemarkFromCoordinates(lat, lng);
                  if (placemarks.isNotEmpty) {
                    Placemark place = placemarks[0];
                    // Include sub-locality, locality, and country for a detailed address
                    return '${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
                  } else {
                    return 'Unknown Location';
                  }
                } catch (e) {
                  return 'Location Error';
                }
              }

              return FutureBuilder<String>(
                future: getLocation(latitude, longitude),
                builder: (context, locationSnapshot) {
                  if (locationSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  String location = locationSnapshot.data ?? 'Unknown Location';
                  sendNotification(userEmail ?? "Unknown", location, formattedTimestamp);

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text('Action: $action'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: $userEmail'),
                          Text('Timestamp: $formattedTimestamp'),
                          Text('Location: $location'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          // sendNotification(userEmail ?? "Unknown", location, formattedTimestamp);
                          // Mark the notification as read
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
      ),
    );
  }
}
