import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save check-in data
  Future<void> saveCheckIn(Position position) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.email);

      // Ensure the parent user document exists
      await userDoc.set(<String, dynamic>{}, SetOptions(merge: true));

      await userDoc.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'action': 'checkin',
      });
    } catch (e) {
      print("Error saving check-in: $e");
    }
  }

  // Save checkout data
  Future<void> saveCheckout(Position position) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.email);

      // Ensure the parent user document exists
      await userDoc.set(<String, dynamic>{}, SetOptions(merge: true));

      await userDoc.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'action': 'checkout',
      });
    } catch (e) {
      print("Error saving checkout: $e");
    }
  }

  // Fetch the latest action
  Future<String> getLastAction() async {
    User? user = _auth.currentUser;
    if (user == null) return 'none';

    try {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.email);

      // Get the latest entry from the history collection
      QuerySnapshot snapshot = await userDoc
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first['action']; // Returns 'checkin' or 'checkout'
      }
    } catch (e) {
      print("Error retrieving last action: $e");
    }
    return 'none'; // Default if no actions are found
  }
}
