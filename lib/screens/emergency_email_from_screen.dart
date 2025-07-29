import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyEmailFormScreen extends StatefulWidget {
  @override
  _EmergencyEmailFormScreenState createState() =>
      _EmergencyEmailFormScreenState();
}

class _EmergencyEmailFormScreenState extends State<EmergencyEmailFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  Future<void> saveEmail() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('emergency_emails').add({
        'email': _emailController.text.trim(),
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emergency email saved')),
      );

      Navigator.pop(context); // Go back to HomePage
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Emergency Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Emergency Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      !value.contains('@') ||
                      !value.contains('.')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveEmail,
                child: Text('Save Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}