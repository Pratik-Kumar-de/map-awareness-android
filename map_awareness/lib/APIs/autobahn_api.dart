import 'dart:convert';
import 'package:flutter_curl/flutter_curl.dart';

class AutobahnRoadworks{
  final String identifier;
  final String isBlocked;
  final String extent;
  //final String point;
  final String startLcPosition;
  //final String impact;
  final String subtitle;
  final String title;
  final List<dynamic> description;


  AutobahnRoadworks({
    required this.identifier,
    required this.isBlocked,
    required this.extent,
    //required this.point,
    required this.startLcPosition,
    required this.subtitle,
    required this.title,
    required this.description
  });
}

//example url for A1
//"https://verkehr.autobahn.de/o/autobahn/A1/services/roadworks"
List<AutobahnRoadworks> listRoadworks = [];

String AutobahnURL1 = "https://verkehr.autobahn.de/o/autobahn/";
String AutobahnURL2 = "/services/roadworks";


//Test method
Future<void> testAutobahnAPI(String autobahnName)
async {

  // Initialize client
Client client = Client(
      verbose: true,
      interceptors: [
        // HTTPCaching(),
      ],
    );
await client.init();

// Send request
final res = await client.send(Request(
      method: "GET",
      url: AutobahnURL1 + autobahnName + AutobahnURL2,
      headers: {

      },
      )
  );

  //transforms list of int into Map
  if (res.statusCode == 200) {
  String jsonString = res.text();
  Map<String, dynamic> data = jsonDecode(jsonString);
  //print("Parsed JSON data: $data");
  //print(data["roadworks"][0]["identifier"]);
  for(int i = 0; i < data["roadworks"].length; i++){
    listRoadworks.add(
      AutobahnRoadworks(
        identifier: data["roadworks"][i]["identifier"],
         isBlocked: data["roadworks"][i]["isBlocked"],
          extent: data["roadworks"][i]["extent"],
           //point: data["roadworks"][i]["data"],
            startLcPosition: data["roadworks"][i]["startLcPosition"],
             subtitle: data["roadworks"][i]["subtitle"],
              title: data["roadworks"][i]["title"],
               description: data["roadworks"][i]["description"]
              )
    );
  }



} else {
  //print("Request failed with status: ${res.statusCode}");
}

print(listRoadworks[0].title);
}