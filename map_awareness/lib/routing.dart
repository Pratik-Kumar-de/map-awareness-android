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


Future<List<RoutingWidgetData>> GetAllRoadworksData(String coordinate1, String coordinate2){
  List<RoutingWidgetData> listOfRoadworks = [];
  Future<List<dynamic>> streetNames = routing(coordinate1, coordinate2);
  
  for(int i = 0; i < streetNames.size; i++){
    //check if streetname is Autobahn
    //get raodworks from Autobahn
    //get only roadwokrs which are in coordinates
  }
  return listOfRoadworks;
}