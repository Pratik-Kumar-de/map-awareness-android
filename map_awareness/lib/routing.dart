import 'dart:math';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:map_awareness/APIs/autobahn_api.dart';
import 'package:map_awareness/APIs/map_api.dart';

///contains all data from entrys of the Route feature
class RoutingWidgetData{
  final String title;
  final List<dynamic> description;

  RoutingWidgetData({
    required this.title,
    required this.description
  });
}


Future<List<RoutingWidgetData>> getAllRoadworksData(String coordinate1, String coordinate2) async {
  List<RoutingWidgetData> listOfRoadworks = [];

  List<AutobahnClass> listOfAutobahn = await routing(coordinate1, coordinate2);
  
  for(int i = 0; i < listOfAutobahn.length; i++){
    
    //get all roadworks from Autobahn
    List<AutobahnRoadworks> fullListOfRoadworks = [];
    fullListOfRoadworks = await getAllAutobahnRoadworks(listOfAutobahn[i].name);

    //check if roadwork is between coordinates
    //calculate the Radius between the Autobahn coordinates
    double radius = coordinateVectorLength(listOfAutobahn[i].start, listOfAutobahn[i].end) / 2;

    double centerLat = (listOfAutobahn[i].start.latitude + listOfAutobahn[i].end.latitude) / 2;
    double centerLng = (listOfAutobahn[i].start.longitude + listOfAutobahn[i].end.longitude) / 2;

    PointLatLng center = PointLatLng(centerLat, centerLng);

    //checks if roadwork is within radius
    for(int j = 0; j < fullListOfRoadworks.length; j++){

      List<PointLatLng> pointsOfRoadWorks = getCoordinatesFromExtent(fullListOfRoadworks[j].extent);

      double vectorStart = coordinateVectorLength(center, pointsOfRoadWorks[0]);
      double vectorEnd = coordinateVectorLength(center, pointsOfRoadWorks[1]);

      if(vectorStart <= radius || vectorEnd <= radius){
        //add roadwork to List
        //print(" found Roadwork!");
        listOfRoadworks.add(RoutingWidgetData(
          title: fullListOfRoadworks[j].title,
           description: fullListOfRoadworks[j].description));
      }
      //else outside of route and ignore roadwork and ignore
    }
    //get only roadwokrs which are in coordinates
  }
  return listOfRoadworks;
}

///calculates the length of the vector between the 2 coordinates
double coordinateVectorLength(PointLatLng pointA, PointLatLng pointB){
  double vectorLat = pointB.latitude - pointA.latitude;
  double vectorLng = pointB.longitude - pointA.longitude;

  double vectorLength = sqrt(vectorLat * vectorLat + vectorLng * vectorLng);

  return vectorLength;
}

///gets coordinates from Autobahn.roadworks.extent
List<PointLatLng> getCoordinatesFromExtent(String stringExtent){
  List<PointLatLng> list = [];
  List<String> stringList = stringExtent.split(',');

  list.add(PointLatLng(double.parse(stringList[0]), double.parse(stringList[1])));
  list.add(PointLatLng(double.parse(stringList[2]), double.parse(stringList[3])));

  return list;
}