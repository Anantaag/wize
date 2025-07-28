import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wize_app/screens/contact_form_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    requestPermissions(); // ✅ Request permissions at start
  }

  Future<void> requestPermissions() async {
    await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.contacts,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wize'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              child: Text('Setup Emergency Contact'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactFormScreen()),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('🚨 Send SOS Alert'),
              onPressed: () async {
                try {
                  // Get current location
                  Position position = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high,
                  );

                  // Store SOS alert in Firestore
                  await FirebaseFirestore.instance.collection('sos_alerts').add({
                    'triggered_at': Timestamp.now(),
                    'status': 'pending',
                    'message': 'User has triggered an SOS alert!',
                    'latitude': position.latitude,
                    'longitude': position.longitude,
                  });

                  // Show local notification
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

                  // Fetch emergency contacts
                  final contactsSnapshot = await FirebaseFirestore.instance
                      .collection('emergency_contacts')
                      .orderBy('timestamp', descending: true)
                      .limit(1)
                      .get();

                  if (contactsSnapshot.docs.isNotEmpty) {
                    final data = contactsSnapshot.docs.first.data();
                    final List<String> recipients = [
                      data['primary_contact'],
                      data['alternate_contact']
                    ];

                    final message =
                        "🚨 SOS! I need help. My location: https://maps.google.com/?q=${position.latitude},${position.longitude}";

                    await sendSMS(message: message, recipients: recipients, sendDirect: false);

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
              },
            ),
          ],
        ),
      ),
    );
  }
}