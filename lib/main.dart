import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  runApp(WizeApp());
}

class WizeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wize',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
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
                  // Check and request location permission
                  LocationPermission permission = await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied ||
                      permission == LocationPermission.deniedForever) {
                    permission = await Geolocator.requestPermission();
                  }

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

                  // Fetch emergency contacts from Firestore
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

class ContactFormScreen extends StatefulWidget {
  @override
  _ContactFormScreenState createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String primaryContact = '';
  String alternateContact = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Contact Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Full Name'),
                onChanged: (val) => name = val,
                validator: (val) => val!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Primary Contact Number'),
                keyboardType: TextInputType.phone,
                onChanged: (val) => primaryContact = val,
                validator: (val) => val!.isEmpty ? 'Enter a phone number' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Alternate Contact Number'),
                keyboardType: TextInputType.phone,
                onChanged: (val) => alternateContact = val,
                validator: (val) => val!.isEmpty ? 'Enter alternate number' : null,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                child: Text('Save Contact Info'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await FirebaseFirestore.instance.collection('emergency_contacts').add({
                        'name': name,
                        'primary_contact': primaryContact,
                        'alternate_contact': alternateContact,
                        'timestamp': Timestamp.now(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Contact Info Saved!')),
                      );

                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
