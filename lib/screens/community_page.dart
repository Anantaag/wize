import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_sms/flutter_sms.dart';

class CommunityPage extends StatefulWidget {
  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  double? latitude;
  double? longitude;
  bool notifyEmergency = false;

  final List<String> emergencyNumbers = [
    '102', // Ambulance
    '100', // Police
    '1073', // Accident Helpline (India)
    '1091', // Women Helpline
    '101', // Fire Station
    '1070', // Natural Hazard Helpline
  ];

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      try {
        final reportData = {
          'title': title,
          'description': description,
          'timestamp': Timestamp.now(),
          'latitude': latitude ?? 28.6139,
          'longitude': longitude ?? 77.2090,
          'notified': notifyEmergency,
        };

        await FirebaseFirestore.instance
            .collection('community_reports')
            .add(reportData);

        if (notifyEmergency) {
          await sendSMS(
            message:
                "🚨 Emergency Reported: $title\nLocation: https://maps.google.com/?q=${latitude ?? 28.6139},${longitude ?? 77.2090}\nDetails: $description",
            recipients: emergencyNumbers,
            sendDirect: true,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report submitted')),
        );

        _formKey.currentState!.reset();
        setState(() {
          title = '';
          description = '';
          notifyEmergency = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _fetchDummyLocation() {
    latitude = 28.6139;
    longitude = 77.2090;
  }

  @override
  void initState() {
    super.initState();
    _fetchDummyLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Community Reports')),
      body: Column(
        children: [
          // 🔹 Form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration:
                        InputDecoration(labelText: 'Report Incident'),
                    onChanged: (val) => title = val,
                    validator: (val) =>
                        val!.isEmpty ? 'Enter a report title' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: 'Description (optional)'),
                    maxLines: 3,
                    onChanged: (val) => description = val,
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: notifyEmergency,
                        onChanged: (value) {
                          setState(() {
                            notifyEmergency = value!;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                            'Send report to emergency helplines (ambulance, police, fire, etc.)'),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _submitReport,
                    child: Text('Submit Report'),
                  ),
                ],
              ),
            ),
          ),

          // 🔹 Map View
          Container(
            height: 220,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_reports')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                final reports = snapshot.data!.docs;

                return FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(28.6139, 77.2090),
                    initialZoom: 12.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.wize_app',
                    ),
                    MarkerLayer(
                      markers: reports.map((report) {
                        final lat = report['latitude'] ?? 28.6139;
                        final lon = report['longitude'] ?? 77.2090;
                        return Marker(
                          width: 30.0,
                          height: 30.0,
                          point: LatLng(lat, lon),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 30,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),

          Divider(),

          // 🔹 Feed
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_reports')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                final reports = snapshot.data!.docs;

                if (reports.isEmpty) {
                  return Center(child: Text('No reports yet.'));
                }

                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return ListTile(
                      leading: Icon(Icons.report, color: Colors.orange),
                      title: Text(report['title']),
                      subtitle: Text(report['description'] ?? 'No details'),
                      trailing: Text(
                        (report['timestamp'] as Timestamp)
                            .toDate()
                            .toLocal()
                            .toString()
                            .substring(0, 16),
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
