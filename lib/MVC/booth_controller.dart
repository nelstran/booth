import 'package:Booth/MVC/profile_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:Booth/Database/SessionDatabase.dart';
import 'package:Booth/Database/firestore_database.dart';
import 'package:Booth/MVC/friend_extension.dart';
import 'package:Booth/MVC/session_extension.dart';
import 'package:Booth/MVC/student_model.dart';
import 'package:logger/web.dart';

/// Controller will act as a bridge from front end to back end.
/// Anything needed to modify the logged in user or sessions should
/// go through controller.
class BoothController extends ValueNotifier {
  final DatabaseReference ref;
  final FirestoreDatabase firestoreDb = FirestoreDatabase();
  SessionDatabase db;
  Student student;
  String _studentInstitution = "";
  String get studentInstitution => _studentInstitution;

  DatabaseReference get sessionRef =>
      ref.child("institutions/$studentInstitution/sessions");
  DatabaseReference get studentRef => ref.child("users/${student.key}");

  // Constructor
  BoothController(
    this.ref,
  )   : db = SessionDatabase(ref),
        student = Student(uid: "", firstName: "", lastName: ""),
        super(null);

  void setListeners(key) async {
    // Modify student on change
    DatabaseReference entryRef = ref.child("users/$key");
    DatabaseReference schoolRef = ref.child("users/$key/profile/institution");
    entryRef.onValue.listen((event) {
      // In an event the user deletes their account
      if (!event.snapshot.exists) {
        return;
      }
      var value = event.snapshot.value as Map;
      value['key'] = event.snapshot.key;

      setStudent(key, value);
    });
    schoolRef.onValue.listen((event){
      if (!event.snapshot.exists){
        return;
      }
      var value = event.snapshot.value.toString();
      setInstitution(value);
    });
    profileRef.onValue.listen((event) async {
      if (!event.snapshot.exists){
        return;
      }
      var value = event.snapshot.value as Map;
      if (student.session != ""){
        try{
          Map json = await db.getSession(student.session) as Map;
          // Get list of users from session
          Map users = Map.from(json["users"]);
          // Get user from user list
          Map currUser = users[student.sessionKey] as Map;
          // Update name
          currUser["name"] = value["name"];
          json["users"] = users;
          // I HATE CASTING
          Map<String, Object?> session = json.cast<String, Object?>();
          // Update session
          db.updateSession(student.session, session);
        }
        catch (e){
          // Skip
          print(e);
        }
      }
    });
  }

  /// Get logged in user's account information
  Future<String> fetchAccountInfo(User user) async {
    try {
      String key = await db.fetchUserKey(user);
      DatabaseReference entryRef = ref.child("users/$key");
      final event = await entryRef.once();
      final doc = await firestoreDb.getUserData(user.uid);
      if (doc == null) {
        firestoreDb.addUserData(user.uid);
      }
      var value = event.snapshot.value as Map;
      value['key'] = event.snapshot.key;
      setListeners(key);
      setStudent(key, value);
      if (value.containsKey('profile') &&
          (value['profile'] as Map).containsKey('institution')) {
        await setInstitution(value['profile']['institution']);
      }
      return student.fullname;
    } catch (error) {
      if (error == 'Error fetching user info') {
        if (FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.currentUser!.delete();
        }
      }
      FirebaseAuth.instance.signOut();
      return Future.error(error);
    }
  }

  Future<void> setInstitution(String institution) async  {
    _studentInstitution = institution;
    db.setInstitution(institution);
    await updateUserProfile({"institution": institution});
  }

  ///  Deletes the User account in FireBase
  Future<void> deleteUserAccountFB(BuildContext context) async {
    // Logs Exceptions
    var logger = Logger();
    // Checks if context is mounted so no crash happens
    //if (!context.mounted) return;
    try {
      // This Deletes the user from Firebase
      return reauthenticateThenDelete(context);
      //await FirebaseAuth.instance.currentUser!.delete();
      //Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      logger.e(e);
      // This means that Firebase wants them to re-authenticate before Axing the account
      if (e.code == "requires-recent-login") {
        print("Requires Recent login.");

        return reauthenticateThenDelete(context);
      } else {
        logger.e(e);
      }
    } catch (e) {
      logger.e(e);
    }
  }

  /// Function that Requires the user to input their password so they
  /// can prove that it is them with the account.
  Future<void> reauthenticateThenDelete(BuildContext context) async {
    // Used for Logging exceptions
    Logger logger = Logger();
    // Checks if context is mounted so no crash happens
    //if (!context.mounted) return;

    // Runs method to delete account
    //await tryToDelete(context);
    // For inputted password
    TextEditingController passwordController = TextEditingController();
    String password = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: "Password"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                //password = "Cancel";
                Navigator.of(context).pop();
                return;
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () async {
                password = passwordController.text;
                try {
                  AuthCredential credential = EmailAuthProvider.credential(
                      email: FirebaseAuth.instance.currentUser!.email!,
                      password: password);
                  await FirebaseAuth.instance.currentUser!
                      .reauthenticateWithCredential(credential);
                  // After fresh credential is gained, Firebase Deletes the account
                  await FirebaseAuth.instance.currentUser!.delete();
                  //Pops both Dialogs (Enter Password + Warning Dialog)
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

                  // Deletes the user from everywhere on our app
                  deleteUserAccountEverywhere(student);
                } on FirebaseAuthException catch (e) {
                  logger.e(e);
                  // Handles Firebase exceptions during reauthentication
                  if (e.code == "invalid-credential") {
                    showDialog(
                        context: context,
                        builder: (BuildContext ctx) {
                          return AlertDialog(
                            title: const Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text("Wrong Password!"),
                                ),
                              ],
                            ),
                            content: const Text("Wrong Password. Try Again."),
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
                    // Handle case where the entered password is incorrect
                  } else if (e.code == "wrong-password") {
                    // Handle case where the user doesn't match
                    showDialog(
                        context: context,
                        builder: (BuildContext ctx) {
                          return AlertDialog(
                            title: const Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text("Wrong Password!"),
                                ),
                              ],
                            ),
                            content:
                                const Text("Wrong Password! Please Try Again."),
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
                  } else {
                    showDialog(
                        context: context,
                        builder: (BuildContext ctx) {
                          return AlertDialog(
                            title: const Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text("error_occured"),
                                ),
                              ],
                            ),
                            content:
                                const Text("Error Occured, Please Try Again."),
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
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// THIS SHOULD EVENTUALLY GO IN THE PROFILE PAGE
  /// Deletes the user everywhere in our app;
  /// - Any Sessions they are apart of
  /// - Any Sessions that they currently own
  /// - The list of users that are recorded in the DB
  /// - From any Friends list they are apart of
  Future<void> deleteUserAccountEverywhere(Student student) async {
    // First Check to see if the user is apart of any study sessions
    // If so, remove from study session
    if (student.session != "") {
      await removeUserFromSession(student.session, student.sessionKey);
    }
    // Check is their are any sessions that they OWN and remove the session
    if (student.ownedSessionKey != "") {
      await removeUserFromSession(student.session, student.sessionKey);
      removeSession(student.ownedSessionKey);
    }

    // Remove user from their friends' friends list
    Map<dynamic, dynamic> allFriends = await getFriendsKeys();

    for (var entry in allFriends.entries) {
      var key = entry.key;
      removeFriend(key);
    }

    // Remove user from their requests
    Map<dynamic, dynamic> outRequests = await getRequests(true);

    for (var user in outRequests.keys) {
      declineFriendRequest(student.key, user);
    }

    Map<dynamic, dynamic> inRequests = await getRequests(false);
    for (var user in inRequests.keys) {
      declineFriendRequest(user);
    }

    // Remove user from Firestore
    firestoreDb.removeUserData(student.uid);

    // Remove profile picture from Storage;
    firestoreDb.deleteProfilePictureStorage(student.uid);

    // Then, remove from the "users" list in the Database
    removeUser(student.key);
  }

  /// Set student of the controller
  void setStudent(String key, Map value) {
    student = Student.fromJson(value);
  }

  /// Add the given student to the database
  Future<void> addUser(Student student) async {
    await db.addUser(student.toJson());
    await firestoreDb.addUserData(student.uid);
  }

  /// Given its key, remove the user from the database
  void removeUser(String key) {
    db.removeUser(key);
  }

  /// Get user profile, defaults to logged in user if no key is given
  Future<Map<dynamic, dynamic>> getUserProfile([key]) async {
    key = key ?? student.key;
    Object? json = await db.getProfile(key);
    if (json == null) {
      return {};
    }
    return json as Map<dynamic, dynamic>;
  }

  /// Get user entry in database, defaults to logged in user if no key is given
  Future<Map<dynamic, dynamic>> getUserEntry([key]) async {
    key = key ?? student.key;
    Object? json = await db.getUser(key);
    if (json == null) {
      return {};
    }
    return json as Map<dynamic, dynamic>;
  }

  Future<void> updateUserEntry(Map<String, Object?> values, [String? key]) async {
    key = key ?? student.key;
    db.updateUser(key, values);
  }

  Future<Map<dynamic, dynamic>> getUsers() async {
    Object? json = await db.getAllUsers();
    if (json == null) {
      return {};
    }
    return json as Map<dynamic, dynamic>;
  }

  Future<Map<dynamic, dynamic>> getInstitute([institute]) async {
    institute = institute ?? studentInstitution;
    Object? json = await db.getInstitute(institute);
    if (json == null) {
      return {};
    }
    return json as Map<dynamic, dynamic>;
  }

  ValueNotifier<bool> friendsOnlyNotifier = ValueNotifier<bool>(false);
  void setFriendsTab(bool value) {
    friendsOnlyNotifier.value = value;
    notifyListeners();
  }

  //Gets the "uid" from the "FireStore Key"
  Future<Object?> getUid(
      String institution, String seshKey, String ownerKey) async {
    final uid = await db.getUid(institution, seshKey, ownerKey);
    return uid;
  }
}
