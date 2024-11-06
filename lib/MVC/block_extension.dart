import 'package:Booth/MVC/booth_controller.dart';
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

}
