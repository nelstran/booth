import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  bool isEmailEmpty = true;
  bool isPassEmpty = true;
  bool triedToLogin = false;

  // This method logs a user in 
  void login() async {
    // // This shows a loading circle
    // showDialog(
    //   context: context, 
    //   builder: (context) => const Center(
    //     child: CircularProgressIndicator(),
    //   ),
    // );
    setState((){
      triedToLogin = true;
    }
    );
    if(isEmailEmpty || isPassEmpty){
      return;
    }

    // Try to sign the user in with the credentials they have typed
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailController.text, password: passwordController.text);

      // Navigate to the session page after successful login
      // Clear all routes and push SessionPage route
      
      if(!mounted) return;
      // Navigator.of(context).pop;
      Navigator.pushNamedAndRemoveUntil(
        context, '/main_ui_page',
        (_) => false, // This clears all routes in the stack
      );

      // pop loading circle
      // if (context.mounted) Navigator.pop(context); // Had to comment this out otherwise black screen when logging in
    }

    // Display any errors
    on FirebaseAuthException catch (e) {
      // pop loading circle
      // Navigator.pop(context);
      // Show an error message to the user if error encountered
      String message = e.code;
      switch(e.code){
        case 'invalid-email':
        case 'invalid-credential':
          message = "Email or password is incorrect";
          break;
      }
      displayMessageToUser(message, context);
    }
  }

  void enableButton(){
    setState((){
      isEmailEmpty = emailController.text.isEmpty;
      isPassEmpty = passwordController.text.isEmpty;
      if(!isPassEmpty && !isEmailEmpty){
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
          reverse:true,
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              isEmailEmpty && triedToLogin ? 
                const Padding(
                  padding: EdgeInsets.only(left: 15, top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error,
                        size: 20,
                        color: Colors.red),
                      Text(
                        "Enter an email",
                        style:TextStyle(
                          color: Colors.red
                        ))
                    ]
                  ),
                )
                : const SizedBox.shrink(),
              const SizedBox(height: 12),

              // Password textfield
              TextBox(
                hintText: "Password",
                obscureText: true,
                controller: passwordController,
              ),
              const SizedBox(height: 5),

              // Forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  isPassEmpty && triedToLogin ? 
                  const Padding(
                    padding: EdgeInsets.only(left: 15),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error,
                          size: 20,
                          color: Colors.red),
                        Text(
                          "Enter a password",
                          style:TextStyle(
                            color: Colors.red
                          ))
                      ]
                    ),
                  )
                  : const SizedBox.shrink(),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Forgot Password?",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary),
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
                    backgroundColor: 
                    isEmailEmpty || isPassEmpty ? 
                    Colors.grey[800]
                    : const Color.fromARGB(255, 28, 125, 204)
                  ),
                  onPressed: login,
                  child: const Text("Login"),
                ),
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
                  // 
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
