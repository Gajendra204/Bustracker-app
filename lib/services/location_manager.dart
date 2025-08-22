import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

// Manages location tracking and GPS operations
class LocationManager {
  static final LocationManager _instance = LocationManager._internal();
  factory LocationManager() => _instance;
  LocationManager._internal();

  Timer? _locationTimer;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool _isTracking = false;
  String? _driverId;
  
  // Stream controller for location updates
  final StreamController<Position> _locationController = StreamController<Position>.broadcast();
  Stream<Position> get locationStream => _locationController.stream;

  // Initialize location services and permissions
  Future<bool> initialize() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Location service init error: $e');
      return false;
    }
  }

  // Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Get current location error: $e');
      return null;
    }
  }

  // Start continuous location tracking
  Future<bool> startTracking(String driverId) async {
    if (_isTracking) return true;

    try {
      _driverId = driverId;
      _isTracking = true;

      // Start periodic location updates every 10 seconds
      _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _updateLocation();
      });

      return true;
    } catch (e) {
      print('Start tracking error: $e');
      return false;
    }
  }

  // Stop location tracking
  Future<void> stopTracking() async {
    try {
      _locationTimer?.cancel();
      _isTracking = false;

      if (_driverId != null) {
        await _updateDriverStatus(isOnline: false, isTracking: false);
      }
    } catch (e) {
      print('Stop tracking error: $e');
    }
  }

  // Update current location and broadcast to listeners
  Future<void> _updateLocation() async {
    if (!_isTracking || _driverId == null) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Broadcast position to listeners
      _locationController.add(position);

      // Update Firebase with location data
      await _updateFirebaseLocation(position);
      await _updateDriverStatus(isOnline: true, isTracking: true);
    } catch (e) {
      print('Location update error: $e');
    }
  }

  // Update location data in Firebase
  Future<void> _updateFirebaseLocation(Position position) async {
    if (_driverId == null) return;

    final locationData = {
      'driverId': _driverId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'heading': position.heading,
      'accuracy': position.accuracy,
      'isActive': true,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    await _database.child('driver_locations/$_driverId').set(locationData);
  }

  // Update driver status in Firebase
  Future<void> _updateDriverStatus({
    required bool isOnline,
    required bool isTracking,
  }) async {
    if (_driverId == null) return;

    await _database.child('driver_status/$_driverId').set({
      'isOnline': isOnline,
      'isTracking': isTracking,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Check if currently tracking
  bool get isTracking => _isTracking;

  // Cleanup resources
  void dispose() {
    _locationTimer?.cancel();
    _locationController.close();
  }
}
