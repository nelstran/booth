import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/create_profile_page.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_application_1/MVC/profile_extension.dart';
import 'package:flutter_application_1/MVC/sample_extension.dart';
import 'package:flutter_application_1/MVC/session_extension.dart';
import 'package:flutter_application_1/MVC/student_model.dart';
import 'package:flutter_application_1/User_Authentication/auth.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;

/// Class to repressent institution selection page, 
/// Not sure how to know the previous page in the route so previousPage is a string argument
/// [previousPage] can be "Profile", "Login", "Register". If anything else, defaults to "Login"
class InstitutionsPage extends StatefulWidget{
  final BoothController controller;
  final String previousPage;
  const InstitutionsPage(
    this.controller, 
    this.previousPage,
    {super.key});

  @override
  State<StatefulWidget> createState() => _InstituionsPage();
}

/// Class to repressent institution selection page, 
/// Not sure how to know the previous page in the route so previousPage is a string argument
/// [previousPage] can be "Profile", "Login", "Register". If anything else, defaults to "Login"
class _InstituionsPage extends State<InstitutionsPage>{
  TextEditingController institutionController = TextEditingController();
  List<Map<dynamic, dynamic>> listOfInstitutions = [];
  Timer? _debounce;
  bool loading = false;
  bool searching = false;
  String query = '';

  /// Only start searching after the user has stopped
  /// typing after a certain duration, currently 800ms
  _onSearchChanged(String value){
    setState((){
      listOfInstitutions.clear();
      query = value;
    });
    // Don't search an empty query
    if (value == ""){
      setState((){
        loading = false;
      });
      return;
    }

    setState(() {
      searching = true;
      loading = true;
    });

    // Restart timer
    if(_debounce?.isActive ?? false){
      _debounce?.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 800), () {
      // Start searching when timer is done
      searching = false;
      listOfInstitutions.clear();
      _getListOfInstitutions(value);
    });
  }

  @override
  void dispose(){
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect with your college!'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 0.0
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(106, 78, 78, 78),
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: institutionController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: "Search for your institution...",
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey
                  ),
                  border: InputBorder.none,
                ),
                // onSubmitted: (value) => _getListOfInstitutions(value)
                onChanged: (value) => _onSearchChanged(value),
              ),
            ),
          ),
          searchResults()
        ],
      ),
    );
  }

  Expanded searchResults() {
    return Expanded(
      // Currently searching
      child: loading ? const Center(
        child: CircularProgressIndicator()
      )
      : listOfInstitutions.isEmpty ?
        // Show blank if query is also blank
         institutionController.text.isEmpty ?
          const SizedBox.shrink()
          : const Center(
            child: Text('No results found')
          )
        // Display list of colleges once searching is done
        : ListView.builder(
            itemCount: listOfInstitutions.length,
            itemBuilder: (context, index){
              var institute = listOfInstitutions[index];
              String website = institute['web_pages'];
              String logoURL = institute['logo'] ?? '';

              Image logo = Image.network(
                logoURL,
                fit: BoxFit.contain,
                // If no logo is found, use icon instead
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.school,
                    size: 50,
                    color: Colors.grey[700],
                  );
                },
              );
              return schoolTile(logoURL, logo, institute, website, context);
            },
      ),
    );
  }

  Padding schoolTile(String logoURL, Image logo, Map<dynamic, dynamic> institute, String website, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0))
        ),
        tileColor: const Color.fromARGB(55, 78, 78, 78),
        visualDensity: const VisualDensity(
          vertical: 3
          ),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: logoURL == '' ? Colors.transparent
            : Colors.white,
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: SizedBox(
            height: 70,
            width: 70,
            child: logo
          ),
        ),
        title: Text(
          institute['name'],
          style:const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(website),
        onTap: (){
          confirmationDialog(context, logoURL, logo, institute);
        },
      ),
    );
  }

  Future<dynamic> confirmationDialog(BuildContext context, String logoURL, Image logo, Map<dynamic, dynamic> institute) {
    return showDialog(
      context: context,
      builder: (context){
        return AlertDialog(
          title: Center(
            child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: logoURL == '' ? Colors.transparent
              : Colors.white,
            ),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: SizedBox(
              height: 100,
              width: 100,
              child: logo
            ),
          ),
          ),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Would you like to join",
                style:TextStyle(
                  fontSize: 20
                ),
              ),
              Text(
                "${institute['name']}?",
                style:const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30
                ),
                textAlign: TextAlign.center,
              )
            ]
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (){
                      Navigator.pop(context);
                    }, 
                    style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      shadowColor: Colors.transparent,
                      backgroundColor: Colors.transparent
                    ),
                    child: const Text(
                      "No",
                      style: TextStyle(
                        color: Colors.grey
                      ),),
                  ),
                ), 
                const SizedBox(width: 8.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Student student = widget.controller.student;
                      // First Check to see if the user is apart of any study sessions
                      // If so, remove from study session
                      if (student.session != "") {
                        await widget.controller.removeUserFromSession(student.session, student.sessionKey);
                      }
                      // Check is their are any sessions that they OWN and remove the session
                      if (student.ownedSessionKey != "") {
                        await widget.controller.removeUserFromSession(student.session, student.sessionKey);
                        widget.controller.removeSession(student.ownedSessionKey);
                      }
                      widget.controller.updateUserProfile({"institution": institute['name']});
                      widget.controller.setInstitution(institute['name']);
                      
                      // TODO: Delete creation of dummy data in final product
                      Map sessions = await widget.controller.getInstitute();
                      if (sessions.isEmpty){
                        // Create dummy data
                        var numOfSessions = Random().nextInt(9) + 6;
                        widget.controller.createNSampleSessions(numOfSessions);
                      }
                      _proceedToNextPage();
                    }, 
                    style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      shadowColor: Colors.transparent,
                      backgroundColor: const Color.fromARGB(255, 28, 125, 204),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.0)
                        )
                      )
                    ),
                    child: const Text(
                      "Yes",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15
                      )
                    ),
                  ),
                )
              ]
            )
          ],
        );
      }
    );
  }
  
  /// Function to retrieve list of institution from API, we add checks 
  /// between every async operation to ensure best search results
  void _getListOfInstitutions(String value) async {
    // Encode the query to be URL-friendly
    var encoded = Uri.encodeFull(value);

    // Cancel search if user is still typing
    if (searching || query.isEmpty){
      return;
    }
    var response = await http.get(
      Uri.parse(
        'http://universities.hipolabs.com/search?name=$encoded&limit=15'
      )
    );
    // Cancel search if user is still typing
    if (searching || query.isEmpty){
      return;
    }

    List json = jsonDecode(response.body);
    List<Map<dynamic, dynamic>> list = [];

    // Compile information from json
    for(var entry in json){
      Map inst = {};

      inst['name'] = entry['name'];
      inst['web_pages'] = (entry['web_pages'] as List).first;

      // Cancel search if user is still typing
      if (searching || query.isEmpty){
        return;
      }
      String? logoUrl = await _getLogoOfInstitution(entry['name']);
      // Cancel search if user is still typing
      if (searching || query.isEmpty){
        return;
      }

      if (logoUrl != null){
        inst['logo'] = logoUrl;
      }
      
      list.add(inst);
    }

    setState(() {
      listOfInstitutions = list;
      loading = false;
    });
  }

  /// Function to get logo of each institution if available
  Future<String?> _getLogoOfInstitution(String value) async {
    // Encode name of institution to be URL-friendly
    var encoded = Uri.encodeFull(value);
    var response = await http.get(
        Uri.parse('https://autocomplete.clearbit.com/v1/companies/suggest?query=$encoded')
    );
    var json = jsonDecode(response.body);

    for(Map entry in json){
      // Match entry by name
      if(entry['name'] == value){
        String url = entry['logo'];

        // Check if logo exists
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200){
          return null;
        }

        // If logo exists, check if size is big enough
        try{
          Image? logo = Image.network(url);
          Size logoSize = await _getImageSize(logo);
          
          if (logoSize.height >= 32 && logoSize.width >= 32){
            return url;
          }
          else{
            return null;
          }
        }
        catch (err){
          return null;
        }
      }
    }
    return null;
  }
  
  /// Function to get size of image from network
  Future<Size> _getImageSize(Image logo) {
    Completer<ui.Size> completer = Completer<ui.Size>();
    logo.image.resolve(
      const ImageConfiguration()
    ).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          Size size = Size(info.image.width.toDouble(), info.image.height.toDouble());
          return completer.complete(size);
        }
      )
    );
    return completer.future;
  }
  
  /// Function to navigate to the right pages depending on the user's activity
  void _proceedToNextPage() {
    switch (widget.previousPage){
      // Pop current page to go back to Profile creation page
      case 'Profile':
        Navigator.of(context).popUntil(ModalRoute.withName("/Profile"));
      break;
      case 'Register':
        // Pop current page and go to main page
        if (context.mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement( // pushReplacement prevents user from going back
            MaterialPageRoute(
              builder: (context) => const AuthPage())
          );
        }
        // Go to profile creation page
        if (context.mounted){
          Navigator.of(context).push( // push to allow users to exit the page by going back
            MaterialPageRoute(
              builder: (context) => CreateProfilePage(widget.controller))
          );  
        }
      break;
      case 'Login':
      default:
        // Pop current page and go to main page
        if (context.mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement( // pushReplacement prevents user from going back
            MaterialPageRoute(
              builder: (context) => const AuthPage())
          );
        }
    }
    
  }
}