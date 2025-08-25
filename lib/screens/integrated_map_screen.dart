// ignore_for_file: unused_field

import 'package:driver_app/widgets/integrated_map/map_view.dart';
import 'package:driver_app/widgets/integrated_map/next_stop_card.dart';
import 'package:driver_app/widgets/integrated_map/students_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/map_screen_controller.dart';
import 'mobile_number_screen.dart';

class IntegratedMapScreen extends StatefulWidget {
  final Map<String, dynamic> routeData;

  const IntegratedMapScreen({super.key, required this.routeData});

  @override
  State<IntegratedMapScreen> createState() => _IntegratedMapScreenState();
}

class _IntegratedMapScreenState extends State<IntegratedMapScreen> {
  final MapController _mapController = MapController();
  late final MapScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MapScreenController();
    _initializeMap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      await _controller.initialize(widget.routeData);

      // Listen to controller changes
      _controller.addListener(() {
        if (mounted) {
          setState(() {});

          // Center map on current location when it updates
          if (_controller.currentLocation != null) {
            _mapController.move(_controller.currentLocation!, 15.0);
          }
        }
      });

      // Center map on current location initially
      if (_controller.currentLocation != null) {
        _mapController.move(_controller.currentLocation!, 15.0);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          'Failed to initialize map. Please try again.',
          _initializeMap,
        );
      }
    }
  }

  /// Show error snackbar with retry option
  void _showErrorSnackBar(String message, VoidCallback onRetry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(label: 'RETRY', onPressed: onRetry),
      ),
    );
  }

  /// Handle logout process
  Future<void> _logout() async {
    try {
      await _controller.logout();
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
        _showErrorSnackBar('Failed to logout. Please try again.', _logout);
      }
    }
  }

  /// Show confirmation dialog and mark stop as complete
  void _markStopComplete() {
    if (_controller.nextStop == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark Stop Complete'),
          content: Text(
            'Are you sure you want to mark "${_controller.nextStop!['name']}" as complete?',
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

  /// Move to the next stop
  void _moveToNextStop() {
    _controller.markStopComplete();

    final nextStop = _controller.nextStop;
    if (nextStop != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved to next stop: ${nextStop['name']}'),
          backgroundColor: Colors.green,
        ),
      );

      // Move map to next stop location
      final location = nextStop['location'];
      if (location != null) {
        _mapController.move(
          LatLng(location['lat'].toDouble(), location['lng'].toDouble()),
          16.0,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 All stops completed! Great job!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

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
              color: _controller.isTracking ? Colors.green : Colors.white,
            ),
            onPressed: _controller.isTracking ? null : () => _initializeMap(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_controller.nextStop != null)
            NextStopCard(
              nextStop: _controller.nextStop!,
              studentCount: _controller
                  .getStudentsAtStop(_controller.nextStop!['name'])
                  .length,
              onTap: () {
                final location = _controller.nextStop!['location'];
                if (location != null) {
                  _mapController.move(
                    LatLng(
                      location['lat'].toDouble(),
                      location['lng'].toDouble(),
                    ),
                    16.0,
                  );
                }
              },
              onCompletePressed: _markStopComplete,
            ),

          Expanded(
            flex: 2,
            child: MapView(
              mapController: _mapController,
              currentLocation: _controller.currentLocation,
              routeData: widget.routeData,
              nextStopLocation: _controller.nextStop != null
                  ? LatLng(
                      _controller.nextStop!['location']['lat'].toDouble(),
                      _controller.nextStop!['location']['lng'].toDouble(),
                    )
                  : null,
              isDriverView: true, // This is the driver view
            ),
          ),

          StudentsPanel(
            isExpanded: _controller.isStudentsExpanded,
            nextStop: _controller.nextStop,
            students: _controller.students,
            onToggleExpanded: _controller.toggleStudentsExpansion,
          ),
        ],
      ),
    );
  }
}
