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
  Future<List<types.Message>> getSessionMessages(String sessionKey) async {
    final json = await firestoreDb.getSessionMessages(sessionKey);
    if (json.isEmpty){
      return [];
    }
    final messages = json.values
    .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
    .toList();
    
    messages.sort((a, b) => a.createdAt! - b.createdAt!);
    return messages;
  }

  Future<void> sendMessageToSession(types.TextMessage message, String key) async {
    await firestoreDb.sendMessageToSession(message, key);
  }
}