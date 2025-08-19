import 'package:equatable/equatable.dart';
import '../../models/route_models.dart';

abstract class RouteState extends Equatable {
  const RouteState();

  @override
  List<Object?> get props => [];
}

class RouteInitial extends RouteState {}

class RouteLoading extends RouteState {}

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

  @override
  List<Object?> get props => [
    route,
    status,
    nextStop,
    nextStopStudents,
    isGpsEnabled,
    isTracking,
  ];
}

class RouteError extends RouteState {
  final String message;

  const RouteError(this.message);

  @override
  List<Object> get props => [message];
}

class RouteEmpty extends RouteState {
  final String message;

  const RouteEmpty(this.message);

  @override
  List<Object> get props => [message];
}
