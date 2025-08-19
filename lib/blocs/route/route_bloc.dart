import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/route_repository.dart';
import '../../services/location_service.dart';
import '../../services/token_service.dart';
import '../../models/route_models.dart';
import 'route_event.dart';
import 'route_state.dart';

// Route Bloc
class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final RouteRepository _routeRepository;
  final LocationService _locationService;

  RouteBloc({
    RouteRepository? routeRepository,
    LocationService? locationService,
  }) : _routeRepository = routeRepository ?? RouteRepository(),
       _locationService = locationService ?? LocationService(),
       super(RouteInitial()) {
    on<LoadRoute>(_onLoadRoute);
    on<RefreshRoute>(_onRefreshRoute);
    on<EnableGPS>(_onEnableGPS);
    on<StartTracking>(_onStartTracking);
    on<StopTracking>(_onStopTracking);
    on<UpdateRouteStatus>(_onUpdateRouteStatus);
    on<CompleteStop>(_onCompleteStop);
  }

  Future<void> _onLoadRoute(LoadRoute event, Emitter<RouteState> emit) async {
    emit(RouteLoading());

    try {
      final route = await _routeRepository.getDriverRoute();

      if (route == null) {
        emit(const RouteEmpty('No route assigned to this driver'));
        return;
      }

      final nextStop = _routeRepository.getNextStop(route);
      final nextStopStudents = nextStop != null
          ? _routeRepository.getStudentsForStop(route, nextStop.name)
          : <Student>[];

      emit(
        RouteLoaded(
          route: route,
          status: RouteStatus.notStarted,
          nextStop: nextStop,
          nextStopStudents: nextStopStudents,
          isGpsEnabled: false,
          isTracking: false,
        ),
      );
    } catch (e) {
      emit(RouteError('Failed to load route: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshRoute(
    RefreshRoute event,
    Emitter<RouteState> emit,
  ) async {
    if (state is RouteLoaded) {
      final currentState = state as RouteLoaded;
      emit(currentState.copyWith());
    }

    // Reload the route
    add(LoadRoute());
  }

  Future<void> _onEnableGPS(EnableGPS event, Emitter<RouteState> emit) async {
    if (state is RouteLoaded) {
      final currentState = state as RouteLoaded;

      try {
        final isEnabled = await _locationService.initialize();
        emit(currentState.copyWith(isGpsEnabled: isEnabled));
      } catch (e) {
        emit(RouteError('Failed to enable GPS: ${e.toString()}'));
      }
    }
  }

  Future<void> _onStartTracking(
    StartTracking event,
    Emitter<RouteState> emit,
  ) async {
    if (state is RouteLoaded) {
      final currentState = state as RouteLoaded;

      try {
        final driverId = await TokenService.getDriverId();
        if (driverId != null) {
          final started = await _locationService.startBasicTracking(
            driverId: driverId,
          );
          emit(
            currentState.copyWith(
              isTracking: started,
              status: started ? RouteStatus.inProgress : currentState.status,
            ),
          );
        }
      } catch (e) {
        emit(RouteError('Failed to start tracking: ${e.toString()}'));
      }
    }
  }

  Future<void> _onStopTracking(
    StopTracking event,
    Emitter<RouteState> emit,
  ) async {
    if (state is RouteLoaded) {
      final currentState = state as RouteLoaded;

      try {
        await _locationService.stopTracking();
        emit(
          currentState.copyWith(isTracking: false, status: RouteStatus.paused),
        );
      } catch (e) {
        emit(RouteError('Failed to stop tracking: ${e.toString()}'));
      }
    }
  }

  Future<void> _onUpdateRouteStatus(
    UpdateRouteStatus event,
    Emitter<RouteState> emit,
  ) async {
    if (state is RouteLoaded) {
      final currentState = state as RouteLoaded;
      emit(currentState.copyWith(status: event.status));
    }
  }

  Future<void> _onCompleteStop(
    CompleteStop event,
    Emitter<RouteState> emit,
  ) async {
    if (state is RouteLoaded) {
      final currentState = state as RouteLoaded;

      emit(currentState.copyWith());
    }
  }

  @override
  Future<void> close() {
    _locationService.dispose();
    return super.close();
  }
}
