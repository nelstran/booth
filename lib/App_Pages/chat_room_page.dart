import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/chat_room_extension.dart';
import 'package:Booth/UI_components/cached_profile_picture.dart';
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
  List<types.Message> _messages = [];
  FocusNode focus = FocusNode();

  @override
  void initState(){
    super.initState();
    _getMessages();
    _user = types.User(
      id: widget.controller.student.uid
    );
    messageController = TextEditingController();
    types.User x = types.User(
      id: "hi",
    );
    types.Message m = types.TextMessage(author: _user, id: "x", text: "kys");
    types.Message n = types.TextMessage(author: x, id: "x", text: "I am sean williams");

    _messages.add(m);
    _messages.add(n);
  }

  void _getMessages()async {
    List<types.Message> messages = await widget.controller.getSessionMessages(widget.sessionKey);
    setState(() {
      _messages = messages;
    });
  }
  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(), // Create random id per message
      text: message.text,
    );

    _addMessage(textMessage);
  }

  Future<void> _addMessage(types.TextMessage message) async {
    await widget.controller.sendMessageToSession(message, widget.sessionKey);
    setState(() {
      _messages.insert(0,message);
    });
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
            timeFormat: DateFormat.jm(),
            // avatarBuilder: (author) {
            // },
            customBottomWidget: bottomInputBar(),
            messages: _messages,
            theme: const DarkChatTheme(
              backgroundColor: Color.fromARGB(255, 24, 24, 24),
              inputBackgroundColor: Color.fromARGB(106, 78, 78, 78),
              primaryColor: Color.fromARGB(106, 78, 78, 78),

              secondaryColor: Color.fromARGB(255, 0,51,102)
            ),
            // onAttachmentPressed: _handleAttachmentPressed,
            // onMessageTap: _handleMessageTap,
            // onPreviewDataFetched: _handlePreviewDataFetched,
            onSendPressed: _handleSendPressed,
            showUserAvatars: true,
            showUserNames: true,
            user: _user,
          ),
        ),
    );
  }
  
  Container bottomInputBar() {
    return Container(
    padding:
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    decoration: const BoxDecoration(
      color: Color.fromARGB(255, 43, 43, 43),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.0),
        topRight: Radius.circular(20.0),
      ),
    ),
    child: TextField(
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
}