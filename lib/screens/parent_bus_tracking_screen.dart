import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/integrated_map/map_view.dart';
import '../services/parent_bus_tracking_service.dart';
import '../services/api_service.dart';

// Screen for parents to track their child's bus in real-time
class ParentBusTrackingScreen extends StatefulWidget {
  const ParentBusTrackingScreen({super.key});

  @override
  State<ParentBusTrackingScreen> createState() => _ParentBusTrackingScreenState();
}

class _ParentBusTrackingScreenState extends State<ParentBusTrackingScreen> {
  final MapController _mapController = MapController();
  final ParentBusTrackingService _trackingService = ParentBusTrackingService();
  
  bool _isLoading = true;
  bool _isTracking = false;
  String? _errorMessage;
  LatLng? _busLocation;
  Map<String, dynamic>? _routeData;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _trackingService.stopTracking();
    super.dispose();
  }

  // Initialize the tracking functionality
  Future<void> _initializeTracking() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get route data for the parent
      final routeResponse = await ApiService.getParentRoute();
      if (routeResponse['success'] != true) {
        throw Exception(routeResponse['message'] ?? 'Failed to get route data');
      }

      _routeData = routeResponse['data'];
      
      // Get driver ID from route data
      _driverId = await ApiService.getDriverIdForParent();
      if (_driverId == null) {
        throw Exception('No driver assigned to this route');
      }

      // Set up tracking service listeners
      _setupTrackingListeners();

      // Start tracking the driver
      final trackingStarted = await _trackingService.startTracking(_driverId!);
      if (!trackingStarted) {
        throw Exception('Failed to start tracking');
      }

      setState(() {
        _isLoading = false;
        _isTracking = true;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Set up listeners for tracking service streams
  void _setupTrackingListeners() {
    // Listen to location updates
    _trackingService.locationStream.listen((location) {
      if (mounted) {
        setState(() {
          _busLocation = location;
        });
        
        // Center map on bus location when it updates
        if (location != null) {
          _mapController.move(location, 15.0);
        }
      }
    });

    // Listen to tracking status updates
    _trackingService.trackingStatusStream.listen((isTracking) {
      if (mounted) {
        setState(() {
          _isTracking = isTracking;
        });
      }
    });

    // Listen to error updates
    _trackingService.errorStream.listen((error) {
      if (mounted) {
        _showErrorSnackBar(error);
      }
    });
  }

  // Show error message in snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _initializeTracking,
        ),
      ),
    );
  }

  // Refresh tracking data
  Future<void> _refreshTracking() async {
    await _initializeTracking();
  }

  // Center map on bus location
  void _centerOnBus() {
    if (_busLocation != null) {
      _mapController.move(_busLocation!, 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Track Bus',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_busLocation != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _centerOnBus,
              tooltip: 'Center on bus',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTracking,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Loading bus tracking...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to track bus',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshTracking,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_routeData == null) {
      return const Center(
        child: Text(
          'No route data available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Status indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: _isTracking ? Colors.green[50] : Colors.orange[50],
          child: Row(
            children: [
              Icon(
                _isTracking ? Icons.gps_fixed : Icons.gps_off,
                color: _isTracking ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isTracking ? 'Bus is being tracked' : 'Bus tracking unavailable',
                style: TextStyle(
                  color: _isTracking ? Colors.green[700] : Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_busLocation != null)
                Text(
                  'Last updated: ${DateTime.now().toString().substring(11, 19)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        
        // Map view
        Expanded(
          child: MapView(
            mapController: _mapController,
            currentLocation: null, 
            routeData: _routeData!,
            isDriverView: false,
            busLocation: _busLocation,
          ),
        ),
      ],
    );
  }
}
