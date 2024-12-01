import 'package:flutter/material.dart';

class AdminGeofencing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Geofencing Updates'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Text('Hi, this is for geofencing updates.',
            style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
