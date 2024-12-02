import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_register.dart';
import 'home_page.dart';
import 'admin_dashboard.dart'; // Make sure to create this file
import 'location_setting_monitor.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:http/http.dart' as http; 
// import 'package:googleapis_auth/auth_io.dart' as auth;
// import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;  
// import 'dart:convert'; 
// import 'package:flutter/services.dart' show rootBundle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
  await Permission.locationWhenInUse.request(); 
  await Permission.locationAlways.request(); 
  await Permission.location.request(); 
  await Permission.notification.request();
  // await sendNotification(); 
}

// //Function to Get Notification Access Token
// Future<String> getServerToken() async {
//   // Read the JSON file securely
//   final jsonString = await rootBundle.loadString('assets/fcm_access_token/service_token.json');
//   final serviceAccountJson = jsonDecode(jsonString);

//   List<String> scopes = [
//     "https://www.googleapis.com/auth/firebase.messaging"
//   ];

//   // Create an HTTP client
//   http.Client client = await auth.clientViaServiceAccount(
//     auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
//     scopes,
//   );

//   // Obtain access credentials
//   auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount(
//     auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
//     scopes,
//     client,
//   );

//   client.close();

//   // Return the access token
//   return credentials.accessToken.data;
// }

// //Function to send Notification
// sendNotification() async
// {
//     var deviceToken = "e4AmFTEASL6yid_ha__lqd:APA91bE0NttTwBV6expXSRwUWAxHbhPZcxQxqT6lEYa5T9YyPQ6w6h26eWnuKLi85xFs4ujTaVhKuCCcXqD1P7a4I9S-Hreqd0yIU2d1jynrJI5LVA5LQIM"; 
//     final String serverKey = await getServerToken(); 
//     String endpoint = "https://fcm.googleapis.com/v1/projects/employee-app-1fd50/messages:send"; 
//     final Map<String, dynamic> message = {
//       'message': 
//       {
//         'token': deviceToken, 
//         'notification': {
//           'title': "Hey!", 
//           'body': "Welcome to the notification"
//         }
         
//       }
//     }; 
//     final http.Response response = await http.post(
//       Uri.parse(endpoint), 
//       headers: <String, String> {
//         'Content-Type': "application/json", 
//         'Authorization': 'Bearer $serverKey'
//       }, 
//       body: jsonEncode(message), 
//     ); 
 
//  if(response.statusCode == 200)
//  {
//   print("Notification sent successfully"); 
//  }
//  else 
//  {
//   print("Can't");
//  }

// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Tracking Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LocationMonitor(
        child: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String adminEmail = 'admin@admin.com';

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Check if the current user's email is admin@admin.com
          final User currentUser = snapshot.data!;
          if (currentUser.email?.toLowerCase() == adminEmail.toLowerCase()) {
            return const AdminDashboard();
          }
          return const HomePage();
        }
        return const LoginRegister();
      },
    );
  }
}