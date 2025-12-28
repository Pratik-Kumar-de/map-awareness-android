import 'package:flutter/material.dart';

/// Animation constants.
/// Centralized configuration for app-wide animation durations and easing curves.
class AppAnimations {
  // Durations.
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  
  // Curves.
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve emphasizedCurve = Curves.easeOutCubic;
  static const Curve deceleratedCurve = Curves.easeOut;
}
