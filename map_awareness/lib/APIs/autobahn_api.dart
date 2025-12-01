import 'dart:convert';
import 'package:flutter_curl/flutter_curl.dart';
import 'package:map_awareness/api_data.dart';

List<AutobahnRoadworks> listRoadworks = [];

//Test method
Future<void> testAutobahnAPI()
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
      url: "https://verkehr.autobahn.de/o/autobahn/A1/services/roadworks",
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
//print(listRoadworks[0].title);

}