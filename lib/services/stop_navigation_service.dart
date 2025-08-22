import 'package:latlong2/latlong.dart';

// Manages stop navigation and progression logic
class StopNavigationService {
  List<dynamic> _stops = [];
  int _currentStopIndex = 0;

  // Initialize the service with route stops
  void initializeStops(List<dynamic> stops) {
    _stops = List.from(stops);
    _stops.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));
    _currentStopIndex = 0;
  }

  // Get the current stop
  Map<String, dynamic>? getCurrentStop() {
    if (_stops.isEmpty || _currentStopIndex >= _stops.length) {
      return null;
    }
    return _stops[_currentStopIndex];
  }

  // Get the next stop location as LatLng
  LatLng? getCurrentStopLocation() {
    final currentStop = getCurrentStop();
    if (currentStop == null || currentStop['location'] == null) {
      return null;
    }

    final location = currentStop['location'];
    if (location['lat'] == null || location['lng'] == null) {
      return null;
    }

    return LatLng(
      location['lat'].toDouble(),
      location['lng'].toDouble(),
    );
  }

  // Move to the next stop in the route
  Map<String, dynamic>? moveToNextStop() {
    if (_stops.isEmpty) return null;

    _currentStopIndex++;
    
    if (_currentStopIndex >= _stops.length) {
      // All stops completed
      return null;
    }

    return getCurrentStop();
  }

  // Check if there are more stops remaining
  bool hasMoreStops() {
    return _currentStopIndex < _stops.length;
  }

  // Get the total number of stops
  int getTotalStops() {
    return _stops.length;
  }

  // Get the current stop index (0-based)
  int getCurrentStopIndex() {
    return _currentStopIndex;
  }

  // Get remaining stops count
  int getRemainingStopsCount() {
    return _stops.length - _currentStopIndex;
  }

  // Get all stop locations as LatLng list
  List<LatLng> getAllStopLocations() {
    return _stops
        .where((stop) => stop['location'] != null)
        .map((stop) => LatLng(
              stop['location']['lat'].toDouble(),
              stop['location']['lng'].toDouble(),
            ))
        .toList();
  }

  // Reset to the first stop
  void resetToFirstStop() {
    _currentStopIndex = 0;
  }

  // Get stop by index
  Map<String, dynamic>? getStopByIndex(int index) {
    if (index < 0 || index >= _stops.length) {
      return null;
    }
    return _stops[index];
  }

  // Find stop index by stop ID
  int findStopIndexById(String stopId) {
    return _stops.indexWhere((stop) => stop['_id'] == stopId);
  }

  // Get progress percentage 
  double getProgressPercentage() {
    if (_stops.isEmpty) return 0.0;
    return _currentStopIndex / _stops.length;
  }
}
