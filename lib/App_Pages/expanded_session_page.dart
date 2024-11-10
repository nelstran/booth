import 'package:Booth/App_Pages/chat_room_page.dart';
import 'package:Booth/App_Pages/display_user_page.dart';
import 'package:Booth/App_Pages/session_details_page.dart';
import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:Booth/App_Pages/create_session_page.dart';
import 'package:Booth/MVC/analytics_extension.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/profile_extension.dart';
import 'package:Booth/MVC/session_extension.dart';
import 'package:synchronized/synchronized.dart';

import '../MVC/session_model.dart';

class ExpandedSessionPage extends StatefulWidget {
  final BoothController controller;
  final String sessionKey;
  const ExpandedSessionPage(this.sessionKey, this.controller, {super.key});
  

  @override
  State<ExpandedSessionPage> createState() {
    return _ExpandedSessionPageState();
  }
}

class _ExpandedSessionPageState extends State<ExpandedSessionPage> {
  late PageController pageController;
  int currPageIndex = 0;
  List<Widget> pages = [];

  late Stream sessionStream;
  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: currPageIndex);
    var detailsPage = SessionDetailsPage(widget.sessionKey, widget.controller, pageController);
    var chatPage = ChatRoomPage();
    pages = [
      detailsPage,
      chatPage
    ];
  }

  void changePage(int index){
    setState(() {
      currPageIndex = 1;
      pageController.animateToPage(
        currPageIndex, 
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutExpo
      );
    });
  }

  @override
  void dispose(){
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      onPageChanged: (value) => setState(() {
        currPageIndex = value;
      }),
      controller: pageController,
      children: pages
    );
  }
}


