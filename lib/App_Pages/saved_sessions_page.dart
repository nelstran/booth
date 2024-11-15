// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:Booth/App_Pages/expanded_session_page.dart';
// import 'package:Booth/MVC/booth_controller.dart';
// import '../MVC/session_model.dart';

// class SavedSessionsPage extends StatefulWidget {
//   const SavedSessionsPage(this.controller, {super.key});
//   final BoothController controller;

//   @override
//   State<SavedSessionsPage> createState() => _SavedSessionsPage();
// }

// class _SavedSessionsPage extends State<SavedSessionsPage>{
//   @override
//   Widget build(BuildContext context) {
//     Future<Map<dynamic, dynamic>> savedSessions;
//     var savedSessionsList = {};
//     return Scaffold(
//         appBar: AppBar(
//           title: const Text('Saved Sessions List'),
//         ),
//         body: FutureBuilder(
//         future: savedSessions,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//           savedSessionsList = snapshot.data!;

//           return Column(
//             children: [
//               const Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "Saved Sessions",
//                     style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//               if (savedSessionsList.isNotEmpty)
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: savedSessionsList.length,
//                     itemBuilder: (context, index) {
//                       return savedSessionTile();
//                     }
//                   ),
//                 )
//               else
//                 const Center(child: Text('No saved sessions found'))
//             ],
//           );
//         }
//       )
//     );
//   }

//   StreamBuilder<DatabaseEvent> savedSessionTile() {
//     return StreamBuilder(
//       stream: widget.controller
//         .studentRef(userKey)
//         .onValue,
//       builder: (context, snapshot) {
//         String title = json['title'] ?? '';
//         return 
//           ListTile(
//               // Display title and description
//               title: Text(
//                 title,
//                 style: const TextStyle(
//                     fontWeight: FontWeight.bold),
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(session.locationDescription),
//                   const SizedBox(height: 2),
//                 ],
//               ),
//               trailing: rehostButton(context),
//               onTap: () { 
//                 }
//                 );
//               },
//             );
//   }

//   ElevatedButton rehostButton(BuildContext context) {
//     return ElevatedButton.icon(
//           style: ElevatedButton.styleFrom(
//           shape: StadiumBorder(),
//           ),
//           onPressed: () {
//             // Add session to sessions page 
//           },
//           label: const Text("Rehost"),
//         );
//   }
// }
