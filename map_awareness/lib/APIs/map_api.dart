import 'dart:convert';
import 'package:flutter_curl/flutter_curl.dart';


List<String> routeStreetNames = [];

//Test method
Future<void> testMap()
async {

  // Initialize client
  Client client = Client(
      verbose: true,
      interceptors: [
        // HTTPCaching(),
      ],
    );
  await client.init();

  // Send request //point=53.084,8.798&point=53.538,10.033 coordinates from bremen to hamburg
  final res = await client.send(Request(
      method: "GET",
      url: "https://graphhopper.com/api/1/route?point=53.084,8.798&point=53.538,10.033&profile=car&locale=de&calc_points=true&key=95c5067c-b1d5-461f-823a-8ae69a6f6997",
      headers: {

      },
    )
  );
  //print(res.text());
  
  //transforms list of int into Map
  if (res.statusCode == 200) {
    String jsonString = res.text();
    Map<String, dynamic> data = jsonDecode(jsonString);

    //print(data["paths"][0]["instructions"][1]["street_name"]);
    for(int i = 0; i < data["paths"][0]["instructions"].length; i++){
            
      //checking for street ref
      if(data["paths"][0]["instructions"][i]["street_ref"] != null){
        routeStreetNames.add(data["paths"][0]["instructions"][i]["street_ref"]);
      }
      //checking for street_destination_ref
      else if(data["paths"][0]["instructions"][i]["street_destination_ref"] != null){
        routeStreetNames.add(data["paths"][0]["instructions"][i]["street_destination_ref"]);
      }
      else{
        //might be empty
        routeStreetNames.add(data["paths"][0]["instructions"][i]["street_name"]);
      }
    }
    print(routeStreetNames);
  }
  else {

  //print("Request failed with status: ${res.statusCode}");
  }
}