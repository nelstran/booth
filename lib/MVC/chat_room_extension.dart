import 'package:Booth/MVC/booth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

extension ChatRoomExtension on BoothController {
  CollectionReference sessionChatRef(String sessionKey){
    return firestoreDb.db
    .collection("sessions")
    .doc(sessionKey)
    .collection("chat_room");
  }

  /// Send [message] to the session given its [key]
  Future<void> sendMessageToSession(types.TextMessage message, String key) async {
    await firestoreDb.sendMessageToSession(message, key);
  }
}