import 'package:Booth/App_Pages/biometric_helper.dart';
import 'package:Booth/App_Pages/blocked_users_page.dart';
import 'package:Booth/Helper_Functions/helper_methods.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class SettingsPage extends StatefulWidget {
  final BoothController controller;
  final User user;

  const SettingsPage({super.key, required this.controller, required this.user});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  bool isBiometricEnabled = false;
  final storage = const FlutterSecureStorage();
  final LocalAuthentication auth = LocalAuthentication();
  final biometricHelper = BiometricAuthHelper();

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
      const storage = FlutterSecureStorage();
      final String? storedEmail =
          await storage.read(key: 'biometric_user_email');
      final String? storedPassword =
          await storage.read(key: 'biometric_user_password');

      // Only consider biometric as enabled if we have both the preference and stored credentials
      final bool isActuallyEnabled =
          prefsEnabled && storedEmail != null && storedPassword != null;

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
    if (isEnabled) {
      // Check if biometrics is available on the device
      if (!await biometricHelper.isBiometricsAvailable()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Biometric authentication not available on this device')),
          );
        }
        return;
      }

      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enable Biometric Authentication'),
            content: const Text(
                'By enabling biometric authentication, you can use your fingerprint/face to sign in. Make sure you are on a trusted device, and no one else has access to your biometric data.'),
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

              // Save credentials using the helper
              final saveSuccess = await biometricHelper.saveCredentials(
                  currentUserEmail, password);

              if (mounted) {
                setState(() {
                  isBiometricEnabled = saveSuccess;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(saveSuccess
                        ? 'Biometric login enabled successfully'
                        : 'Failed to enable biometric login'),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  isBiometricEnabled = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Invalid password. Biometric login not enabled.')),
                );
              }
            }
          } else {
            // User cancelled password input
            if (mounted) {
              setState(() {
                isBiometricEnabled = false;
              });
            }
          }
        }
      } else {
        // User cancelled the confirmation dialog
        if (mounted) {
          setState(() {
            isBiometricEnabled = false;
          });
        }
      }
    } else {
      // Disabling biometric authentication using the helper
      await biometricHelper.clearCredentials();
      if (mounted) {
        setState(() {
          isBiometricEnabled = false;
        });
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
              const Text(
                  'Please enter your current password to enable biometric authentication:'),
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
              onPressed: () =>
                  Navigator.of(context).pop(passwordController.text),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> openDocument(String fileName) async {
    try {
      // Check if file exists in assets
      final ByteData data = await rootBundle.load('assets/documents/$fileName');

      // Store file in temp dir
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;
      final File tempFile = File('$tempPath/$fileName');

      // Write file to temp storage
      await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);

      // Document opens in a new page
      if (mounted) {
        String documentTitle = fileName;
        if (fileName == 'Booth_PP.pdf') {
          documentTitle = 'Privacy Policy';
        } else if (fileName == 'Booth_TOS.pdf') {
          documentTitle = 'Terms of Service';
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewerPage(
              filePath: tempFile.path,
              fileName: fileName,
              title: documentTitle,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening $fileName: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            onTap: _handleChangeEmailPress),
        ListTile(
            title: const Text("Change Password"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _handleChangePasswordPress),
      ],
    );
  }

  AlertDialog _enterCredentials(VoidCallback confirmAction) {
    TextEditingController passwordController = TextEditingController();
    String password = '';
    return AlertDialog(
      title: const Text('Enter Password'),
      content: TextField(
        controller: passwordController,
        obscureText: true,
        decoration: const InputDecoration(hintText: "Password"),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            //password = "Cancel";
            Navigator.of(context).pop();
            return;
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            password = passwordController.text;
            try {
              AuthCredential credential = EmailAuthProvider.credential(
                  email: FirebaseAuth.instance.currentUser!.email!,
                  password: password);
              await FirebaseAuth.instance.currentUser!
                  .reauthenticateWithCredential(credential);
              if (mounted) {
                Navigator.of(context).pop();
              }
              // Do action that was passed in
              confirmAction();
            } on FirebaseAuthException catch (e) {
              // Handles Firebase exceptions during reauthentication
              if (e.code == "invalid-credential") {
                await noticeDialog("Error", "Wrong Password. Try Again");
                // Handle case where the entered password is incorrect
              } else if (e.code == "wrong-password") {
                await noticeDialog("Error", "Wrong Password. Try Again");
              } else {
                await noticeDialog("Error", e.code);
              }
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  Future<void> _handleChangeEmailPress() async {
    await showDialog(
        context: context,
        builder: (context) {
          return _enterCredentials(_changeEmail);
        });
  }

  Future<void> _changeEmail() async {
    TextEditingController emailController = TextEditingController();

    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Change email'),
            content: TextField(
              controller: emailController,
              decoration: const InputDecoration(hintText: "New Email"),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigator.of(context).pop();
                  return;
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    if (emailController.text ==
                        FirebaseAuth.instance.currentUser!.email) {
                      return noticeDialog(
                          "Warning", "New email cannot be old email");
                    }
                    await FirebaseAuth.instance.currentUser!
                        .verifyBeforeUpdateEmail(emailController.text);
                    await noticeDialog("Notice",
                        "A verification has been sent to the new email address!");
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  } on FirebaseAuthException catch (e) {
                    await noticeDialog("Error", e.message ?? e.code);
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        });
  }

  Future<void> noticeDialog(String title, String content) {
    return showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(title),
                ),
              ],
            ),
            content: Text(content),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Ok"),
              )
            ],
          );
        });
  }

  Future<void> _handleChangePasswordPress() async {
    await showDialog(
        context: context,
        builder: (context) {
          return _enterCredentials(_changePassword);
        });
  }

  Future<void> _changePassword() async {
    TextEditingController passwordController = TextEditingController();
    TextEditingController confirmPwController = TextEditingController();

    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: "New Password"),
                ),
                TextField(
                  controller: confirmPwController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(hintText: "Confirm Password"),
                ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigator.of(context).pop();
                  return;
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    if (passwordController.text != confirmPwController.text) {
                      return noticeDialog(
                          "Warning", "Mismatch password. Try again.");
                    }
                    await FirebaseAuth.instance.currentUser!
                        .updatePassword(passwordController.text);
                    await noticeDialog("Notice", "Password updated!");
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  } on FirebaseAuthException catch (e) {
                    await noticeDialog("Error", e.message ?? e.code);
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        });
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
        ListTile(
          title: const Text("Blocked Users"),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BlockedUsersPage(widget.controller),
              ),
            );
          },
        ),
        ListTile(
          title: const Text("Privacy Policy"),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            openDocument('Booth_PP.pdf');
          },
        ),
        ListTile(
          title: const Text("Terms of Service"),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            openDocument('Booth_TOS.pdf');
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
            logout(widget.controller, context);
          },
          icon: const Icon(Icons.logout),
        ),
      ],
    );
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

// Document Viewer Page
class DocumentViewerPage extends StatelessWidget {
  final String filePath;
  final String fileName;
  final String title;

  const DocumentViewerPage({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: fileName.toLowerCase().endsWith('.pdf')
          ? Platform.isIOS
              ? SfPdfViewer.file(File(filePath))
              : PDFView(
                  filePath: filePath,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                  onError: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<String>(
                future: File(filePath).readAsString(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data!);
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
    );
  }
}
