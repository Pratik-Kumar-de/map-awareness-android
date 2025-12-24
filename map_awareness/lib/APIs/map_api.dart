import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:map_awareness/services/cache_service.dart';

String mapURLStart = "https://graphhopper.com/api/1/route?point=";
String point2 = "&point=";
String mapURLend = "&details=street_name&details=street_ref&profile=car&locale=de&calc_points=true&key=95c5067c-b1d5-461f-823a-8ae69a6f6997";

String autobahnList1 = "https://verkehr.autobahn.de/";
String autobahnList2 = "/autobahn/";

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

///gets all street names in a car route between 2 coordinate points
Future<List<AutobahnClass>> routing(String startingPoint, String endPoint) async {
  List<AutobahnClass> listOfAutobahnenAndCoordinates = [];

  // Check cache first
  final cachedData = await CacheService.getCachedRouteResponse(startingPoint, endPoint);
  Map<String, dynamic>? data;

  if (cachedData != null) {
    data = cachedData;
  } else {
    String mapURL = mapURLStart + startingPoint + point2 + endPoint + mapURLend;
    final res = await http.get(Uri.parse(mapURL));
    
    if (res.statusCode == 200) {
      data = jsonDecode(res.body);
      await CacheService.cacheRouteResponse(startingPoint, endPoint, data!);
    } else {
      return listOfAutobahnenAndCoordinates;
    }
  }

  List<PointLatLng> result = PolylinePoints().decodePolyline(data!["paths"][0]["points"]);

  Map<String, dynamic> listOfAutobahnNames = await isAutobahn();

  for(int i = 0; i < data["paths"][0]["details"]["street_ref"].length; i++){
    if(data["paths"][0]["details"]["street_ref"][i][2] == null){
    }      
    else{
      String streetName = data["paths"][0]["details"]["street_ref"][i][2];
      String spacelessName = streetName.replaceAll(' ', "");

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
  return listOfAutobahnenAndCoordinates;
}

///returns a list of every Autobahn (cached for 24 hours)
Future<Map<String, dynamic>> isAutobahn() async {
  // Check cache first
  final cachedData = await CacheService.getCachedAutobahnList();
  if (cachedData != null) {
    return cachedData;
  }

  String roadname = "o";
  String mapURL = autobahnList1 + roadname + autobahnList2;

  final res = await http.get(Uri.parse(mapURL));
  
  Map<String, dynamic> data = {};

  if (res.statusCode == 200) {
    data = jsonDecode(res.body);
    await CacheService.cacheAutobahnList(data);
    return data;
  }

  return data;
}
