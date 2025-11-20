//classes wich contains the data from the APIs

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