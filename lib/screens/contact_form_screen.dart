import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
