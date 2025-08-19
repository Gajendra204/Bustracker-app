import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _locationTimer;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool _isTracking = false;
  String? _driverId;

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

  Future<bool> startBasicTracking({required String driverId}) async {
    if (_isTracking) return true;

    try {
      _driverId = driverId;
      _isTracking = true;

      // updates every 10 seconds
      _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _updateLocation();
      });

      return true;
    } catch (e) {
      print('Start tracking error: $e');
      return false;
    }
  }

  Future<void> stopTracking() async {
    try {
      _locationTimer?.cancel();
      _isTracking = false;

      if (_driverId != null) {
        await _database.child('driver_status/$_driverId').set({
          'isOnline': false,
          'isTracking': false,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('Stop tracking error: $e');
    }
  }

  Future<void> _updateLocation() async {
    if (!_isTracking || _driverId == null) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final locationData = {
        'driverId': _driverId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'heading': position.heading, // direction
        'accuracy': position.accuracy, // meters
        'isActive': true,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await _database.child('driver_locations/$_driverId').set(locationData);

      await _database.child('driver_status/$_driverId').set({
        'isOnline': true,
        'isTracking': true,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Location update error: $e');
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  bool get isTracking => _isTracking;

  void dispose() {
    _locationTimer?.cancel();
  }
}
