import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/display_user_page.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';

class RequestsPage extends StatelessWidget {
  final BoothController controller;

  const RequestsPage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests')
      ),
      body: FutureBuilder<Map<dynamic, dynamic>>(
        future: controller.getRequests(false), 
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
            itemBuilder: (context, index) {
              final requestId = requests.keys.elementAt(index);
              final requestName = requests[requestId] as String;
              return ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[200],
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.grey[500],
                  ),
                ),
                title: Text(requestName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await controller.acceptFriendRequest(requestId);
                        if(context.mounted){
                          return Navigator.of(context).pop(); 
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await controller.declineFriendRequest(requestId);
                        if(context.mounted){
                          Navigator.of(context).pop(); 
                        }
                      },
                    ),
                  ],
                ),
                onTap: (){
                  Navigator.of(context).push(
                            MaterialPageRoute(
                      builder: (context) => UserDisplayPage(controller, requestId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
