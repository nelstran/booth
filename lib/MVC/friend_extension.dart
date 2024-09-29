import 'package:flutter_application_1/MVC/booth_controller.dart';

extension FriendExtension on BoothController{
  Future<Map<dynamic, dynamic>> getFriends() async {
    Object? json = await db.getFriends(student.key);
    if (json == null) {
      return {};
    }
    Map<dynamic, dynamic> friends = json as Map<dynamic, dynamic>;

    if (friends.containsKey('requests')) {
      friends.remove('requests');
    }

    for (var key in friends.keys) {
      // Get names for now, maybe get the entire student model later
      String value = await db.getNameByKey(key) as String;
      if (value == "") continue;
      friends[key] = value;
    }
    friends.removeWhere((key, value) => value == "");
    return friends;
  }

  Future<Map<dynamic, dynamic>> getFriendsKeys() async {
    Object? json = await db.getFriends(student.key);
    if (json == null) {
      return {};
    }
    Map<dynamic, dynamic> friendsKeys = json as Map<dynamic, dynamic>;

    if (friendsKeys.containsKey('requests')) {
      friendsKeys.remove('requests');
    }

    for (var key in friendsKeys.keys) {
      friendsKeys[key] = key;
    }
    return friendsKeys;
  }

  void removeFriend(String key) {
    db.removeFriend(student.key, key);
  }

  Future<Map<dynamic, dynamic>> getRequests(bool isOutgoing) async {
    Object? json = await db.getRequests(student.key);
    String outgoing = isOutgoing ? "outgoing" : "incoming";
    if (json == null || (json as Map)[outgoing] == null) {
      return {};
    }
    Map<dynamic, dynamic> requests = {};
    for (var key in json[outgoing].keys) {
      // Get names for now, maybe get the entire student model later
      String value = await db.getNameByKey(key) as String;
      if (value == "") continue;
      requests[key] = value;
    }
    requests.removeWhere((key, value) => value == "");
    return requests;
  }

  void sendFriendRequest(String key) async {
    Map<dynamic, dynamic> requests = await getRequests(true);
    Map<dynamic, dynamic> friends = await getFriends();
    if (requests.containsKey(key)){
      return; // Do nothing if user already sent a request
    }
    if (friends.containsKey(key)){
      return; // Do nothing if user is already friends
    }

    db.sendFriendRequest(student.key, key);
  }

  Future<void> declineFriendRequest(String sender, [String? receiver]) async {
    receiver = receiver ?? student.key;
    return db.declineFriendRequest(receiver, sender);
  }

  Future<void> acceptFriendRequest(String key) async {
    Map<dynamic, dynamic> requests = await getRequests(true);
    Map<dynamic, dynamic> friends = await getFriends();
    if (requests.containsKey(key)) {
      return; // Do nothing if user already sent a request
    }
    if (friends.containsKey(key)) {
      return; // Do nothing if user is already friends
    }
    return db.acceptFriendRequest(student.key, key);
  }
}