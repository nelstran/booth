import 'package:Booth/MVC/booth_controller.dart';
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
  List<types.Message> _messages = [];
  late final types.User _user;
  @override
  void initState(){
    super.initState();
    _user = types.User(
      id: widget.controller.student.uid
    );
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
          body: Chat(
            messages: _messages,
            theme: const DarkChatTheme(
              backgroundColor: Color.fromARGB(255, 24, 24, 24),
              inputBackgroundColor: Color.fromARGB(106, 78, 78, 78)
            ),
            // onAttachmentPressed: _handleAttachmentPressed,
            // onMessageTap: _handleMessageTap,
            // onPreviewDataFetched: _handlePreviewDataFetched,
            onSendPressed: (x){},
            showUserAvatars: true,
            showUserNames: true,
            user: _user,
          ),
        ),
    );
  }
}