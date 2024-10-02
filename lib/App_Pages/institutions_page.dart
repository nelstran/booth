import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;

class InstitutionsPage extends StatefulWidget{
  const InstitutionsPage({super.key});

  @override
  State<StatefulWidget> createState() => _InstituionsPage();
}

class _InstituionsPage extends State<InstitutionsPage>{
  TextEditingController institutionController = TextEditingController();
  List<Map<dynamic, dynamic>> listOfInstitutions = [];
  Timer? _debounce;
  bool loading = false;
  bool searching = false;

  /// Only start searching after the user has stopped
  /// typing after a certain duration, currently 800ms
  _onSearchChanged(String value){
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
    _debounce = Timer(const Duration(milliseconds: 800), (){
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

              return ListTile(
                visualDensity: const VisualDensity(
                  vertical: 3
                  ),
                leading: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(106, 78, 78, 78),
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.0)
                    )
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 70,
                    width: 70,
                    child: Image.network(
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
                    )
                  ),
                ),
                title: Text(
                  institute['name'],
                  style:const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(website),
              );
            },
      ),
    );
  }
  
  /// Function to retrieve list of institution from API
  void _getListOfInstitutions(String value) async {
    // Encode the query to be URL-friendly
    var encoded = Uri.encodeFull(value);
    var response = await http.get(
      Uri.parse(
        'http://universities.hipolabs.com/search?name=$encoded&limit=15'
      )
    );
    List json = jsonDecode(response.body);
    List<Map<dynamic, dynamic>> list = [];

    // Compile information from json
    for(var entry in json){
      Map inst = {};

      inst['name'] = entry['name'];
      inst['web_pages'] = (entry['web_pages'] as List).first;

      String? logoUrl = await _getLogoOfInstitution(entry['name']);
      if (logoUrl != null){
        inst['logo'] = logoUrl;
      }
      
      list.add(inst);
    }

    // Cancel search if user is still typing
    if (searching){
      return;
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
          
          if (logoSize.height >= 128 && logoSize.width >= 128){
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
}