import 'dart:async';
import 'package:Booth/App_Pages/display_user_page.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/chat_room_extension.dart';
import 'package:Booth/MVC/profile_extension.dart';
import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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

class _ChatRoomPageState extends State<ChatRoomPage> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;

  late TextEditingController messageController;
  late final types.User _user;
  late Stream<QuerySnapshot<Object?>> chatRoomStream;

  StreamController<List<types.Message>> messageStream = StreamController();
  List<types.Message> _messages = [];
  FocusNode focus = FocusNode();
  bool isInThisSession = false;

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
    chatRoomStream = widget.controller.sessionChatRef(widget.sessionKey).snapshots();
    isInThisSession = widget.controller.student.session == widget.sessionKey;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Lots of streams smh
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat room")
      ),
      // Get current state of messages and stream new ones
      body: StreamBuilder(
        stream: chatRoomStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData){
            // Add each new message that comes in
            for (var document in snapshot.data!.docChanges){
              try{
                if (document.type == DocumentChangeType.added){
                  final newMessage = types.TextMessage.fromJson(document.doc.data() as Map<String, dynamic>);
                  _messages.insert(0, newMessage);
                }
                // Remove messages from UI
                if(document.type == DocumentChangeType.removed){
                  final removedMessage = types.TextMessage.fromJson(document.doc.data() as Map<String, dynamic>);
                  final messages = List.from(_messages);
                  // Go through the message list and remove messages that have been deleted from database
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

          // Sort messages by time
          _messages.sort((a, b) {
            if (a.createdAt == null){ // System messages do not have a time stamp, put them at the top (for now)
              return -2147483648;
            }
            if (b.createdAt == null){
              return 0;
            }
            return b.createdAt! - a.createdAt!;
          });
          // Notifies users when the session has been deleted
          return StreamBuilder(
            stream: widget.controller.sessionRef.child(widget.sessionKey).onValue,
            builder: (context, snapshot) {
              isInThisSession = widget.controller.student.session == widget.sessionKey;
              if (snapshot.hasData && !snapshot.data!.snapshot.exists){
                // Delete all messages and display deletion notice
                _messages.clear();
                _sendDeletionNotice();
                isInThisSession = false;
              }
              // This updates on local changes of the chat room, like System messages
              return StreamBuilder(
                stream: messageStream.stream,
                builder: (context, snapshot) {
                  // Keep users' names up to date in chat room
                  return StreamBuilder(
                    stream: widget.controller.studentRef().onValue,
                    builder: (context, snapshot) {
                      return Chat(
                        // Customize the chat to our liking
                        theme: const DarkChatTheme(
                          userAvatarNameColors: [Colors.white],
                          userNameTextStyle: TextStyle(
                            fontSize: 15,
                            fontFamily: 'RobotoMono',
                            // fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic
                          ),
                          backgroundColor: Color.fromARGB(255, 18, 18, 18),
                          inputBackgroundColor: Color.fromARGB(106, 78, 78, 78),
                          primaryColor: Color.fromARGB(106, 78, 78, 78),
                          secondaryColor: Color.fromARGB(255, 0,51,102),
                        ),
                        timeFormat: DateFormat.jm(), // Set time as XX:XX AM/PM
                        // timeFormat: DateFormat.yMd().add_jm() // Adds date plus time
                        avatarBuilder: _cachedAvatarBuilder,
                        systemMessageBuilder: _systemMessageBuilder,
                        customBottomWidget: bottomInputBar(),
                        messages: _messages,
                        // onAttachmentPressed: _handleAttachmentPressed,
                        onMessageTap: _handleMessageTap,
                        onPreviewDataFetched: _handlePreviewDataFetched,
                        onSendPressed: _handleSendPressed,
                        usePreviewData: true,
                        showUserAvatars: true,
                        showUserNames: true,
                        user: _user,
                      );
                    }
                  );
                }
              );
            }
          );
        }
      ),
    );
  }

  /// Detect when messages with a link has been tapped, then 
  /// confirm with users if they would like to proceed
  void _handleMessageTap(BuildContext context, types.Message message){
    Uri url = Uri();
    if ((message as types.TextMessage).previewData != null){
      if(message.previewData!.link != null){
        url = Uri.parse(message.previewData!.link!);
        showDialog(
          context: context, 
          builder: (context){
            return AlertDialog(
          title: const Text(
            "Navigate off Booth?",
            // style: TextStyle(fontSize: 30),
          ),
          content: RichText(
            text: TextSpan(
              text: 'This link will take you to\n',
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: url.toString(),
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold
                  )
                ),
                const TextSpan(
                  text: "\n\nAre you sure you would like to proceed?"
                )
              ]  
            )
          ),
          actionsPadding: const EdgeInsets.only(bottom: 8, right: 24),
          actions:[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        elevation: 0.0,
                        shadowColor: Colors.transparent,
                        backgroundColor: Colors.transparent,
                        // padding: EdgeInsets.zero
                        ),
                    child: const Text(
                      "Take me back",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: (){
                    launchUrl(url);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                    ),
                  child: const Text(
                    "Yes, I'm sure",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            )
          ]
        );
          });
      }
    }
  }

  /// Add preview data when it detects the message has a link
  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    _messages[index] = updatedMessage as types.TextMessage;
    messageStream.sink.add(_messages);
  }

  /// Setup the message object given a partial text from the chat UI
  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(), // Create random id per message
      text: message.text.trim(),
    );

    _addMessage(textMessage);
  }

  /// Method to send the privacy warning
  void _sendWarning() {
    String warning = "This chat can be read by anyone! \nDo not share sensitive and personal information over Booth!";
    _sendSystemMessage(warning);
  }

  /// Method to notify users that the session has been deleted
  void _sendDeletionNotice(){
    String warning = "The host has deleted this session. Feel free to join a new session or create your own!";
    _sendSystemMessage(warning);
    messageStream.add(_messages);
  }

  /// Make sure users dont send an empty text and clear the textfield when submitting
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

  /// Helper method to send system message 
  void _sendSystemMessage(String text){
    types.User user = const types.User(
      id: 'Booth',
      firstName: "BOOTH",
      lastName: "(automated message)",
    );

    final textMessage = types.SystemMessage(
      author: user,
      // createdAt: 0,
      id: const Uuid().v4(), // Create random id per message
      text: text,
    );

    _messages.add(textMessage);
  }

  /// Adds the message to the database
  Future<void> _addMessage(types.TextMessage message) async {
    await widget.controller.sendMessageToSession(message, widget.sessionKey);
  }

  Widget _systemMessageBuilder(types.SystemMessage message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 15,
            fontWeight: FontWeight.bold
          )
        ),
      )
    );
  }

  Widget _cachedAvatarBuilder(types.User author) {
    if (author.id == 'Booth'){
      return const Padding(
        padding: EdgeInsets.only(right: 8.0),
        child: Icon(Icons.gpp_maybe, size: 40),
      );
    }
    return GestureDetector(
      onTap: () {
        // Navigate to the profile page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserDisplayPage(
                widget.controller, author.metadata!['key'], false, false),
          ),
        );
      },
      child: FutureBuilder(
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
      ),
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
      child: isInThisSession ? chatRoomInput() : disabledInput()
    );
  }
  Widget disabledInput() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: TextField(
        readOnly: true,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isCollapsed: true,
          hintText: "Join this session to start chatting",
          hintStyle: TextStyle(
            fontSize: 16, 
            color: Colors.grey
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  TextField chatRoomInput() {
    return TextField(
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
    );
  }
}