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
    // Load the biometric preference when the page initializes
    loadBiometricPreference();
  }

  Future<void> loadBiometricPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Check both SharedPreferences and secure storage
      final bool prefsEnabled = prefs.getBool('isBiometricEnabled') ?? false;
      final String? storedEmail = await storage.read(key: 'biometric_user_email');
      final String? storedPassword = await storage.read(key: 'biometric_user_password');
      
      // Only consider biometric as enabled if we have both the preference and stored credentials
      final bool isActuallyEnabled = prefsEnabled && storedEmail != null && storedPassword != null;
      
      if (mounted) {
        setState(() {
          isBiometricEnabled = isActuallyEnabled;
        });
        
        // Sync the SharedPreferences with actual state if they're out of sync
        if (prefsEnabled != isActuallyEnabled) {
          await prefs.setBool('isBiometricEnabled', isActuallyEnabled);
        }
      }
    } catch (e) {
      debugPrint("Error loading biometric preference: $e");
      // Handle any potential errors during loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading biometric settings')),
        );
      }
    }
  }

  Future<void> saveBiometricPreference(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    if (isEnabled) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enable Biometric Authentication'),
            content: const Text('By enabling biometric authentication, you can use your fingerprint/face to sign in. Make sure you are on a trusted device, and no one else has access to your biometric data.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        final currentUserEmail = widget.user.email;
        if (currentUserEmail != null) {
          final String? password = await showPasswordConfirmationDialog();
          if (password != null) {
            try {
              // Verify the password before saving
              final credential = EmailAuthProvider.credential(
                email: currentUserEmail,
                password: password,
              );
              await widget.user.reauthenticateWithCredential(credential);
              
              // Save credentials in secure storage
              await storage.write(key: 'biometric_user_email', value: currentUserEmail);
              await storage.write(key: 'biometric_user_password', value: password);
              
              // Update state and SharedPreferences
              if (mounted) {
                setState(() {
                  isBiometricEnabled = true;
                });
                await prefs.setBool('isBiometricEnabled', true);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Biometric login enabled successfully')),
                );
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  isBiometricEnabled = false;
                });
                await prefs.setBool('isBiometricEnabled', false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid password. Biometric login not enabled.')),
                );
              }
            }
          } else {
            // User cancelled password input
            if (mounted) {
              setState(() {
                isBiometricEnabled = false;
              });
              await prefs.setBool('isBiometricEnabled', false);
            }
          }
        }
      } else {
        // User cancelled the confirmation dialog
        if (mounted) {
          setState(() {
            isBiometricEnabled = false;
          });
          await prefs.setBool('isBiometricEnabled', false);
        }
      }
    } else {
      // Disabling biometric authentication
      await storage.delete(key: 'biometric_user_email');
      await storage.delete(key: 'biometric_user_password');
      if (mounted) {
        setState(() {
          isBiometricEnabled = false;
        });
        await prefs.setBool('isBiometricEnabled', false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric login disabled')),
        );
      }
    }
  }

  Future<String?> showPasswordConfirmationDialog() async {
    final TextEditingController passwordController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your current password to enable biometric authentication:'),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Enter password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(passwordController.text),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
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
