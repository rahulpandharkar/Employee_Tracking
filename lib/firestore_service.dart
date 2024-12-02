import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http; 
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;  
import 'dart:convert'; 
import 'package:flutter/services.dart' show rootBundle;

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // Generic function to save data (check-in or check-out)
  Future<void> saveData(Position position, String action) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.email);

      // Ensure the parent user document exists
      await userDoc.set(<String, dynamic>{}, SetOptions(merge: true)); // Pass an empty Map<String, dynamic>

      // Use the formatted timestamp directly as the document ID
      String formattedTimestamp = DateFormat('yyyy-MM-dd-HH:mm').format(DateTime.now());

      // Add data directly under the user document with timestamp as the document ID
      await userDoc.collection('timestamps').doc(formattedTimestamp).set({
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'action': action,
        'notification_read': false,
      });
      sendNotification(user.email!, "location", DateTime.now().toString());
    } catch (e) {
      print("Error saving $action data: $e");
    }
  }

  // Function to save check-in data
  Future<void> saveCheckIn(Position position) async {
    await saveData(position, 'checkin');
  }

  // Function to save checkout data
  Future<void> saveCheckout(Position position) async {
    await saveData(position, 'checkout');
  }
}
