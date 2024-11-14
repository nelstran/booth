import 'package:Booth/MVC/booth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Method to display messages to user
void displayMessageToUser(String message, BuildContext context) {
  showDialog(
    context: context, 
    builder: (context) => AlertDialog(
      title: const Text("Uh oh! Something went wrong!"),
      content: Text(message),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          child: const Text("OK"),
          onPressed: () => Navigator.of(context).pop(),
        )
      ],

    ),
  );
}

void logout(BoothController controller, BuildContext context) {
  showDialog(
    context: context, builder: (context){
      return AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Do you want to log out?"),
        actions:[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      shadowColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      // padding: EdgeInsets.zero
                      ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: (){
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                    elevation: 0.0,
                  ),
                child: const Text(
                  "Confirm",
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          )
        ]
      );
    }).then((value) {
      if(!value) {
        return;
      } 
      controller.setOnlinePresence(false);
      FirebaseAuth.instance.signOut();
    });
  
}

