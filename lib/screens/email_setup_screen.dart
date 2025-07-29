import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailSetupScreen extends StatefulWidget {
  @override
  _EmailSetupScreenState createState() => _EmailSetupScreenState();
}

class _EmailSetupScreenState extends State<EmailSetupScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSaving = false;
  String? _successMessage;

  Future<void> _saveEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _successMessage = null;
    });

    try {
      await FirebaseFirestore.instance.collection('emergency_emails').add({
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _successMessage = '✅ Emergency email saved successfully!';
        _emailController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving email: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Emergency Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Enter your emergency email address below:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveEmail,
              child: _isSaving
                  ? CircularProgressIndicator()
                  : Text('Save Email'),
            ),
            if (_successMessage != null) ...[
              SizedBox(height: 20),
              Text(
                _successMessage!,
                style: TextStyle(color: Colors.green),
              ),
            ]
          ],
        ),
      ),
    );
  }
}