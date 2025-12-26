import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:map_awareness/services/cache_service.dart';
import 'package:map_awareness/models/routing_data.dart';
import 'package:map_awareness/models/saved_route.dart';
import 'package:map_awareness/APIs/map_api.dart';
import 'dart:math' as math;


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

/// Helper to safely parse boolean from dynamic input (handles bool, String, num)
bool _safeBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value > 0; // 1 or 1.0 is true
  return false;
}

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
      isBlocked: _safeBool(e['isBlocked']),
      length: e['length']?.toString(),
      speedLimit: e['speedLimit']?.toString(),
      maxWidth: e['maxWidth']?.toString(),
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
      
      final roadwork = AutobahnRoadworks(
        extent: rw["extent"] ?? "",
        subtitle: rw["subtitle"] ?? "",
        title: rw["title"] ?? "",
        description: desc,
        startTimestamp: rw["startTimestamp"] ?? "0",
        displayType: rw["display_type"] ?? "",
        isBlocked: _safeBool(rw["isBlocked"]),
        length: parsed['length'],
        speedLimit: parsed['speed'],
        maxWidth: parsed['width'],
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
      });
    }
    
    CacheService.cacheRoadworks(autobahnName, cacheData);
  }
  return listRoadworks;
}

/// Converts AutobahnClass list to AutobahnData for storage
List<AutobahnData> autobahnClassToData(List<AutobahnClass> list) {
  return list.map((a) => AutobahnData(
    name: a.name,
    startLat: a.start.latitude,
    startLng: a.start.longitude,
    endLat: a.end.latitude,
    endLng: a.end.longitude,
  )).toList();
}

/// Fetches roadworks for a route defined by start/end coordinates
Future<List<List<RoutingWidgetData>>> getRoutingWidgetData(String start, String end) async {
  final segments = await routing(start, end);
  return _fetchRoadworksForSegments(segments.map((s) => AutobahnData(
    name: s.name,
    startLat: s.start.latitude,
    startLng: s.start.longitude,
    endLat: s.end.latitude,
    endLng: s.end.longitude,
  )).toList());
}

/// Fetches roadworks for saved route segments
Future<List<List<RoutingWidgetData>>> getRoutingWidgetDataFromCache(List<AutobahnData> segments) async {
  return _fetchRoadworksForSegments(segments);
}

Future<List<List<RoutingWidgetData>>> _fetchRoadworksForSegments(List<AutobahnData> segments) async {
  final List<RoutingWidgetData> ongoing = [];
  final List<RoutingWidgetData> shortTerm = [];
  final List<RoutingWidgetData> future = [];

  final Set<String> processedAutobahns = {};
  
  for (final segment in segments) {
    if (!processedAutobahns.add(segment.name)) continue;
    
    final allRw = await getAllAutobahnRoadworks(segment.name);
    for (final rw in allRw) {
      if (!_isRoadworkInSegment(rw, segment)) continue;
      
      final data = _convertToWidgetData(rw);
      if (rw.displayType == 'SHORT_TERM_ROADWORKS') {
        shortTerm.add(data);
      } else if (rw.startTimestamp != '0' && DateTime.tryParse(rw.startTimestamp)?.isAfter(DateTime.now()) == true) {
        future.add(data);
      } else {
        ongoing.add(data);
      }
    }
  }

  return [ongoing, shortTerm, future];
}

bool _isRoadworkInSegment(AutobahnRoadworks rw, AutobahnData segment) {
  if (rw.extent.isEmpty) return true; // Fallback to all for that road
  
  try {
    final parts = rw.extent.split('|').expand((s) => s.split(',')).toList();
    if (parts.length < 2) return true;
    
    final rwLat = double.parse(parts[0]);
    final rwLng = double.parse(parts[1]);
    
    // Simple bounding box + distance check
    final minLat = math.min(segment.startLat, segment.endLat) - 0.1;
    final maxLat = math.max(segment.startLat, segment.endLat) + 0.1;
    final minLng = math.min(segment.startLng, segment.endLng) - 0.1;
    final maxLng = math.max(segment.startLng, segment.endLng) + 0.1;
    
    return rwLat >= minLat && rwLat <= maxLat && rwLng >= minLng && rwLng <= maxLng;
  } catch (_) {
    return true;
  }
}

RoutingWidgetData _convertToWidgetData(AutobahnRoadworks rw) {
  double? lat, lng;
  try {
    final parts = rw.extent.split('|').first.split(',');
    lat = double.parse(parts[0]);
    lng = double.parse(parts[1]);
  } catch (_) {}
  
  return RoutingWidgetData(
    title: rw.title,
    subtitle: rw.subtitle,
    time: rw.startTimestamp == '0' ? 'ongoing' : rw.startTimestamp,
    displayType: rw.displayType,
    isBlocked: rw.isBlocked,
    length: rw.length,
    speedLimit: rw.speedLimit,
    maxWidth: rw.maxWidth,
    latitude: lat,
    longitude: lng,
  );
}
