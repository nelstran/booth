import 'package:Booth/MVC/biometric_helper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:Booth/UI_components/textbox.dart';
import 'package:Booth/Helper_Functions/helper_methods.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Page for users to login to Booth using Firebase Authentication,
/// users can forget password or navigate to the register page
class LoginPage extends StatefulWidget {
  final void Function()? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for the textfields (these store what the user has typed)
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final BiometricAuthHelper biometricHelper = BiometricAuthHelper();
  bool isEmailEmpty = true;
  bool isPassEmpty = true;
  bool triedToLogin = false;
  bool isBiometricEnabled = false;
  bool isInitialBiometricCheckDone = false;  // New flag to track initial check

  @override
  void initState() {
    super.initState();
    // Only check preference, don't authenticate automatically
    checkBiometricPreference();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    passwordController.addListener(enableButton);
    emailController.addListener(enableButton);

    return Scaffold(
      // This changes the color of the page to match which mode is selected (light/dark)
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          reverse: true,
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/lamp_logo.png',
                width: 100,
                height: 100,
              ),
              // Creates a space between the logo and the app name
              const SizedBox(height: 15),
              const Text(
                "BOOTH",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              // Email textfield
              TextBox(
                hintText: "Email",
                obscureText: false,
                controller: emailController,
              ),
              // Email error message
              if (isEmailEmpty && triedToLogin)
                const Padding(
                  padding: EdgeInsets.only(left: 15, top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.error, size: 20, color: Colors.red),
                      Text(
                        "Enter an email",
                        style: TextStyle(color: Colors.red)
                      )
                    ]
                  ),
                ),
              const SizedBox(height: 12),

              // Password textfield
              TextBox(
                hintText: "Password",
                obscureText: true,
                controller: passwordController,
              ),
              const SizedBox(height: 5),

              // Password error and Forgot password row
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (isPassEmpty && triedToLogin)
                    const Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: Row(
                        children: [
                          Icon(Icons.error, size: 20, color: Colors.red),
                          Text(
                            "Enter a password",
                            style: TextStyle(color: Colors.red)
                          )
                        ]
                      ),
                    ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _forgotPassword,
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              // Login button
              SizedBox(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    ),
                    backgroundColor: isEmailEmpty || isPassEmpty
                      ? Colors.grey[800]
                      : const Color.fromARGB(255, 28, 125, 204)
                  ),
                  onPressed: () => login(isAutoLogin: false),
                  child: const Text("Login"),
                ),
              ),

              const SizedBox(height: 15),

              // Biometric login button
              if (isBiometricEnabled) buildBiometricButton(),
              const SizedBox(height: 15),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: const Text(
                      "Register Here",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBiometricButton() {
    return FutureBuilder(
      future: biometricHelper.checkBiometricPrivacyStatus(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return IconButton(
            icon: const Icon(Icons.fingerprint),
            iconSize: 40,
            onPressed: authenticateBiometric,
            tooltip: 'Use biometric login',
          );
        } else if (snapshot.hasData && snapshot.data == false) {
          return TextButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Enable Biometric Login in Settings'),
            onPressed: () {
              openAppSettings();
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
  
  /// Method to check if user enabled biometric login
  Future<void> checkBiometricPreference() async {
    if (isInitialBiometricCheckDone) return;  // Prevent multiple checks
    
    final prefs = await SharedPreferences.getInstance();
    final bool isEnabled = prefs.getBool('isBiometricEnabled') ?? false;
    final isAvailable = await biometricHelper.isBiometricsAvailable();
    
    isBiometricEnabled = isEnabled && isAvailable;
    isInitialBiometricCheckDone = true;
  }

  /// Method to login the user 
  Future<void> login({bool isAutoLogin = false}) async {
    setState(() {
      triedToLogin = true;
    });
    if (isEmailEmpty || isPassEmpty) {
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text);

      // Navigate to the session page after successful login
      // Clear all routes and push SessionPage route

      if (!mounted) return;
      // Store credentials for biometric login if this was a manual login
      if (!isAutoLogin && isBiometricEnabled) {
        await biometricHelper.saveCredentials(
          emailController.text.trim(),
          passwordController.text,
        );
      }
      Navigator.pushNamedAndRemoveUntil(
        context, '/main_ui_page',
        (_) => false, // This clears all routes in the stack
      );
    } on FirebaseAuthException catch (e) {
      String message = e.code;
      switch (e.code) {
        case 'invalid-email':
        case 'invalid-credential':
          message = "Email or password is incorrect";
          break;
      }
      if (!isAutoLogin && mounted) {
        displayMessageToUser(message, context);
      }
    }
  }

  /// Method to login via Biometrics,
  Future<void> authenticateBiometric() async {
    if (!isBiometricEnabled) return;

    final result = await biometricHelper.authenticateWithBiometrics();
    
    if (result.success && result.credentials != null) {
      setState(() {
        emailController.text = result.credentials!.email;
        passwordController.text = result.credentials!.password;
        isEmailEmpty = false;
        isPassEmpty = false;
      });
      
      await login(isAutoLogin: true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Authentication failed')),
      );
    }
  }

  /// This method lights up the login button when users input both password and email
  void enableButton() {
    setState(() {
      isEmailEmpty = emailController.text.isEmpty;
      isPassEmpty = passwordController.text.isEmpty;
      if (!isPassEmpty && !isEmailEmpty) {
        triedToLogin = false;
      }
    });
  }
  /// Method to ask for email for Firebase to send a password reset email to.
  Future<void> _forgotPassword() async {
    TextEditingController emailController = TextEditingController();

    await showDialog(
      context: context, 
      builder: (context){
        return AlertDialog(
            title: const Text('Forgot password?'),
            content: TextField(
              controller: emailController,
              decoration: const InputDecoration(hintText: "Email"),
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
                  try{
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text);
                    await noticeDialog("Success", "If account exists, an email will be sent to reset your password");
                    if(!context.mounted) return;
                    Navigator.of(context).pop();
                  }
                  on FirebaseAuthException catch(e){
                    await noticeDialog("Error", e.message ?? e.code);
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
        );
      }
    );
  }

  /// Helper method to display a dialog with a message
  Future<void> noticeDialog(String title, String content){
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
      }
    );
  }
}
