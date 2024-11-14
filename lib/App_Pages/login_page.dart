import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Booth/UI_components/textbox.dart';
import 'package:Booth/Helper_Functions/helper_methods.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// This class is for the login page
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
  final LocalAuthentication auth = LocalAuthentication();
  final storage = const FlutterSecureStorage();
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

  Future<void> checkBiometricPreference() async {
    if (isInitialBiometricCheckDone) return;  // Prevent multiple checks
    
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;
      isInitialBiometricCheckDone = true;
    });
  }

  void login({bool isAutoLogin = false}) async {
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
        await storage.write(
          key: 'biometric_user_email',
          value: emailController.text.trim(),
        );
        await storage.write(
          key: 'biometric_user_password',
          value: passwordController.text,
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

  Future<void> authenticateBiometric() async {
    if (!isBiometricEnabled) return;  // Early return if biometrics not enabled

    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication not available')),
          );
        }
        return;
      }

      bool authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to log in',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (authenticated && mounted) {
        final storedEmail = await storage.read(key: 'biometric_user_email');
        final storedPassword = await storage.read(key: 'biometric_user_password');

        if (storedEmail != null && storedPassword != null) {
          setState(() {
            emailController.text = storedEmail;
            passwordController.text = storedPassword;
            isEmailEmpty = false;
            isPassEmpty = false;
          });
          
          login(isAutoLogin: true);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please login once manually to enable biometric login')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Biometric authentication error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed')),
        );
      }
    }
  }

  void enableButton() {
    setState(() {
      isEmailEmpty = emailController.text.isEmpty;
      isPassEmpty = passwordController.text.isEmpty;
      if (!isPassEmpty && !isEmailEmpty) {
        triedToLogin = false;
      }
    });
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
              Image.asset('assets/images/lamp_logo.png',
                  width: 100, height: 100),
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
                        Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary
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
              if (isBiometricEnabled)
                IconButton(
                  icon: const Icon(Icons.fingerprint),
                  iconSize: 40,
                  onPressed: authenticateBiometric,
                  tooltip: 'Use biometric login',
                ),

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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
