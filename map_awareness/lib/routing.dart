import 'package:map_awareness/APIs/map_api.dart';

class RoutingWidgetData{
  final String title;
  final List<dynamic> description;

  //contains all data from entrys of the Route feature
  RoutingWidgetData({
    required this.title,
    required this.description
  });
}


List<RoutingWidgetData> getAllRoadworksData(String coordinate1, String coordinate2){
  List<RoutingWidgetData> listOfRoadworks = [];
  List<String> streetNames = routing(coordinate1, coordinate2) as List<String>;
  
  for(int i = 0; i < streetNames.length; i++){
    //check if streetname is Autobahn
    //get raodworks from Autobahn
    //get only roadwokrs which are in coordinates
  }
  return listOfRoadworks;
}