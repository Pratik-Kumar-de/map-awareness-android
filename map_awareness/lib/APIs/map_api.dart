import 'dart:convert';
import 'package:flutter_curl/flutter_curl.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

//example URL bremen to Hamburg
//"https://graphhopper.com/api/1/route?point=53.084,8.798&point=53.538,10.033&profile=car&locale=de&calc_points=true&key=95c5067c-b1d5-461f-823a-8ae69a6f6997"
String mapURLStart = "https://graphhopper.com/api/1/route?point=";
String point2 = "&point=";
String mapURLend = "&details=street_name&details=street_ref&profile=car&locale=de&calc_points=true&key=95c5067c-b1d5-461f-823a-8ae69a6f6997";

//checking if its an Autobahn URL
String autobahnList1 = "https://verkehr.autobahn.de/";
String autobahnList2 = "/autobahn/";

List<String> routeStreetNames = [];

/// String name, PointLatLng start, PointLatLng end
class AutobahnClass{
  final String name;
  final PointLatLng start;
  final PointLatLng end;

  AutobahnClass({
    required this.name,
    required this.start,
    required this.end
  });
}

List<AutobahnClass> listOfAutobahnenAndCoordinates = [];

///gets all street names in a car route between 2 coordinate points
Future<List<AutobahnClass>> routing(String startingPoint, String endPoint)
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

    //decodes Polyline into list of PointLatLng pairs
    List<PointLatLng> result = PolylinePoints().decodePolyline(data["paths"][0]["points"]);

    //get list of Autobahn
     Map<String, dynamic> listOfAutobahnNames = await isAutobahn();

    //iterate trough details.street_refs to get streetnames
    for(int i = 0; i < data["paths"][0]["details"]["street_ref"].length; i++){

      //check for null
      if(data["paths"][0]["details"]["street_ref"][i][2] == null){

      }      
      else{
        String streetName = data["paths"][0]["details"]["street_ref"][i][2];
        
        //trim spaces in String
        String spacelessName = streetName.replaceAll(' ', "");

        //if streetname is autobahn
        if(listOfAutobahnNames["roads"].contains(spacelessName)){
          listOfAutobahnenAndCoordinates.add(AutobahnClass(
            name: spacelessName,
            start: result[data["paths"][0]["details"]["street_ref"][i][0]],
            end: result[data["paths"][0]["details"]["street_ref"][i][1]]
            )
          );
        }
      }
    }
    
    //print(routeStreetNames);
    return listOfAutobahnenAndCoordinates;
  }
  else {
    //print("Request failed with status: ${res.statusCode}");
    return listOfAutobahnenAndCoordinates;
  }
}

///returns a list of every Autobahn
Future<Map<String, dynamic>> isAutobahn() async {
  String roadname = "o";
  String mapURL = autobahnList1 + roadname + autobahnList2;

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
  Map<String, dynamic> data = {};

  //transforms list of int into Map
  if (res.statusCode == 200) {
    //worked
    String jsonString = res.text();
    data = jsonDecode(jsonString);

    return data;
  }else{
    //print("error");
  }

  return data;
}
