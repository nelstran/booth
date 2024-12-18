import 'package:Booth/MVC/profile_extension.dart';
import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:flutter/material.dart';
import 'package:Booth/App_Pages/display_user_page.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/friend_extension.dart';

/// Page that is only accessible if user receives a 
/// friend request from another user. Users have the
/// option to view the profile, decline or accept the request.
class RequestsPage extends StatefulWidget {
  const RequestsPage(this.controller, {super.key});
  final BoothController controller;

  @override
  State<RequestsPage> createState() => _RequestsPage();
}

class _RequestsPage extends State<RequestsPage> {
  @override
  Widget build(BuildContext context) {
    double pfpRadius = 25;
    double pfpFontSize = 20;
    return Scaffold(
      appBar: AppBar(title: const Text('Friend Requests')),
      body: FutureBuilder<Map<dynamic, dynamic>>(
        future: widget.controller.getRequests(false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No requests found.'));
          }
          final requests = snapshot.data!;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index){
              final requestId = requests.keys.elementAt(index);
              final requestName = requests[requestId] as String;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                leading: StreamBuilder(
                  stream: widget.controller.pfpRef(requestId).snapshots(), 
                  builder: (context, snapshot){
                    return FutureBuilder(
                      future: widget.controller.getProfilePictureByKey(requestId, true),
                      builder: (context, snapshot) {
                        return Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: CachedProfilePicture(
                            name: requestName,
                            radius: pfpRadius,
                            fontSize: pfpFontSize,
                            imageUrl: snapshot.data
                          )
                        );
                      },
                    );
                  }
                ),
                title: Text(requestName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: const Color.fromARGB(255, 44, 44, 44),
                        child: IconButton(
                          icon: const Icon(
                            Icons.check, 
                            color: Colors.green
                          ),
                          onPressed: () async {
                            await widget.controller.acceptFriendRequest(requestId);
                            setState((){
                              requests.remove(requestId);
                            });
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: const Color.fromARGB(255, 44, 44, 44),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close, 
                            color: Colors.red
                          ),
                          onPressed: () async {
                            await widget.controller.declineFriendRequest(requestId);
                            setState((){
                              requests.remove(requestId);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          UserDisplayPage(widget.controller, requestId, true, false),
                    ),
                  );
                },
              );
            }
          );
        },
      ),
    );
  }
}
