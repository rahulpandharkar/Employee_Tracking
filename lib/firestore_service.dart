import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http; 
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;  
import 'dart:convert'; 
import 'package:flutter/services.dart' show rootBundle;
import 'package:geocoding/geocoding.dart'; 
import 'dart:math'; 

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

  Future<void> sendNotification(String email, String action, double latitude, double longitude, DateTime timestamp) async {
  print("**********************************************************SEND NOTIFICATION CALLED****************************************************"); 
  final String serverKey = await getServerToken();
  String endpoint = "https://fcm.googleapis.com/v1/projects/employee-app-1fd50/messages:send";

  // Reverse geocoding to get location details
  String location = "Unknown Location";
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      location = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
    }
  } catch (e) {
    print("Error during reverse geocoding: $e");
  }

  // Format the timestamp
    String formattedTimestamp =DateFormat('EEEE, MMM dd, yyyy, hh:mm:ss a').format(timestamp);

  // Fetch all device tokens from Firestore
  try {
    CollectionReference deviceTokensCollection = FirebaseFirestore.instance.collection('/admin/device-tokens/timestamps');
    QuerySnapshot snapshot = await deviceTokensCollection.get();
    String? userName =  await getNameFromFirestore(email);

    if (snapshot.docs.isEmpty) {
      print("No device tokens found.");
      return;
    }

    for (QueryDocumentSnapshot doc in snapshot.docs) {
      var deviceToken = doc.get('token-value');

      final Map<String, dynamic> message = {
        'message': {
          'token': deviceToken,
          'notification': {
            'title': "$action!",
            'body': "$userName $action at $location on $formattedTimestamp!",
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
        print("Notification sent successfully to token: $deviceToken");
      } else {
        print("Failed to send notification to token $deviceToken: ${response.body}");
      }
    }
  } catch (e) {
    print("Error fetching device tokens: $e");
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
      var notification_action = ""; 
      if(action=="checkin")
      {
        notification_action = "Checked In"; 
      }
      else 
      {
        notification_action = "Checked Out";
      }
      sendNotification(user.email!, notification_action, position.latitude, position.longitude, DateTime.now());
    } catch (e) { 
      print("Error saving $action data: $e");
    }
  }

  Future<void> saveRegisteredData(String name, String email, String phoneNumber) async {
  try {
    // Reference to the user's document in Firestore
    DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(email);

    // Ensure 'user-details' exists and is not overwritten
    var userDetailsDoc = await userDoc.collection('user-details').doc('details').get();
    
    // If 'user-details' doesn't exist, save it
    if (!userDetailsDoc.exists) {
      await userDoc.collection('user-details').doc('details').set({
        'name': name,
        'email': email,
        'phone_number': phoneNumber,
        'created_at': FieldValue.serverTimestamp(),
      });
      print("User details saved successfully for $email.");
    } else {
      print("User details already exist for $email.");
    }
  } catch (e) {
    print("Error saving user details for $email: $e");
  }
}

 Future<void> checkSuspiciousCheckout(Position checkoutPosition, DateTime checkoutTimestamp) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      print('Suspicious Checkout Called'); 
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.email);
      QuerySnapshot snapshot = await userDoc
          .collection('timestamps')
          .where('action', isEqualTo: 'checkin')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var latestCheckIn = snapshot.docs.first;
        double checkInLat = latestCheckIn['latitude'];
        double checkInLng = latestCheckIn['longitude'];
        Timestamp checkInTimestamp = latestCheckIn['timestamp'];

        double distance = _calculateDistance(
          checkInLat,
          checkInLng,
          checkoutPosition.latitude,
          checkoutPosition.longitude,
        );

        Duration timeDifference = checkoutTimestamp.difference(checkInTimestamp.toDate());
        double timeDifferenceHours = timeDifference.inHours.toDouble();

        Map<String, dynamic> suspiciousData = {
          'checkInLat': checkInLat,
          'checkInLng': checkInLng,
          'checkoutLat': checkoutPosition.latitude,
          'checkoutLng': checkoutPosition.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'distance': distance,
          'timeDifferenceHours': timeDifferenceHours,
        };

        if (distance > 2.0) {
          suspiciousData['geofence_broken'] = true;
        }

        if (timeDifferenceHours > 4.0) {
          suspiciousData['time_bound_broken'] = true;
        }

        if (suspiciousData.containsKey('geofence_broken') || suspiciousData.containsKey('time_bound_broken')) {
          String formattedTimestamp = DateFormat('yyyy-MM-dd-HH:mm').format(checkoutTimestamp);
          await userDoc.collection('suspiciousCheckouts').doc(formattedTimestamp).set(suspiciousData);
          print("Suspicious checkout recorded: $suspiciousData");
        }
        else { 
          print('Not a suspicious checkout, universe is fine'); 
        }
      }
    } catch (e) {
      print("Error checking suspicious checkout: $e");
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371.0;
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }


Future<String?> getNameFromFirestore(String email) async {
  try {
    // Get the user document from Firestore using the provided email
    DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(email);
    DocumentSnapshot snapshot = await userDoc.collection('user-details').doc('details').get();

    print("Document exists: ${snapshot.exists}"); // Check if the document exists

    // Check if the document exists
    if (snapshot.exists) {
      // Retrieve the name field from the document
      String name = snapshot['name'];
      print("The name is: $name"); // Print the name for debugging
      return name; // Return the name
    } else {
      print("User details not found for email: $email");
      return null; // Return null if the document does not exist
    }
  } catch (e) {
    print("Error fetching user name for email $email: $e");
    return null; // Return null if there was an error
  }
}

static Future<String?> getPhoneNumberFromFirestore(String email) async {
  try {
    // Get the user document from Firestore using the provided email
    DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(email);
    DocumentSnapshot snapshot = await userDoc.collection('user-details').doc('details').get();

    print("Document exists: ${snapshot.exists}"); // Check if the document exists

    // Check if the document exists
    if (snapshot.exists) {
      // Retrieve the phone number field from the document
      String phoneNumber = snapshot['phone_number'];
      print("The phone number is: $phoneNumber"); // Print the phone number for debugging
      return phoneNumber; // Return the phone number
    } else {
      print("User details not found for email: $email");
      return null; // Return null if the document does not exist
    }
  } catch (e) {
    print("Error fetching phone number for email $email: $e");
    return null; // Return null if there was an error
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
