import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State object holding current start and end location inputs.
class RouteInputState {
  final String start;
  final String end;
  
  const RouteInputState({this.start = '', this.end = ''});
  
  /// Creates a copy of the state with optional updated fields.
  RouteInputState copyWith({String? start, String? end}) {
    return RouteInputState(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}

/// Notifier managing route input fields and their updates.
class RouteInputNotifier extends StateNotifier<RouteInputState> {
  RouteInputNotifier() : super(const RouteInputState(start: 'Bremen', end: 'Hamburg'));

  /// Updates the start location text.
  void setStart(String value) => state = state.copyWith(start: value);
  /// Updates the end location text.
  void setEnd(String value) => state = state.copyWith(end: value);
  /// Swaps the start and end values.
  void swap() => state = state.copyWith(start: state.end, end: state.start);
}

final routeInputProvider = StateNotifierProvider<RouteInputNotifier, RouteInputState>((ref) => RouteInputNotifier());
