import 'package:equatable/equatable.dart';
import '../../models/route_models.dart';

// Route events 
abstract class RouteEvent extends Equatable {
  const RouteEvent();

  @override
  List<Object?> get props => [];
}

class LoadRoute extends RouteEvent {}

class RefreshRoute extends RouteEvent {}

class EnableGPS extends RouteEvent {}

class StartTracking extends RouteEvent {}

class StopTracking extends RouteEvent {}

class UpdateRouteStatus extends RouteEvent {
  final RouteStatus status;

  const UpdateRouteStatus(this.status);

  @override
  List<Object> get props => [status];
}

class CompleteStop extends RouteEvent {
  final String stopId;

  const CompleteStop(this.stopId);

  @override
  List<Object> get props => [stopId];
}
