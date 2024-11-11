import 'package:Booth/App_Pages/chat_room_page.dart';
import 'package:Booth/App_Pages/session_details_page.dart';
import 'package:flutter/material.dart';
import 'package:Booth/MVC/booth_controller.dart';

class ExpandedSessionPage extends StatefulWidget {
  final BoothController controller;
  final String sessionKey;
  const ExpandedSessionPage(
    this.sessionKey, 
    this.controller, 
    {super.key}
    );
  

  @override
  State<ExpandedSessionPage> createState() => _ExpandedSessionPageState();
}

class _ExpandedSessionPageState extends State<ExpandedSessionPage> {
  late PageController pageController;
  int currPageIndex = 0;
  List<Widget> pages = [];
  
  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: currPageIndex);
    var detailsPage = SessionDetailsPage(widget.sessionKey, widget.controller, pageController);
    var chatPage = ChatRoomPage(widget.sessionKey, widget.controller, pageController);
    pages = [
      detailsPage,
      chatPage
    ];
  }

  void changePage(int index){
    if (index == 0){
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() {
      currPageIndex = index;
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop){
          return;
        }
        if (currPageIndex == 1){
          pageController.animateToPage(
            0, 
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut
          );
        }
        else{
          Navigator.of(context).pop();
        }
      },
      child: PageView(
        onPageChanged: (value) => changePage(value),
        controller: pageController,
        children: pages
      ),
    );
  }
}


