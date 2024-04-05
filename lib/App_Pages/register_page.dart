import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/UI_components/button.dart';
import 'package:flutter_application_1/UI_components/textbox.dart';
import 'package:flutter_application_1/Helper_Functions/helper_methods.dart';

/// This class is for the register page
class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers for the textboxes
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  // Register the User
  void registerUser() async {
    // Show loading circle
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Make sure the passwords match
    if (passwordController.text != confirmPwController.text) {
      // pop loading circle
      Navigator.pop(context);

      // Show error message to user
      displayMessageToUser("Passwords do not match", context);
    }
    
    // If the passwords do match, try creating a user
    else{
      // Create the user in firebase with their email and password
      try{
        UserCredential? userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text, 
          password: passwordController.text
        );

        // Create profile in realtime database using 
        final DatabaseReference ref = FirebaseDatabase.instance.ref();
        final newRef = ref.child('users').push();
        await newRef.set({
          "name": "Booth User", //<-- For debugging, change this 
          "uid": userCredential.user?.uid
        });

        // pop loading circle
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        // pop loading circle
        Navigator.pop(context);
        //display error message to user
        displayMessageToUser(e.code, context);
      }
    }


  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This changes the color of the page to match which mode is selected (light/dark)
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // This is where the logo is to be displayed - for now, an icon of a person
              Icon(
                Icons.person,
                size: 80,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),

              // Creates a space between the logo and the app name
              const SizedBox(height: 25),
              
              const Text(
                "BOOTH",
                style: TextStyle(fontSize: 20),
              ),

              const SizedBox(height: 50),

              // Username textfield
              TextBox(
                hintText: "Username",
                obscureText: false,
                controller: usernameController,
              ),

              const SizedBox(height: 10),

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

              // Confirm password textfield
              TextBox(
                hintText: "Confirm Password",
                obscureText: true,
                controller: confirmPwController,
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

              // Register button
              Button(
                text: "Register", 
                onTap: registerUser,
              ),

              const SizedBox(height: 25),

              // Login here
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: const Text(
                      "Login Here", 
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
