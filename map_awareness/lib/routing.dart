import 'dart:math';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:map_awareness/APIs/autobahn_api.dart';
import 'package:map_awareness/APIs/map_api.dart';
import 'package:map_awareness/models/saved_route.dart';

///contains all data from entrys of the Route feature
class RoutingWidgetData{
  final String title;
  final String subtitle;
  final String time;
  final String displayType;
  final String? length;
  final String? speedLimit;
  final String? maxWidth;
  final bool isBlocked;

  RoutingWidgetData({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.displayType,
    this.length,
    this.speedLimit,
    this.maxWidth,
    this.isBlocked = false,
  });

  String get typeLabel {
    switch (displayType) {
      case 'SHORT_TERM_ROADWORKS':
        return 'Short-term';
      case 'ROADWORKS':
        return 'Roadworks';
      default:
        return displayType.isEmpty ? 'Unknown' : displayType;
    }
  }
  
  /// Summary line: combines length, speed, width
  String get infoSummary {
    final parts = <String>[];
    if (length != null) parts.add(length!);
    if (speedLimit != null) parts.add('Max. $speedLimit');
    if (maxWidth != null) parts.add('Width: $maxWidth');
    return parts.isEmpty ? '' : parts.join(' | ');
  }
}

/// Converts AutobahnRoadworks to RoutingWidgetData
RoutingWidgetData _toWidgetData(AutobahnRoadworks rw) => RoutingWidgetData(
  title: rw.title,
  subtitle: rw.subtitle,
  time: rw.startTimestamp != '0' ? rw.startTimestamp : 'ongoing',
  displayType: rw.displayType,
  length: rw.length,
  speedLimit: rw.speedLimit,
  maxWidth: rw.maxWidth,
  isBlocked: rw.isBlocked,
);

/// Categorizes roadwork into ongoing/short-term/future lists
void _categorizeRoadwork(AutobahnRoadworks rw, List<RoutingWidgetData> ongoing, List<RoutingWidgetData> shortTerm, List<RoutingWidgetData> future) {
  final data = _toWidgetData(rw);
  if (rw.startTimestamp != '0' && rw.displayType != 'SHORT_TERM_ROADWORKS') {
    future.add(data);
  } else if (rw.displayType == 'SHORT_TERM_ROADWORKS') {
    shortTerm.add(data);
  } else {
    ongoing.add(data);
  }
}

/// Checks if roadwork is within route segment
bool _isRoadworkInSegment(AutobahnRoadworks rw, PointLatLng center, double radius) {
  final points = getCoordinatesFromExtent(rw.extent);
  return coordinateVectorLength(center, points[0]) <= radius ||
         coordinateVectorLength(center, points[1]) <= radius;
}

/// Gets all roadworks along a route
Future<List<List<RoutingWidgetData>>> getRoutingWidgetData(String coordinate1, String coordinate2) async {
  final ongoing = <RoutingWidgetData>[];
  final shortTerm = <RoutingWidgetData>[];
  final future = <RoutingWidgetData>[];

  final autobahnList = await routing(coordinate1, coordinate2);
  
  for (final autobahn in autobahnList) {
    final roadworks = await getAllAutobahnRoadworks(autobahn.name);
    final radius = coordinateVectorLength(autobahn.start, autobahn.end) / 2;
    final center = PointLatLng(
      (autobahn.start.latitude + autobahn.end.latitude) / 2,
      (autobahn.start.longitude + autobahn.end.longitude) / 2,
    );

    for (final rw in roadworks) {
      if (_isRoadworkInSegment(rw, center, radius)) {
        _categorizeRoadwork(rw, ongoing, shortTerm, future);
      }
    }
  }
  return [ongoing, shortTerm, future];
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

/// Gets roadwork data using cached Autobahn segments (skips route API call)
Future<List<List<RoutingWidgetData>>> getRoutingWidgetDataFromCache(List<AutobahnData> cachedSegments) async {
  final ongoing = <RoutingWidgetData>[];
  final shortTerm = <RoutingWidgetData>[];
  final future = <RoutingWidgetData>[];

  for (final segment in cachedSegments) {
    final roadworks = await getAllAutobahnRoadworks(segment.name);
    final start = PointLatLng(segment.startLat, segment.startLng);
    final end = PointLatLng(segment.endLat, segment.endLng);
    final radius = coordinateVectorLength(start, end) / 2;
    final center = PointLatLng(
      (segment.startLat + segment.endLat) / 2,
      (segment.startLng + segment.endLng) / 2,
    );

    for (final rw in roadworks) {
      if (_isRoadworkInSegment(rw, center, radius)) {
        _categorizeRoadwork(rw, ongoing, shortTerm, future);
      }
    }
  }
  return [ongoing, shortTerm, future];
}

///converts AutobahnClass list to AutobahnData list for storage
List<AutobahnData> autobahnClassToData(List<AutobahnClass> autobahnList) {
  return autobahnList.map((a) => AutobahnData(
    name: a.name,
    startLat: a.start.latitude,
    startLng: a.start.longitude,
    endLat: a.end.latitude,
    endLng: a.end.longitude,
  )).toList();
}