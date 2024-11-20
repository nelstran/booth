import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/session_extension.dart';
import 'package:Booth/MVC/friend_extension.dart';

extension BlockExtension on BoothController {

  /// Method to block a user given a user's [key]
  void blockUser(String key) async {
    // Remove them from friends list if they are friends
    Map<dynamic, dynamic> friends = await getFriends();
    if (friends.containsKey(key)) {
      db.removeFriend(student.key, key);
    }
    // Add them to the blocked list
    db.addToBlocked(student.key, key);
  }

  /// Method to unblock a user given a user's [key]
  void unblockUser(String key) async {
    db.removeFromBlocked(student.key, key);
  }

  /// Gets the users the user blocked
  Future<Map<dynamic, dynamic>> getBlockedUsers(String key) async {
    Object? json = await db.getAllBlockedUsers(key);
    if (json == null) {
      return {};
    }
    return json as Map<dynamic, dynamic>;
  }

  // Get the users the user blocked with both user key and name
  Future<Map<dynamic, dynamic>> getBlockedUsersName(String key) async {
    Object? json = await db.getAllBlockedUsers(key);
    if (json == null) {
      return {};
    }
    Map<dynamic, dynamic> blockedUsers = json as Map<dynamic, dynamic>;

    for (var key in blockedUsers.keys) {
      String value = await db.getNameByKey(key) as String;
      if (value == "") continue;
      blockedUsers[key] = value;
    }
    blockedUsers.removeWhere((key, value) => value == "");
    return blockedUsers;
  }

  /// Gets the users the user is blocked from
  Future<Map<dynamic, dynamic>> getBlockedFromUsers(String key) async {
    Object? json = await db.getAllBlockedFromUsers(key);
    if (json == null) {
      return {};
    }
    return json as Map<dynamic, dynamic>;
  }

  /// Gets all users except for those the user has blocked and is blocked from
  Future<Map<dynamic, dynamic>> getNonBlockedUsers(String key) async {

    Map<dynamic, dynamic> allUsers = await getUsers();
    Map<dynamic, dynamic> blockedUsers = await getBlockedUsers(key);
    Map<dynamic, dynamic> blockedFromUsers = await getBlockedFromUsers(key);

   List<dynamic> usersToHide = blockedUsers.keys.toList();
   usersToHide.addAll(blockedFromUsers.keys.toList());

    for(var i = 0; i < usersToHide.length; i++){
      allUsers.removeWhere((key, value) => key == usersToHide[i]);
    }
    return allUsers;
  }

  /// Gets all sessions except for those the user is blocked from
  Future<Map<dynamic, dynamic>> getNonBlockedSessions(String key) async {

    Map<dynamic, dynamic> allSessions = await getSessions();
    Map<dynamic, dynamic> blockedUsers = await getBlockedUsers(key);
    Map<dynamic, dynamic> blockedFromUsers = await getBlockedFromUsers(key);

   List<dynamic> usersToHide = blockedUsers.keys.toList();
   usersToHide.addAll(blockedFromUsers.keys.toList());

    for(var i = 0; i < usersToHide.length; i++){ 
      String hiddenSession = await db.getUserSession(usersToHide[i]) as String;
      allSessions.removeWhere((key, value) => key == hiddenSession);
    }
    return allSessions;
  }
}
