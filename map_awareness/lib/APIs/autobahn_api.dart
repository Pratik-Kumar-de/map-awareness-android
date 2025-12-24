import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:map_awareness/services/cache_service.dart';

/// Roadwork data from Autobahn API
class AutobahnRoadworks {
  final String extent;
  final String subtitle;
  final String title;
  final String startTimestamp;
  final List<dynamic> description;
  final String displayType;
  final bool isBlocked;
  final String? length;
  final String? speedLimit;
  final String? maxWidth;
  final String? impactFrom;
  final String? impactTo;

  AutobahnRoadworks({
    required this.extent,
    required this.subtitle,
    required this.title,
    required this.startTimestamp,
    required this.description,
    required this.displayType,
    this.isBlocked = false,
    this.length,
    this.speedLimit,
    this.maxWidth,
    this.impactFrom,
    this.impactTo,
  });

  /// Parse structured info from description array
  static Map<String, String?> parseDescription(List<dynamic> desc) {
    String? length, speed, width;
    for (final line in desc) {
      final s = line.toString();
      final match = RegExp(r'Länge:\s*([\d.,]+\s*km)').firstMatch(s);
      if (match != null) length = match.group(1);
      final speedMatch = RegExp(r'Max\.\s*(\d+)\s*km/h').firstMatch(s);
      if (speedMatch != null) speed = '${speedMatch.group(1)} km/h';
      final widthMatch = RegExp(r'Durchfahrtbreite:\s*([\d.,]+\s*m)').firstMatch(s);
      if (widthMatch != null) width = widthMatch.group(1);
    }
    return {'length': length, 'speed': speed, 'width': width};
  }
}

String autobahnURL1 = "https://verkehr.autobahn.de/o/autobahn/";
String autobahnURL2 = "/services/roadworks";

///gets all roadworks for an Autobahn (cached for 15 minutes in-memory)
Future<List<AutobahnRoadworks>> getAllAutobahnRoadworks(String autobahnName) async {
  // Check in-memory cache first
  final cachedData = CacheService.getCachedRoadworks(autobahnName);
  if (cachedData != null) {
    return cachedData.map((e) => AutobahnRoadworks(
      extent: e['extent'],
      subtitle: e['subtitle'],
      title: e['title'],
      description: e['description'],
      startTimestamp: e['startTimestamp'],
      displayType: e['displayType'],
      isBlocked: e['isBlocked'] ?? false,
      length: e['length'],
      speedLimit: e['speedLimit'],
      maxWidth: e['maxWidth'],
      impactFrom: e['impactFrom'],
      impactTo: e['impactTo'],
    )).toList();
  }

  List<AutobahnRoadworks> listRoadworks = [];
  List<Map<String, dynamic>> cacheData = [];

  final res = await http.get(Uri.parse(autobahnURL1 + autobahnName + autobahnURL2));

  if (res.statusCode == 200) {
    Map<String, dynamic> data = jsonDecode(res.body);

    for(int i = 0; i < data["roadworks"].length; i++){
      final rw = data["roadworks"][i];
      final desc = rw["description"] as List<dynamic>? ?? [];
      final parsed = AutobahnRoadworks.parseDescription(desc);
      final impact = rw["impact"] as Map<String, dynamic>?;
      
      final roadwork = AutobahnRoadworks(
        extent: rw["extent"] ?? "",
        subtitle: rw["subtitle"] ?? "",
        title: rw["title"] ?? "",
        description: desc,
        startTimestamp: rw["startTimestamp"] ?? "0",
        displayType: rw["display_type"] ?? "",
        isBlocked: rw["isBlocked"] == "true",
        length: parsed['length'],
        speedLimit: parsed['speed'],
        maxWidth: parsed['width'],
        impactFrom: impact?['lower'],
        impactTo: impact?['upper'],
      );
      listRoadworks.add(roadwork);
      
      cacheData.add({
        'extent': roadwork.extent,
        'subtitle': roadwork.subtitle,
        'title': roadwork.title,
        'description': roadwork.description,
        'startTimestamp': roadwork.startTimestamp,
        'displayType': roadwork.displayType,
        'isBlocked': roadwork.isBlocked,
        'length': roadwork.length,
        'speedLimit': roadwork.speedLimit,
        'maxWidth': roadwork.maxWidth,
        'impactFrom': roadwork.impactFrom,
        'impactTo': roadwork.impactTo,
      });
    }
    
    CacheService.cacheRoadworks(autobahnName, cacheData);
  }
  return listRoadworks;
}