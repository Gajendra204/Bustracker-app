import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/route_repository.dart';
import '../services/location_service.dart';
import '../services/token_service.dart';
import '../models/route_models.dart';

// Route State classes 
abstract class RouteState {
  const RouteState();
}

class RouteInitial extends RouteState {
  const RouteInitial();
}

class RouteLoading extends RouteState {
  const RouteLoading();
}

class RouteLoaded extends RouteState {
  final RouteData route;
  final RouteStatus status;
  final RouteStop? nextStop;
  final List<Student> nextStopStudents;
  final bool isGpsEnabled;
  final bool isTracking;

  const RouteLoaded({
    required this.route,
    required this.status,
    this.nextStop,
    required this.nextStopStudents,
    required this.isGpsEnabled,
    required this.isTracking,
  });

  RouteLoaded copyWith({
    RouteData? route,
    RouteStatus? status,
    RouteStop? nextStop,
    List<Student>? nextStopStudents,
    bool? isGpsEnabled,
    bool? isTracking,
  }) {
    return RouteLoaded(
      route: route ?? this.route,
      status: status ?? this.status,
      nextStop: nextStop ?? this.nextStop,
      nextStopStudents: nextStopStudents ?? this.nextStopStudents,
      isGpsEnabled: isGpsEnabled ?? this.isGpsEnabled,
      isTracking: isTracking ?? this.isTracking,
    );
  }
}

class RouteError extends RouteState {
  final String message;

  const RouteError(this.message);
}

class RouteEmpty extends RouteState {
  final String message;

  const RouteEmpty(this.message);
}

// Route StateNotifier 
class RouteNotifier extends StateNotifier<RouteState> {
  final RouteRepository _routeRepository;
  final LocationService _locationService;

  RouteNotifier({
    RouteRepository? routeRepository,
    LocationService? locationService,
  }) : _routeRepository = routeRepository ?? RouteRepository(),
       _locationService = locationService ?? LocationService(),
       super(const RouteInitial());

  // Load route 
  Future<void> loadRoute() async {
    state = const RouteLoading();

    try {
      final route = await _routeRepository.getDriverRoute();

      if (route == null) {
        state = const RouteEmpty('No route assigned to this driver');
        return;
      }

      final nextStop = _routeRepository.getNextStop(route);
      final nextStopStudents = nextStop != null
          ? _routeRepository.getStudentsForStop(route, nextStop.name)
          : <Student>[];

      state = RouteLoaded(
        route: route,
        status: RouteStatus.notStarted,
        nextStop: nextStop,
        nextStopStudents: nextStopStudents,
        isGpsEnabled: false,
        isTracking: false,
      );
    } catch (e) {
      state = RouteError('Failed to load route: ${e.toString()}');
    }
  }

  // Refresh route 
  Future<void> refreshRoute() async {
    if (state is RouteLoaded) {
      final currentState = state as RouteLoaded;
      state = currentState.copyWith();
    }

    // Reload the route
    await loadRoute();
  }

  // Enable GPS 
  Future<void> enableGPS() async {
    if (state is RouteLoaded) {
      final currentState = state as RouteLoaded;

      try {
        final isEnabled = await _locationService.initialize();
        state = currentState.copyWith(isGpsEnabled: isEnabled);
      } catch (e) {
        state = RouteError('Failed to enable GPS: ${e.toString()}');
      }
    }
  }

  // Start tracking
  Future<void> startTracking() async {
    if (state is RouteLoaded) {
      final currentState = state as RouteLoaded;

      try {
        final driverId = await TokenService.getDriverId();
        if (driverId != null) {
          final started = await _locationService.startBasicTracking(
            driverId: driverId,
          );
          state = currentState.copyWith(
            isTracking: started,
            status: started ? RouteStatus.inProgress : currentState.status,
          );
        }
      } catch (e) {
        state = RouteError('Failed to start tracking: ${e.toString()}');
      }
    }
  }

  // Stop tracking 
  Future<void> stopTracking() async {
    if (state is RouteLoaded) {
      final currentState = state as RouteLoaded;

      try {
        await _locationService.stopTracking();
        state = currentState.copyWith(
          isTracking: false, 
          status: RouteStatus.paused,
        );
      } catch (e) {
        state = RouteError('Failed to stop tracking: ${e.toString()}');
      }
    }
  }

  // Update route status 
  void updateRouteStatus(RouteStatus status) {
    if (state is RouteLoaded) {
      final currentState = state as RouteLoaded;
      state = currentState.copyWith(status: status);
    }
  }

  // Complete stop 
  void completeStop(String stopId) {
    if (state is RouteLoaded) {
      final currentState = state as RouteLoaded;
      state = currentState.copyWith();
    }
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}

// Provider definitions
final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return RouteRepository();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final routeProvider = StateNotifierProvider<RouteNotifier, RouteState>((ref) {
  final routeRepository = ref.watch(routeRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  
  return RouteNotifier(
    routeRepository: routeRepository,
    locationService: locationService,
  );
});
