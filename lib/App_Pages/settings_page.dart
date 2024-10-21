import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Booth/MVC/booth_controller.dart';

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
  bool faceIdEnabled = false;
  bool locationEnabled = false;
  bool storageEnabled = false;
  bool cameraEnabled = false;

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
          title: const Text("Enable FaceID/TouchID"),
          value: faceIdEnabled,
          onChanged: (bool value) {
            setState(() {
              faceIdEnabled = value;
            });
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
