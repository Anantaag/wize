import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class ThemeProvider with ChangeNotifier {
  bool isDarkMode = false;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  File? _image;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _notificationsEnabled = true;

  Map<Permission, bool> _permissionStatuses = {};

  @override
  void initState() {
    super.initState();
    loadUserProfile();
    loadSettingsFromFirestore(); // ✅ Load user settings
    checkPermissions();
  }

  Future<void> loadUserProfile() async {
    nameController.text = user.displayName ?? "";
    emailController.text = user.email ?? "";

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        nameController.text = data['name'] ?? user.displayName ?? '';
      });
    }
  }

  Future<void> loadSettingsFromFirestore() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data()?['settings'] != null) {
      final settings = doc.data()!['settings'];
      setState(() {
        _notificationsEnabled = settings['notifications'] ?? true;
      });
      final isDark = settings['theme'] ?? false;
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      if (isDark != themeProvider.isDarkMode) {
        themeProvider.toggleTheme();
      }
    }
  }

  Future<void> syncSettingsToFirestore() async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'settings': {
        'notifications': _notificationsEnabled,
        'theme': Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
      }
    }, SetOptions(merge: true));
  }

  Future<void> checkPermissions() async {
    final permissions = [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.contacts,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();
    setState(() {
      for (var permission in permissions) {
        _permissionStatuses[permission] = statuses[permission]?.isGranted ?? false;
      }
    });

    await syncPermissionsToFirestore();
  }

  Future<void> syncPermissionsToFirestore() async {
    final permissionData = {
      'location': _permissionStatuses[Permission.location] ?? false,
      'camera': _permissionStatuses[Permission.camera] ?? false,
      'microphone': _permissionStatuses[Permission.microphone] ?? false,
      'contacts': _permissionStatuses[Permission.contacts] ?? false,
    };

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'permissions': permissionData
    }, SetOptions(merge: true));
  }

  Future<void> _handlePermissionToggle(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('To disable this permission, open app settings.'),
          action: SnackBarAction(
            label: "Settings",
            onPressed: openAppSettings,
          ),
        ),
      );
      return;
    }

    final newStatus = await permission.request();
    setState(() {
      _permissionStatuses[permission] = newStatus.isGranted;
    });

    if (newStatus.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Permission permanently denied. Open settings to enable."),
          action: SnackBarAction(
            label: "Open Settings",
            onPressed: openAppSettings,
          ),
        ),
      );
    }

    await syncPermissionsToFirestore();
  }

  Widget _buildPermissionSwitch(Permission permission, String label) {
    bool isGranted = _permissionStatuses[permission] ?? false;
    return ListTile(
      title: Text(label),
      subtitle: Text(
        isGranted ? 'Granted ✅' : 'Denied ❌',
        style: TextStyle(
          color: isGranted ? Colors.green : Colors.red,
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: isGranted,
        onChanged: (_) {
          if (isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("To disable this permission, open app settings."),
                action: SnackBarAction(
                  label: "Settings",
                  onPressed: openAppSettings,
                ),
              ),
            );
          } else {
            _handlePermissionToggle(permission);
          }
        },
      ),
    );
  }

  Future<void> saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await user.updateDisplayName(nameController.text);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': nameController.text,
        'email': user.email,
      }, SetOptions(merge: true));
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile updated!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update profile: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> changeEmail(String newEmail, String password) async {
    try {
      final credential = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);
      await user.updateEmail(newEmail);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'email': newEmail});
      setState(() => emailController.text = newEmail);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Email updated!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  void showChangeEmailDialog() {
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change Email"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: newEmailController, decoration: InputDecoration(labelText: "New Email")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await changeEmail(newEmailController.text.trim(), passwordController.text.trim());
            },
            child: Text("Update"),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          GestureDetector(
            onTap: _isEditing ? pickImage : null,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _image != null ? FileImage(_image!) : null,
              child: _image == null ? Icon(Icons.person, size: 50) : null,
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: nameController,
            enabled: _isEditing,
            decoration: InputDecoration(labelText: "Name"),
          ),
          SizedBox(height: 10),
          TextField(
            controller: emailController,
            enabled: false,
            decoration: InputDecoration(
              labelText: "Email",
              suffixIcon: IconButton(
                icon: Icon(Icons.edit),
                onPressed: showChangeEmailDialog,
              ),
            ),
          ),
          SizedBox(height: 20),
          if (_isEditing)
            ElevatedButton(
              onPressed: _isSaving ? null : saveProfile,
              child: _isSaving ? CircularProgressIndicator() : Text("Save Changes"),
            ),
          Divider(height: 40),
          Text("App Settings", style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            title: Text("Enable Notifications"),
            value: _notificationsEnabled,
            onChanged: (val) async {
              setState(() => _notificationsEnabled = val);
              await syncSettingsToFirestore(); // ✅ update
            },
          ),
          SwitchListTile(
            title: Text("Dark Mode"),
            value: themeProvider.isDarkMode,
            onChanged: (val) async {
              themeProvider.toggleTheme();
              await syncSettingsToFirestore(); // ✅ update
            },
          ),
          Divider(height: 40),
          Text("Privacy Settings", style: Theme.of(context).textTheme.titleLarge),
          _buildPermissionSwitch(Permission.location, "Location Access"),
          _buildPermissionSwitch(Permission.camera, "Camera Access"),
          _buildPermissionSwitch(Permission.microphone, "Microphone Access"),
          _buildPermissionSwitch(Permission.contacts, "Contacts Access"),
          SizedBox(height: 10),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text("Refresh Permissions"),
            onPressed: checkPermissions,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.logout),
            label: Text("Logout"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: _confirmLogout,
          ),
        ],
      ),
    );
  }
}