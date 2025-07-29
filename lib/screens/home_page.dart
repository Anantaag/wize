import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wize_app/screens/contact_form_screen.dart';
import 'package:wize_app/screens/email_setup_screen.dart'; // ✅ Add this import

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.contacts,
    ].request();
  }

  Future<void> sendSosAlert() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await FirebaseFirestore.instance.collection('sos_alerts').add({
        'triggered_at': Timestamp.now(),
        'status': 'pending',
        'message': 'User has triggered an SOS alert!',
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      await flutterLocalNotificationsPlugin.show(
        0,
        '🚨 SOS Alert Triggered!',
        'Help has been requested!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sos_channel',
            'SOS Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );

      final contactsSnapshot = await FirebaseFirestore.instance
          .collection('emergency_contacts')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (contactsSnapshot.docs.isNotEmpty) {
        final data = contactsSnapshot.docs.first.data();
        final List<String> recipients = [
          data['primary_contact'],
          data['alternate_contact'],
        ];

        final message =
            "🚨 SOS! I need help. My location: https://maps.google.com/?q=${position.latitude},${position.longitude}";

        await sendSMS(
          message: message,
          recipients: recipients,
          sendDirect: false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🚨 SOS sent with location & SMS!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No emergency contact found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending SOS: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Wize'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Spacer(flex: 2),
          Text(
            'PRESS THIS BUTTON IN CASE OF EMERGENCY',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: sendSosAlert,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.redAccent.shade700, Colors.red],
                  center: Alignment(-0.3, -0.3),
                  radius: 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    offset: Offset(0, 8),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: 6,
                ),
              ),
              child: Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          Spacer(flex: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactFormScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: StadiumBorder(),
                elevation: 6,
              ),
              child: Text(
                'Setup Emergency Contact',
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EmailSetupScreen()), // ✅ Navigate to email setup
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: StadiumBorder(),
                elevation: 6,
              ),
              child: Text(
                'Setup Emergency Email',
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
          ),
        ],
      ),
    );
  }
}