import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/route_provider.dart';
import '../models/route_models.dart';
import '../services/token_service.dart';
import '../widgets/route_header_card.dart';
import '../widgets/route_stats_card.dart';
import '../widgets/students_list_card.dart';
import '../widgets/route_actions_card.dart';
import 'mobile_number_screen.dart';
import 'integrated_map_screen.dart';

class RouteDetailsScreen extends ConsumerStatefulWidget {
  const RouteDetailsScreen({super.key});

  @override
  ConsumerState<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends ConsumerState<RouteDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Load route when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routeProvider.notifier).loadRoute();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Route Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final state = ref.watch(routeProvider);
              if (state is RouteLoaded) {
                return IconButton(
                  icon: Icon(
                    Icons.location_on_outlined,
                    color: state.isGpsEnabled ? Colors.green : Colors.grey[800],
                  ),
                  onPressed: state.isGpsEnabled
                      ? null
                      : () => ref.read(routeProvider.notifier).enableGPS(),
                  tooltip: state.isGpsEnabled ? 'GPS Enabled' : 'Enable GPS',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[800]),
            onPressed: () => ref.read(routeProvider.notifier).refreshRoute(),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.grey[800]),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(routeProvider);

          if (state is RouteLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading route details...'),
                ],
              ),
            );
          }

          if (state is RouteError) {
            return _buildErrorView(context, state.message);
          }

          if (state is RouteEmpty) {
            return _buildEmptyView(context, state.message);
          }

          if (state is RouteLoaded) {
            return _buildRouteView(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(routeProvider);
          if (state is RouteLoaded && state.isGpsEnabled) {
            return FloatingActionButton.extended(
              onPressed: state.isTracking
                  ? () => ref.read(routeProvider.notifier).stopTracking()
                  : () => ref.read(routeProvider.notifier).startTracking(),
              icon: Icon(state.isTracking ? Icons.pause : Icons.play_arrow),
              label: Text(state.isTracking ? 'Pause Route' : 'Start Route'),
              backgroundColor: state.isTracking ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(routeProvider.notifier).loadRoute(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Route Assigned',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(routeProvider.notifier).loadRoute(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteView(BuildContext context, RouteLoaded state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Route Header
          RouteHeaderCard(route: state.route, status: state.status),

          // Route Statistics
          RouteStatsCard(route: state.route, isTracking: state.isTracking),

          // Students Overview Card
          StudentsListCard(route: state.route),

          // Action Buttons
          RouteActionsCard(
            isGpsEnabled: state.isGpsEnabled,
            isTracking: state.isTracking,
            status: state.status,

            onOpenMap: () => _openIntegratedMap(context, state.route),
            onCompleteRoute: () => ref
                .read(routeProvider.notifier)
                .updateRouteStatus(RouteStatus.completed),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await TokenService.clearAllTokens();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MobileNumberScreen(userType: 'driver'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logout failed. Please try again.'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _openIntegratedMap(BuildContext context, RouteData route) {
    final routeDataMap = {
      'route': {
        '_id': route.id,
        'name': route.name,
        'description': route.description,
        'stops': route.stops
            .map(
              (stop) => {
                '_id': stop.id,
                'name': stop.name,
                'description': stop.description,
                'order': stop.order,
                'location': stop.location != null
                    ? {'lat': stop.location!.lat, 'lng': stop.location!.lng}
                    : null,
              },
            )
            .toList(),
      },
      'students': route.students
          .map(
            (student) => {
              '_id': student.id,
              'name': student.name,
              'class': student.class_,
              'parentName': student.parentName,
              'parentPhone': student.parentPhone,
              'pickupLocation': student.pickupLocation,
              'dropoffLocation': student.dropoffLocation,
            },
          )
          .toList(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntegratedMapScreen(routeData: routeDataMap),
      ),
    );
  }
}
