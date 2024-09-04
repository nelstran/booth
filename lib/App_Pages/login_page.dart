import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/UI_components/button.dart';
import 'package:flutter_application_1/UI_components/textbox.dart';
import 'package:flutter_application_1/Helper_Functions/helper_methods.dart';

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

  // This method logs a user in 
  void login() async {
    // This shows a loading circle
    showDialog(
      context: context, 
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Try to sign the user in with the credentials they have typed
    try {
      // UserCredential? userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailController.text, password: passwordController.text);

      // Navigate to the session page after successful login
      // Clear all routes and push SessionPage route
      
      if(!mounted) return;
      Navigator.pop(context);
      Navigator.pushNamedAndRemoveUntil(
        context, '/main_page',
        (_) => false, // This clears all routes in the stack
      );

      // pop loading circle
      // if (context.mounted) Navigator.pop(context); // Had to comment this out otherwise black screen when logging in
    }

    // Display any errors
    on FirebaseAuthException catch (e) {
      // pop loading circle
      Navigator.pop(context);
      // Show an error message to the user if error encountered
      displayMessageToUser(e.code, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This changes the color of the page to match which mode is selected (light/dark)
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          reverse:true,
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // This is where the logo is to be displayed - for now, an icon of a person
              // Icon(
              //   Icons.person,
              //   size: 50,
              //   color: Theme.of(context).colorScheme.inversePrimary,
              // ),

              Image.asset(
                'assets/images/lamp_logo.png',
                width: 100,
                height: 100),
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

              const SizedBox(height: 10),

              // Password textfield
              TextBox(
                hintText: "Password",
                obscureText: true,
                controller: passwordController,
              ),

              const SizedBox(height: 10),

              // Forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Forgot Password?",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              // Login button
              Button(
                text: "Login", 
                onTap: login,
              ),

              const SizedBox(height: 25),

              // Register here 
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
}
