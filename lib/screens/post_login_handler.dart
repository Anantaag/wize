import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/bottom_nav.dart';

class PostLoginHandler extends StatefulWidget {
  @override
  _PostLoginHandlerState createState() => _PostLoginHandlerState();
}

class _PostLoginHandlerState extends State<PostLoginHandler> {
  @override
  void initState() {
    super.initState();
    requestPermissionsAndNavigate();
  }
Future<void> requestPermissionsAndNavigate() async {
  print("🔁 Requesting permissions...");
  
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.camera,
    Permission.microphone,
    Permission.contacts,
  ].request();

  statuses.forEach((permission, status) {
    print("🔍 $permission = $status");
  });

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => BottomNavBar()),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()), // optional loading
    );
  }
}