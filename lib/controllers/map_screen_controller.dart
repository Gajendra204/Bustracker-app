import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_manager.dart';
import '../services/stop_navigation_service.dart';
import '../services/token_service.dart';

// managing the state and business logic of the integrated map screen
class MapScreenController extends ChangeNotifier {
  final LocationManager _locationManager;
  final StopNavigationService _stopNavigationService;

  // State variables
  LatLng? _currentLocation;
  Map<String, dynamic>? _nextStop;
  List<dynamic> _students = [];
  bool _isStudentsExpanded = false;
  List<LatLng> _allStopLocations = [];
  bool _isTracking = false;
  String? _driverId;

  // Getters
  LatLng? get currentLocation => _currentLocation;
  Map<String, dynamic>? get nextStop => _nextStop;
  List<dynamic> get students => _students;
  bool get isStudentsExpanded => _isStudentsExpanded;
  List<LatLng> get allStopLocations => _allStopLocations;
  bool get isTracking => _isTracking;
  String? get driverId => _driverId;

  MapScreenController({
    LocationManager? locationManager,
    StopNavigationService? stopNavigationService,
  })  : _locationManager = locationManager ?? LocationManager(),
        _stopNavigationService = stopNavigationService ?? StopNavigationService();

  // Initialize the map screen with route data
  Future<void> initialize(Map<String, dynamic> routeData) async {
    try {
      // Get driver ID
      _driverId = await TokenService.getDriverId();

      // Initialize location manager
      await _locationManager.initialize();

      // Process route data
      await _processRouteData(routeData);

      // Start location tracking
      await _startLocationTracking();
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Process and extract data from route information
  Future<void> _processRouteData(Map<String, dynamic> routeData) async {
    final route = routeData['route'];
    final students = routeData['students'] as List<dynamic>? ?? [];

    _students = students;

    if (route != null && route['stops'] != null) {
      final stops = route['stops'] as List<dynamic>;
      stops.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

      // Extract all stop locations for markers
      _allStopLocations = stops
          .where((stop) => stop['location'] != null)
          .map(
            (stop) => LatLng(
              stop['location']['lat'].toDouble(),
              stop['location']['lng'].toDouble(),
            ),
          )
          .toList();

      // Set first stop as next stop
      if (stops.isNotEmpty) {
        _stopNavigationService.initializeStops(stops);
        _nextStop = _stopNavigationService.getCurrentStop();
      }
    }
  }

  // Start location tracking
  Future<void> _startLocationTracking() async {
    if (_driverId == null) return;

    final position = await _locationManager.getCurrentLocation();
    if (position != null) {
      _currentLocation = LatLng(position.latitude, position.longitude);
    }

    final started = await _locationManager.startTracking(_driverId!);
    _isTracking = started;

    // Listen to location updates
    _locationManager.locationStream.listen((position) {
      _currentLocation = LatLng(position.latitude, position.longitude);
      notifyListeners();
    });
  }

  // Toggle students panel expansion
  void toggleStudentsExpansion() {
    _isStudentsExpanded = !_isStudentsExpanded;
    notifyListeners();
  }

  // Mark current stop as complete and move to next
  void markStopComplete() {
    final nextStopData = _stopNavigationService.moveToNextStop();
    _nextStop = nextStopData;
    notifyListeners();
  }

  // Get students at a specific stop
  List<Map<String, dynamic>> getStudentsAtStop(String stopName) {
    return _students
        .where(
          (student) =>
              student['pickupLocation'] == stopName ||
              student['dropoffLocation'] == stopName,
        )
        .cast<Map<String, dynamic>>()
        .toList();
  }

  // Stop tracking and cleanup
  Future<void> stopTracking() async {
    await _locationManager.stopTracking();
    _isTracking = false;
    notifyListeners();
  }

  // Logout and cleanup
  Future<void> logout() async {
    await stopTracking();
    await TokenService.clearAllTokens();
  }

  @override
  void dispose() {
    _locationManager.dispose();
    super.dispose();
  }
}
