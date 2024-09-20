import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreDatabase {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  FirestoreDatabase();

  void addUserData(String key) {
    db.collection("users").doc(key).set({});
  }
  
  Future<Map<String, dynamic>?> getUserData(String key) async {
    final ref = db.collection("users").doc(key);
    final doc = await ref.get();
    return doc.data();
  }

}