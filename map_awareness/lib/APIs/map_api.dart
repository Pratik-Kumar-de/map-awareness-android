import 'dart:convert';
import 'package:flutter_curl/flutter_curl.dart';

List<String> routeStreetNames = [];

//example URL bremen to Hamburg
//"https://graphhopper.com/api/1/route?point=53.084,8.798&point=53.538,10.033&profile=car&locale=de&calc_points=true&key=95c5067c-b1d5-461f-823a-8ae69a6f6997"
String mapURLStart = "https://graphhopper.com/api/1/route?point=";
String point2 = "&point=";
String mapURLend = "&profile=car&locale=de&calc_points=true&key=95c5067c-b1d5-461f-823a-8ae69a6f6997";

//gets all street names in a car route between 2 coordinate points
Future<List<String>> routing(String startingPoint, String endPoint)
async {

String mapURL = mapURLStart + startingPoint + point2 + endPoint +mapURLend;
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
      url: mapURL,
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
    
    //print(routeStreetNames);
    return routeStreetNames;
  }
  else {
    return routeStreetNames;
  //print("Request failed with status: ${res.statusCode}");
  }
}