import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
