// ignore_for_file: unused_field

import '../services/api_service.dart';
import '../models/route_models.dart';


class RouteRepository {
  final ApiService _apiService;

  RouteRepository({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  // Get driver's assigned route
  Future<RouteData?> getDriverRoute() async {
    try {
      final response = await ApiService.getDriverRoute();
      
      if (response['success'] == true && response['data'] != null) {
        return RouteData.fromJson(response['data']);
      }
      
      return null;
    } catch (e) {
      print('Error fetching driver route: $e');
      return null;
    }
  }

  // Get students for a specific stop
  List<Student> getStudentsForStop(RouteData route, String stopName) {
    return route.students.where((student) => 
        student.pickupLocation == stopName ||
        student.dropoffLocation == stopName
    ).toList();
  }

  // Get next stop in the route
  RouteStop? getNextStop(RouteData route) {
    if (route.stops.isEmpty) return null;
    
    // Sort stops by order and return the first one
    final sortedStops = List<RouteStop>.from(route.stops);
    sortedStops.sort((a, b) => a.order.compareTo(b.order));
    
    return sortedStops.first;
  }

  // Get all stops sorted by order
  List<RouteStop> getSortedStops(RouteData route) {
    final sortedStops = List<RouteStop>.from(route.stops);
    sortedStops.sort((a, b) => a.order.compareTo(b.order));
    return sortedStops;
  }

  // Calculate total distance of route 
  double calculateRouteDistance(RouteData route) {
   
    return route.stops.length * 2.5; 
  }

  // Get estimated time for route completion 
  Duration getEstimatedRouteTime(RouteData route) {
    
    return Duration(minutes: route.stops.length * 10); 
  }
}
