// import 'package:geolocator/geolocator.dart';
// import 'dart:async';

// class Geofencing {
//   // Variables to store the center latitude and longitude
//   double? centerLatitude;
//   double? centerLongitude;

//   // Geofencing radius in meters (700m in this case)
//   double geofenceRadius = 700;

//   // Timer for checking location every 5 seconds
//   Timer? _timer;

//   // Function to start geofencing service
//   Future<void> startGeofencing() async {
//     // Get initial location to set as the center
//     Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

//     // Set the center coordinates as user's initial location
//     centerLatitude = position.latitude;
//     centerLongitude = position.longitude;

//     // Print the initial center
//     print("Geofencing center set to: Lat: $centerLatitude, Long: $centerLongitude");

//     // Start checking the location every 5 seconds
//     _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
//       await _checkLocation();
//     });
//   }

//   // Function to get the current location
//   Future<void> _checkLocation() async {
//     // Get the current position of the user
//     Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

//     // Calculate the distance from the center to the current location
//     double distance = await _calculateDistance(
//       centerLatitude!, centerLongitude!, position.latitude, position.longitude);

//     // Print the current location and distance from center
//     print("Current Location: Lat: ${position.latitude}, Long: ${position.longitude}");
//     print("Distance from center: $distance meters");

//     // Check if the distance exceeds the geofence radius
//     if (distance > geofenceRadius) {
//       print("Geofence broken! You are more than $geofenceRadius meters away from the center.");
//     }
//   }

//   // Function to calculate the distance between two geographical points
//   Future<double> _calculateDistance(double lat1, double lon1, double lat2, double lon2) async {
//     double distanceInMeters = await Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
//     return distanceInMeters;
//   }

//   // Function to stop the geofencing service
//   void stopGeofencing() {
//     _timer?.cancel();
//   }
// }
