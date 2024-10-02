import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class InstitutionsPage extends StatefulWidget{
  const InstitutionsPage({super.key});

  @override
  State<StatefulWidget> createState() => _InstituionsPage();
}

class _InstituionsPage extends State<InstitutionsPage>{
  TextEditingController institutionController = TextEditingController();
  List<Map<dynamic, dynamic>> listOfInstitutions = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Booth!'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
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
                onSubmitted: (value) => _getListOfInstitutions(value)
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: listOfInstitutions.length,
              itemBuilder: (context, index){
                var institute = listOfInstitutions[index];
                List websites = institute['web_pages'];
                return ListTile(
                  leading: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      border: Border.all(
                        color: Colors.red
                      )
                    ),
                    child: institute.containsKey('logo') ? 
                    Image.network(institute['logo'], fit: BoxFit.contain)
                    : const SizedBox.shrink(),
                  ),
                  title: Text(
                    institute['name'],
                    style:const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(websites.join('\n')),
                );
              },
            ),
          )
        ],
      ),
    );
  }
  
  void _getListOfInstitutions(String value) async {
    var encoded = Uri.encodeFull(value);
    var response = await http.get(
      Uri.parse(
        'http://universities.hipolabs.com/search?name=$encoded'));
    List json = jsonDecode(response.body);
    List<Map<dynamic, dynamic>> list = [];
    for(var entry in json){
      Map inst = {};

      inst['name'] = entry['name'];
      inst['web_pages'] = entry['web_pages'];

      String? logoUrl = await _getLogoOfInstitution(entry['name']);
      if (logoUrl != null){
        inst['logo'] = logoUrl;
      }
      
      list.add(inst);
    }
    setState(() {
      listOfInstitutions = list;
    });
  }

  Future<String?> _getLogoOfInstitution(String value) async {
    var encoded = Uri.encodeFull(value);
    var response = await http.get(
        Uri.parse('https://autocomplete.clearbit.com/v1/companies/suggest?query=$encoded')
    );
    var json = jsonDecode(response.body);
    for(Map entry in json){
      if(entry['name'] == value){
        return entry['logo'];
      }
    }
    return null;
  }
}