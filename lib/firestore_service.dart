import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to save check-in data
  Future<void> saveCheckIn(Position position) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.email);
      String formattedTimestamp = DateFormat('yyyy-MM-dd-HH:mm').format(DateTime.now());

      await userDoc.collection('checkinhistory').doc(formattedTimestamp).set({
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'action': 'checkin',
      });
    } catch (e) {
      print("Error saving check-in: $e");
    }
  }

  // Function to save checkout data
  Future<void> saveCheckout(Position position) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.email);
      String formattedTimestamp = DateFormat('yyyy-MM-dd-HH:mm').format(DateTime.now());

      await userDoc.collection('checkouthistory').doc(formattedTimestamp).set({
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'action': 'checkout',
      });
    } catch (e) {
      print("Error saving checkout: $e");
    }
  }
}
