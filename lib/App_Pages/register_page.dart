import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/institutions_page.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_application_1/MVC/student_model.dart';
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
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  bool isFirstEmpty = true;
  bool isLastEmpty = true;
  bool isEmailEmpty = true;
  bool isPassEmpty = true;
  bool doesPassMatch = false;
  bool triedToRegister = false;
  // Register the User
  void registerUser() async {
    setState((){
      triedToRegister = true;
      isFirstEmpty = firstNameController.text.isEmpty;
      isLastEmpty = lastNameController.text.isEmpty;
      isEmailEmpty = emailController.text.isEmpty;
      isPassEmpty = passwordController.text.isEmpty;
      doesPassMatch = passwordController.text == confirmPwController.text;
    });
    if(!isFirstEmpty && !isLastEmpty && !isEmailEmpty && !isPassEmpty && doesPassMatch){
      // Show loading circle
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      // Create the user in firebase with their email and password
      try {
        String emailString = emailController.text.trim();
        String pwString = passwordController.text;
        String fNameString = firstNameController.text.trim();
        String lNameString = lastNameController.text.trim();
        
        UserCredential? userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: emailString, password: pwString);
        await FirebaseAuth.instance.signOut();
        
        // Create profile in realtime database using
        final DatabaseReference ref = FirebaseDatabase.instance.ref();
        final BoothController controller = BoothController(ref);

        Student newUser = Student(
          uid: userCredential.user!.uid,
          firstName: fNameString,
          lastName: lNameString,
        );
        await controller.addUser(newUser);
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailString, 
          password: pwString
        );
        if (!mounted) return;
        Navigator.of(context).pop();
      } on FirebaseAuthException catch (e) {
        // pop loading circle
        Navigator.pop(context);
        //display error message to user
        displayMessageToUser(e.message ?? "Error unknown", context);
      }
    }
    else{
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // This is where the logo is to be displayed - for now, an icon of a person
              // Icon(
              //   Icons.person,
              //   size: 40,
              //   color: Theme.of(context).colorScheme.inversePrimary,
              // ),

              // Creates a space between the logo and the app name
              //const SizedBox(height: 15),

              const Text(
                "Create an Account",
                style: TextStyle(fontSize: 20),
              ),

              const SizedBox(height: 20),

              // First name textfield
              TextBox(
                hintText: "First Name",
                obscureText: false,
                controller: firstNameController,
              ),
              isFirstEmpty && triedToRegister ? 
                const Padding(
                  padding: EdgeInsets.only(left: 15, top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "First name cannot be empty",
                        style:TextStyle(
                          color: Colors.red
                        ))
                    ]
                  ),
                )
                : const SizedBox.shrink(),
              const SizedBox(height: 10),
              // Last name textfield
              TextBox(
                hintText: "Last Name",
                obscureText: false,
                controller: lastNameController,
              ),
              isLastEmpty && triedToRegister ? 
                const Padding(
                  padding: EdgeInsets.only(left: 15, top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Last name cannot be empty",
                        style:TextStyle(
                          color: Colors.red
                        ))
                    ]
                  ),
                )
                : const SizedBox.shrink(),
              const SizedBox(height: 10),
              // Email textfield
              TextBox(
                hintText: "Email",
                obscureText: false,
                controller: emailController,
              ),
              isEmailEmpty && triedToRegister ? 
                const Padding(
                  padding: EdgeInsets.only(left: 15, top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Email cannot be empty",
                        style:TextStyle(
                          color: Colors.red
                        ))
                    ]
                  ),
                )
                : const SizedBox.shrink(),
              const SizedBox(height: 10),

              // Password textfield
              TextBox(
                hintText: "Password",
                obscureText: true,
                controller: passwordController,
              ),
              isPassEmpty && triedToRegister ? 
                const Padding(
                  padding: EdgeInsets.only(left: 15, top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Password cannot be empty",
                        style:TextStyle(
                          color: Colors.red
                        ))
                    ]
                  ),
                )
                : const SizedBox.shrink(),
              const SizedBox(height: 10),

              // Confirm password textfield
              TextBox(
                hintText: "Confirm Password",
                obscureText: true,
                controller: confirmPwController,
              ),
              !doesPassMatch && triedToRegister ? 
                const Padding(
                  padding: EdgeInsets.only(left: 15, top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Passwords must match",
                        style:TextStyle(
                          color: Colors.red
                        ))
                    ]
                  ),
                )
                : const SizedBox.shrink(),
              const SizedBox(height: 25),
              // // Register button
              // Button(
              //   text: "Register",
              //   onTap: registerUser,
              // ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 28, 125, 204)
                ),
                onPressed: () {
                  // Register user and navigate to the create profile page
                  registerUser();
                },
                child: const Text("Register"),
              ),

              const SizedBox(height: 25),

              // Login here
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary),
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
