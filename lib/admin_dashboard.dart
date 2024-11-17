import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // Function to fetch everything inside the user's document (including subcollections)
  Future<void> fetchUserDataAndSubcollections(String email) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Reference to the user's main document
      final userDocRef = firestore.collection('users').doc(email);

      // Fetch the user's main document (general data)
      userDocRef.get().then((DocumentSnapshot userDoc) {
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          print('User Data: $userData');
        } else {
          print('No user found with that email.');
        }
      });

      // Fetch the user's check-in history
      final checkInHistoryRef = firestore
          .collection('users')           // users collection
          .doc(email)                    // user document (based on email)
          .collection('checkinhistory');  // sub-collection 'checkinhistory'

      final checkInSnapshot = await checkInHistoryRef.get();
      if (checkInSnapshot.docs.isEmpty) {
        print('No check-in history found for this user.');
      } else {
        checkInSnapshot.docs.forEach((doc) {
          final checkInData = doc.data() as Map<String, dynamic>;
          print('Check-in History Data: $checkInData');
        });
      }

      // Manually fetching all other subcollections, if they exist
      await _fetchSubcollections(userDocRef);
      
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  // Manually fetch subcollections by checking known collections
  Future<void> _fetchSubcollections(DocumentReference userDocRef) async {
    try {
      // Known subcollection names to check
      final subcollectionNames = ['checkinhistory', 'otherSubCollection']; // add more subcollections here

      for (var collectionName in subcollectionNames) {
        final subcollectionRef = userDocRef.collection(collectionName);
        final subcollectionSnapshot = await subcollectionRef.get();

        if (subcollectionSnapshot.docs.isEmpty) {
          print('No documents found in subcollection $collectionName.');
        } else {
          subcollectionSnapshot.docs.forEach((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('Data from subcollection $collectionName: $data');
          });
        }
      }
    } catch (e) {
      print('Error fetching subcollections: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'ADMIN DASHBOARD',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Example email to fetch all data for the user
                fetchUserDataAndSubcollections('rahul@gmail.com');
              },
              child: const Text('Fetch User Data and Subcollections'),
            ),
          ],
        ),
      ),
    );
  }
}
