import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'contact_form_screen.dart';
import 'email_setup_screen.dart';

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
    _initializeNotifications();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.location,
      Permission.sms,
      Permission.contacts,
    ].request();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> sendSosAlert() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final String mapLink =
          'https://maps.google.com/?q=${position.latitude},${position.longitude}';

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

      // Send SMS
      final contactsSnapshot = await FirebaseFirestore.instance
          .collection('emergency_contacts')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (contactsSnapshot.docs.isNotEmpty) {
        final contact = contactsSnapshot.docs.first.data();
        final List<String> recipients = [
          contact['primary_contact'],
          contact['alternate_contact'],
        ];

        final smsMessage = "🚨 SOS! I need help. My location: $mapLink";

        await sendSMS(
          message: smsMessage,
          recipients: recipients,
          sendDirect: false,
        );
      }

      // Send Email
      final emailSnapshot = await FirebaseFirestore.instance
          .collection('emergency_emails')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (emailSnapshot.docs.isNotEmpty) {
        final email = emailSnapshot.docs.first.data()['email'];
        final subject = Uri.encodeComponent("🚨 SOS Alert");
        final body = Uri.encodeComponent(
            "🚨 I need help. My current location: $mapLink");

        final Uri emailLaunchUri = Uri(
          scheme: 'mailto',
          path: email,
          query: 'subject=$subject&body=$body',
        );

        await launchUrl(emailLaunchUri);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🚨 SOS sent via SMS and Email!')),
      );
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
        title: const Text('Wize'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Spacer(flex: 2),
          const Text(
            'PRESS THIS BUTTON IN CASE OF EMERGENCY',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: sendSosAlert,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.redAccent.shade700, Colors.red],
                  center: const Alignment(-0.3, -0.3),
                  radius: 0.9,
                ),
                boxShadow: const [
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
              child: const Center(
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
          const Spacer(flex: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ContactFormScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: const StadiumBorder(),
                    elevation: 6,
                  ),
                  child: const Text(
                    'Setup Emergency Contact',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => EmailSetupScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: const StadiumBorder(),
                    elevation: 6,
                  ),
                  child: const Text(
                    'Setup Emergency Email',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}