// ignore_for_file: unused_field

import 'package:driver_app/widgets/integrated_map/map_view.dart';
import 'package:driver_app/widgets/integrated_map/next_stop_card.dart';
import 'package:driver_app/widgets/integrated_map/students_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/location_service.dart';
import '../services/token_service.dart';
import 'mobile_number_screen.dart';

class IntegratedMapScreen extends StatefulWidget {
  final Map<String, dynamic> routeData;

  const IntegratedMapScreen({super.key, required this.routeData});

  @override
  State<IntegratedMapScreen> createState() => _IntegratedMapScreenState();
}

class _IntegratedMapScreenState extends State<IntegratedMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  LatLng? _currentLocation;
  LatLng? _nextStopLocation;
  Timer? _locationUpdateTimer;
  bool _isTracking = false;
  String? _driverId;
  Map<String, dynamic>? _nextStop;
  List<dynamic> _students = [];
  bool _isStudentsExpanded = false;
  List<LatLng> _allStopLocations = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      // Get driver ID
      _driverId = await TokenService.getDriverId();

      // Initialize location service
      await _locationService.initialize();

      // Get route data
      final route = widget.routeData['route'];
      final students = widget.routeData['students'] as List<dynamic>? ?? [];

      setState(() {
        _students = students;
      });

      // Get ALL stops and their locations
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

        // Find next stop 
        if (stops.isNotEmpty) {
          final firstStop = stops.first;
          final location = firstStop['location'];

          if (location != null &&
              location['lat'] != null &&
              location['lng'] != null) {
            setState(() {
              _nextStop = firstStop;
              _nextStopLocation = LatLng(
                location['lat'].toDouble(),
                location['lng'].toDouble(),
              );
            });
          }
        }
      }

      // Get current location and start tracking
      await _getCurrentLocationAndStartTracking();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to initialize map. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'RETRY',
              onPressed: () => _initializeMap(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocationAndStartTracking() async {
    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Center map on current location
      if (_currentLocation != null) {
        _mapController.move(_currentLocation!, 15.0);
      }

      // Start location tracking
      if (_driverId != null) {
        bool started = await _locationService.startBasicTracking(
          driverId: _driverId!,
        );
        if (started) {
          setState(() {
            _isTracking = true;
          });

          _startLocationUpdates();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to get current location. Please try again.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'RETRY',
              onPressed: () => _getCurrentLocationAndStartTracking(),
            ),
          ),
        );
      }
    }
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to start location updates. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'RETRY',
              onPressed: () => _startLocationUpdates(),
            ),
          ),
        );
      }
    }
    });
  }

  Future<void> _logout() async {
    try {
      _locationUpdateTimer?.cancel();
      await _locationService.stopTracking();
      await TokenService.clearAllTokens();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MobileNumberScreen(userType: 'driver'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to logout. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'RETRY',
              onPressed: () => _logout(),
            ),
          ),
        );
      }
    }
  }

  void _markStopComplete() {
    if (_nextStop == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark Stop Complete'),
          content: Text(
            'Are you sure you want to mark "${_nextStop!['name']}" as complete?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _moveToNextStop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );
  }

  void _moveToNextStop() {
    // Get current route stops
    final stops = widget.routeData['route']['stops'] as List<dynamic>? ?? [];

    if (stops.isEmpty) return;

    // Sort stops by order
    stops.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

    // Find current stop index
    int currentIndex = -1;
    if (_nextStop != null) {
      currentIndex = stops.indexWhere(
        (stop) => stop['_id'] == _nextStop!['_id'],
      );
    }

    // Move to next stop
    if (currentIndex < stops.length - 1) {
      setState(() {
        _nextStop = stops[currentIndex + 1];
        if (_nextStop!['location'] != null) {
          _nextStopLocation = LatLng(
            _nextStop!['location']['lat'].toDouble(),
            _nextStop!['location']['lng'].toDouble(),
          );
          // Move map to next stop
          _mapController.move(_nextStopLocation!, 16.0);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved to next stop: ${_nextStop!['name']}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // All stops completed
      setState(() {
        _nextStop = null;
        _nextStopLocation = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 All stops completed! Great job!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.gps_fixed,
              color: _isTracking ? Colors.green : Colors.white,
            ),
            onPressed: _isTracking ? null : _getCurrentLocationAndStartTracking,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_nextStop != null)
            NextStopCard(
              nextStop: _nextStop!,
              studentCount: _getStudentsAtStop(_nextStop!['name']).length,
              onTap: () => _mapController.move(
                LatLng(
                  _nextStop!['location']['lat'].toDouble(),
                  _nextStop!['location']['lng'].toDouble(),
                ),
                16.0,
              ),
              onCompletePressed: _markStopComplete,
            ),

          Expanded(
            flex: 2,
            child: MapView(
              mapController: _mapController,
              currentLocation: _currentLocation,
              routeData: widget.routeData,
              nextStopLocation: _nextStop != null
                  ? LatLng(
                      _nextStop!['location']['lat'].toDouble(),
                      _nextStop!['location']['lng'].toDouble(),
                    )
                  : null,
            ),
          ),

          StudentsPanel(
            isExpanded: _isStudentsExpanded,
            nextStop: _nextStop,
            students: _students,
            onToggleExpanded: () =>
                setState(() => _isStudentsExpanded = !_isStudentsExpanded),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getStudentsAtStop(String stopName) {
    return _students
        .where(
          (student) =>
              student['pickupLocation'] == stopName ||
              student['dropoffLocation'] == stopName,
        )
        .cast<Map<String, dynamic>>()
        .toList();
  }
}
