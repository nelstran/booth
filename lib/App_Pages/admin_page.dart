import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required DatabaseReference ref,
    required this.controller,
  }) : _ref = ref;

  final DatabaseReference _ref;
  final BoothController controller;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
            flex: 1, child: Text("Place backend stuff here to test")),
        // Testing friend system
        const Divider(),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text("All users"),
                    const Divider(),
                    Expanded(
                        flex: 1,
                        child: FirebaseAnimatedList(
                          query: _ref.child("users"),
                          itemBuilder: (BuildContext context,
                              DataSnapshot snapshot,
                              Animation<double> animation,
                              int index) {
                            Map<dynamic, dynamic> json =
                                snapshot.value as Map<dynamic, dynamic>;
                            if (json['uid'] == controller.student.uid)
                              return const SizedBox.shrink();
                            return ListTile(
                              title: Text(
                                json["name"],
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              trailing: const Icon(Icons.add),
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                controller.sendFriendRequest(snapshot.key!);
                              },
                            );
                          },
                        )),
                  ],
                ),
              ),
              const VerticalDivider(),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    const Text("Friends"),
                    const Divider(),
                    Expanded(
                        child: FutureBuilder(
                      future: controller.getFriends(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        if (snapshot.data!.isEmpty)
                          return const SizedBox.shrink();
                        Map<dynamic, dynamic> friends =
                            snapshot.data as Map<dynamic, dynamic>;
                        List<dynamic> friendKeys = friends.keys.toList();
                        return ListView.builder(
                            itemCount: friends.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(friends[friendKeys[index]]),
                                contentPadding: const EdgeInsets.all(0),
                                trailing: ElevatedButton(
                                  child: const Icon(Icons.remove),
                                  onPressed: () {
                                    controller.removeFriend(friendKeys[index]);
                                  },
                                ),
                              );
                            });
                      },
                    ))
                  ],
                ),
              ),
              const VerticalDivider(),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                        child: Column(
                      children: [
                        const Text("Incoming Requests"),
                        const Divider(),
                        Expanded(
                            child: FutureBuilder(
                          future: controller.getRequests(false),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const SizedBox.shrink();
                            Map<dynamic, dynamic> json =
                                snapshot.data as Map<dynamic, dynamic>;
                            if (json.isEmpty) return const SizedBox.shrink();
                            var keys = json.keys.toList();
                            return ListView.builder(
                              itemCount: json.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(json[keys[index]]),
                                  trailing: Column(
                                    children: [
                                      GestureDetector(
                                        child: const Icon(Icons.check),
                                        onTap: () {
                                          controller
                                              .acceptFriendRequest(keys[index]);
                                        },
                                      ),
                                      GestureDetector(
                                        child: const Icon(Icons.close),
                                        onTap: () {
                                          controller.declineFriendRequest(
                                              keys[index]);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        )),
                      ],
                    )),
                    Expanded(
                        child: Column(
                      children: [
                        const Text("Outgoing Requests"),
                        const Divider(),
                        Expanded(
                            child: FutureBuilder(
                          future: controller.getRequests(true),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const SizedBox.shrink();
                            Map<dynamic, dynamic> json =
                                snapshot.data as Map<dynamic, dynamic>;
                            if (json.isEmpty) return const SizedBox.shrink();
                            var keys = json.keys.toList();
                            return ListView.builder(
                              itemCount: json.length,
                              itemBuilder: (context, index) {
                                return Text(keys[index]);
                              },
                            );
                          },
                        )),
                      ],
                    )),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
