import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class SettingsPage extends StatefulWidget {
  final BoothController controller;
  final User user;

  const SettingsPage({super.key, required this.controller, required this.user});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool privacyVisible = true;

  bool isBiometricEnabled = false;

  bool locationEnabled = false;
  bool storageEnabled = false;
  bool cameraEnabled = false;
  
  final storage = const FlutterSecureStorage();

  final LocalAuthentication auth = LocalAuthentication();
  
  @override
  void initState() {
    super.initState();
    loadBiometricPreference();
  }

  Future<void> loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;
  }

  Future<void> saveBiometricPreference(bool isEnabled) async {
  final prefs = await SharedPreferences.getInstance();
  
  if (isEnabled) {
    // Show a confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Biometric Authentication'),
          content: const Text('By enabling biometric authentication, you confirm that this device is yours and will be kept secure. This will allow you to log in without entering your password.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return false when canceled
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true); // Return true when confirmed
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Generate and store token only if user confirmed
      final token = generateUniqueToken();
      await storage.write(key: 'auth_token', value: token);
      
      // Store the current user's email securely
      final currentUserEmail = widget.user.email;
      if (currentUserEmail != null) {
        await storage.write(key: 'biometric_user_email', value: currentUserEmail);
      }
      
      // Update the UI state and save preference
      setState(() {
        isBiometricEnabled = true;
      });
      await prefs.setBool('isBiometricEnabled', true);
    } else {
      // If not confirmed, ensure the switch stays off
      setState(() {
        isBiometricEnabled = false;
      });
      await prefs.setBool('isBiometricEnabled', false);
    }
  } else {
    // If disabling biometric auth, clear stored credentials
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'biometric_user_email');
    setState(() {
      isBiometricEnabled = false;
    });
    await prefs.setBool('isBiometricEnabled', false);
  }
}


  String generateUniqueToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random rand = Random();

    return String.fromCharCodes(Iterable.generate(2, (_) => chars.codeUnitAt(rand.nextInt(chars.length))));
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: adminAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          buildAccountSettingsSection(),
          const Divider(),
          buildPermissionsSection(),
          const Divider(),
          buildPrivacySettingsSection(),
          const Divider(),
          buildSecuritySettingsSection(),
          const Divider(),
          const SizedBox(height: 20),
          buildDeleteAccountButton(),
        ],
      ),
    );
  }

  // Account Settings Section
  Widget buildAccountSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Account Settings",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListTile(
          title: const Text("Change Email"),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Handle email change logic
          },
        ),
        ListTile(
          title: const Text("Change Password"),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Handle password change logic
          },
        ),
      ],
    );
  }

  // Permissions Section
  Widget buildPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Permissions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          title: const Text("Allow Notifications"),
          value: notificationsEnabled,
          onChanged: (bool value) {
            setState(() {
              notificationsEnabled = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text("Allow Location"),
          value: locationEnabled,
          onChanged: (bool value) {
            setState(() {
              locationEnabled = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text("Allow Storage"),
          value: storageEnabled,
          onChanged: (bool value) {
            setState(() {
              storageEnabled = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text("Allow Camera"),
          value: cameraEnabled,
          onChanged: (bool value) {
            setState(() {
              cameraEnabled = value;
            });
          },
        ),
      ],
    );
  }

  // Privacy Settings Section
  Widget buildPrivacySettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Privacy Settings",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SwitchListTile(
          title: const Text("Profile Visible"),
          value: privacyVisible,
          onChanged: (bool value) {
            setState(() {
              privacyVisible = value;
            });
          },
        ),
        ListTile(
          title: const Text("Privacy Policy"),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Handle privacy policy logic
          },
        ),
        ListTile(
          title: const Text("Terms of Service"),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Handle terms of service logic
          },
        ),
      ],
    );
  }

  // Security Section for FaceID/TouchID
  Widget buildSecuritySettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Security",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SwitchListTile(
          title: const Text('Enable Biometric Authentication'),
          value: isBiometricEnabled,
          onChanged: (value) {
            saveBiometricPreference(value);
          },
        ),
      ],
    );
  }

  // Delete Account Button
  Widget buildDeleteAccountButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        child:
            const Text("Delete Account", style: TextStyle(color: Colors.white)),
        onPressed: () {
          deletionDialog();
        },
      ),
    );
  }

  // AppBar with Logout functionality
  AppBar adminAppBar() {
    return AppBar(
      title: const Text("Settings Page"),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            logout();
          },
          icon: const Icon(Icons.logout),
        ),
      ],
    );
  }

  // Logout method
  void logout() {
    FirebaseAuth.instance.signOut();
  }

  // Confirmation Dialog for Account Deletion
  Future<void> deletionDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Account Deletion"),
          content: const Text('''Are you sure you want to delete your account? 

This action is permanent and cannot be undone. All your data, settings, and history will be permanently deleted.'''),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: () async {
                try {
                  await widget.controller.deleteUserAccountFB(context);
                  Navigator.of(context).pop(); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Account deleted successfully.")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to delete account.")),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text("Delete My Account"),
            ),
          ],
        );
      },
    );
  }
}
