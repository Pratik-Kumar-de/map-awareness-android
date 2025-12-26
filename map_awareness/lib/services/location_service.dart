import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

/// Gets user's current location as "lat,lng" string
/// Returns null if location unavailable or platform unsupported
Future<String?> getCurrentUserLocation() async {
  try {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // Check and request permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    // Get current position with web-compatible settings
    final position = await Geolocator.getCurrentPosition(
      locationSettings: kIsWeb
          ? const LocationSettings(accuracy: LocationAccuracy.medium)
          : const LocationSettings(accuracy: LocationAccuracy.medium),
    );
    return '${position.latitude},${position.longitude}';
  } catch (e) {
    // Handles "Unsupported operation" on web or other platform errors
    return null;
  }
}

/// Calculates distance between two coordinates in km (Haversine formula)
double distanceInKm(double lat1, double lng1, double lat2, double lng2) {
  const double earthRadius = 6371; // km
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * 
      math.sin(dLng / 2) * math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

double _toRadians(double deg) => deg * math.pi / 180;
