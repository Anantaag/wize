import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

Future<void> sendEmergencyEmail(BuildContext context, String message) async {
  try {
    final emailSnapshot = await FirebaseFirestore.instance
        .collection('emergency_emails')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (emailSnapshot.docs.isNotEmpty) {
      final email = emailSnapshot.docs.first['email'];
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query: Uri.encodeFull('subject=🚨 Emergency SOS Alert&body=$message'),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch email client';
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No emergency email found')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to send emergency email: $e')),
    );
  }
}