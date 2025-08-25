import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';

// parents to track live bus location 
class ParentBusTrackingService {
  static final ParentBusTrackingService _instance = ParentBusTrackingService._internal();
  factory ParentBusTrackingService() => _instance;
  ParentBusTrackingService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _locationSubscription;
  StreamSubscription<DatabaseEvent>? _statusSubscription;
  
  // Stream controllers for broadcasting updates
  final StreamController<LatLng?> _locationController = StreamController<LatLng?>.broadcast();
  final StreamController<bool> _trackingStatusController = StreamController<bool>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  // Public streams
  Stream<LatLng?> get locationStream => _locationController.stream;
  Stream<bool> get trackingStatusStream => _trackingStatusController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool _isTracking = false;
  String? _currentDriverId;
  LatLng? _lastKnownLocation;

  // Start tracking a specific driver's location
  Future<bool> startTracking(String driverId) async {
    if (_isTracking && _currentDriverId == driverId) {
      return true; 
    }

    try {
      await stopTracking();
      _currentDriverId = driverId;
      _isTracking = true;

      _locationSubscription = _database
          .child('driver_locations/$driverId')
          .onValue
          .listen(
            _handleLocationUpdate,
            onError: _handleLocationError,
          );

      _statusSubscription = _database
          .child('driver_status/$driverId')
          .onValue
          .listen(
            _handleStatusUpdate,
            onError: _handleStatusError,
          );

      return true;
    } catch (e) {
      _handleError('Failed to start tracking: ${e.toString()}');
      return false;
    }
  }

  // Stop tracking the current driver
  Future<void> stopTracking() async {
    _isTracking = false;
    _currentDriverId = null;
    _lastKnownLocation = null;

    await _locationSubscription?.cancel();
    await _statusSubscription?.cancel();
    
    _locationSubscription = null;
    _statusSubscription = null;

    // Notify listeners that tracking stopped
    _locationController.add(null);
    _trackingStatusController.add(false);
  }

  // Handle location updates 
  void _handleLocationUpdate(DatabaseEvent event) {
    try {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      
      if (data == null) {
        _handleError('No location data available');
        return;
      }

      final latitude = data['latitude'] as double?;
      final longitude = data['longitude'] as double?;
      final isActive = data['isActive'] as bool? ?? false;
      final timestamp = data['timestamp'] as int?;

      if (latitude == null || longitude == null) {
        _handleError('Invalid location data received');
        return;
      }

      // Check if location data is recent (2 minutes)
      if (timestamp != null) {
        final locationTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        final difference = now.difference(locationTime).inMinutes;
        
        if (difference > 2) {
          _handleError('Location data is outdated');
          return;
        }
      }

      if (isActive) {
        _lastKnownLocation = LatLng(latitude, longitude);
        _locationController.add(_lastKnownLocation);
      } else {
        _handleError('Driver is not currently active');
      }
    } catch (e) {
      _handleError('Error processing location update: ${e.toString()}');
    }
  }

  // Handle driver status updates
  void _handleStatusUpdate(DatabaseEvent event) {
    try {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      
      if (data == null) return;

      final isOnline = data['isOnline'] as bool? ?? false;
      final isTracking = data['isTracking'] as bool? ?? false;
      final lastSeen = data['lastSeen'] as int?;

      // Check if driver was seen recently (5 minutes)
      bool isRecentlyActive = false;
      if (lastSeen != null) {
        final lastSeenTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);
        final now = DateTime.now();
        final difference = now.difference(lastSeenTime).inMinutes;
        isRecentlyActive = difference <= 5;
      }

      final driverActive = isOnline && isTracking && isRecentlyActive;
      _trackingStatusController.add(driverActive);

      if (!driverActive) {
        _handleError('Driver is currently offline or not tracking');
      }
    } catch (e) {
      _handleError('Error processing status update: ${e.toString()}');
    }
  }

  // Handle location-related errors
  void _handleLocationError(Object error) {
    _handleError('Location tracking error: ${error.toString()}');
  }

  // Handle status-related errors
  void _handleStatusError(Object error) {
    _handleError('Status tracking error: ${error.toString()}');
  }

  // Handle and broadcast errors
  void _handleError(String message) {
    print('ParentBusTrackingService Error: $message');
    _errorController.add(message);
  }

  // Get the last known location
  LatLng? get lastKnownLocation => _lastKnownLocation;

  // Check if currently tracking
  bool get isTracking => _isTracking;

  // Get current driver ID being tracked
  String? get currentDriverId => _currentDriverId;

  // Dispose of all resources
  void dispose() {
    stopTracking();
    _locationController.close();
    _trackingStatusController.close();
    _errorController.close();
  }
}
