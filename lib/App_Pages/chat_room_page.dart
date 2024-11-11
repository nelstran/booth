import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/chat_room_extension.dart';
import 'package:Booth/MVC/profile_extension.dart';
import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

class ChatRoomPage extends StatefulWidget {
  final BoothController controller;
  final String sessionKey;
  final PageController pg;
  const ChatRoomPage(
    this.sessionKey,
    this.controller,
    this.pg,
    {super.key}
  );

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  late TextEditingController messageController;
  late final types.User _user;
  List<types.TextMessage> _messages = [];
  FocusNode focus = FocusNode();

  @override
  void initState(){
    super.initState();
    _user = types.User(
      id: widget.controller.student.uid,
      firstName: widget.controller.student.firstName,
      lastName: widget.controller.student.lastName,
      metadata: {
        "key": widget.controller.student.key,
      }
    );
    _sendWarning();
    messageController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop){
            return;
          }
          widget.pg.animateToPage(
            0, 
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut
          );
        },
      child: Scaffold(
          appBar: AppBar(),
          body: StreamBuilder(
            stream: widget.controller
            .sessionChatRef(widget.sessionKey)
            .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData){
                for (var document in snapshot.data!.docChanges){
                  try{
                    if (document.type == DocumentChangeType.added){
                      final newMessage = types.TextMessage.fromJson(document.doc.data() as Map<String, dynamic>);
                      _messages.insert(0, newMessage);
                    }
                    if(document.type == DocumentChangeType.removed){
                      final removedMessage = types.TextMessage.fromJson(document.doc.data() as Map<String, dynamic>);
                      final messages = List.from(_messages);
                      for(var entry in messages.asMap().entries){
                        if (entry.value.id == removedMessage.id){
                          _messages.removeAt(entry.key);
                          break;
                        }
                      }
                    }
                  }
                  catch (e) {
                    // Skip
                  }
                }
                }
              return Chat(
                timeFormat: DateFormat.jm(),
                avatarBuilder: _cachedAvatarBuilder,
                customBottomWidget: bottomInputBar(),
                messages: _messages,
                theme: const DarkChatTheme(
                  userAvatarNameColors: [Colors.white],
                  userNameTextStyle: TextStyle(
                    fontSize: 15,
                    fontFamily: 'RobotoMono',
                    // fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic
                  ),
                  backgroundColor: Color.fromARGB(255, 24, 24, 24),
                  inputBackgroundColor: Color.fromARGB(106, 78, 78, 78),
                  primaryColor: Color.fromARGB(106, 78, 78, 78),
                  secondaryColor: Color.fromARGB(255, 0,51,102),
                ),
                // onAttachmentPressed: _handleAttachmentPressed,
                // onMessageTap: _handleMessageTap,
                // onPreviewDataFetched: _handlePreviewDataFetched,
                onSendPressed: _handleSendPressed,
                showUserAvatars: true,
                showUserNames: true,
                user: _user,
                emptyState: chatWarning(),
              );
            }
          ),
        ),
    );
  }

  Center chatWarning() {
    return const Center(
      child: Text(
        "This chat can be read by anyone! \nDo not share sensitive and personal information over Booth!",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.grey
        )
      )
    );
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(), // Create random id per message
      text: message.text.trim(),
    );

    _addMessage(textMessage);
  }

  void _sendWarning() {
    types.User user = const types.User(
      id: 'Booth',
      firstName: "BOOTH",
      lastName: "SYSTEM",
    );
    String warning = "This chat can be read by anyone! \nDo not share sensitive and personal information over Booth!";

    final textMessage = types.TextMessage(
      author: user,
      createdAt: 0,
      id: const Uuid().v4(), // Create random id per message
      text: warning,
    );

    _messages.add(textMessage);
  }

  Future<void> _addMessage(types.TextMessage message) async {
    await widget.controller.sendMessageToSession(message, widget.sessionKey);
  }

  void _onTextFieldSubmit(){
    if(messageController.text.isEmpty){
      return;
    }
    final partialText = types.PartialText(
      text: messageController.text
    );
    _handleSendPressed(partialText);
    messageController.clear();
  }

  Widget _cachedAvatarBuilder(types.User author) {
    return FutureBuilder(
      future: widget.controller.getProfilePictureByUID(author.id, true),
      builder: (context, snapshot){
        try{
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CachedProfilePicture(
              name: "${author.firstName} ${author.lastName}",
              imageUrl: snapshot.data,
              radius: 18,
              fontSize: 20,
            ),
          );
        }
        catch (e){
          return const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: CircleAvatar(radius: 18,),
          );
        }
      }
    );
  }
  
  Container bottomInputBar() {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 150
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 43, 43, 43),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: TextField(
        maxLines: 5,
        minLines: 1,
        focusNode: focus,
        textAlignVertical: TextAlignVertical.center,
        controller: messageController,
        decoration: InputDecoration(
          isCollapsed: true,
          hintText: "Message",
          hintStyle: const TextStyle(
            fontSize: 16, 
            color: Colors.grey
          ),
          border: InputBorder.none,
          suffixIcon: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: const Color.fromARGB(255, 16, 90, 151)
            ),
            onPressed: _onTextFieldSubmit,
            child: const Icon(Icons.send)
          )
        ),
        onSubmitted: (value) {
          _onTextFieldSubmit();
          focus.requestFocus();
        }
        // onChanged: (value) => messageController.text = value.trim(),
      )
    );
  }

}