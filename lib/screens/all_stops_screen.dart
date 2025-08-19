import 'package:flutter/material.dart';
import '../models/route_models.dart';
import 'stop_details_screen.dart';

// All Stops Screen
class AllStopsScreen extends StatelessWidget {
  final RouteData route;

  const AllStopsScreen({
    super.key,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    // Sort stops by order
    final sortedStops = List<RouteStop>.from(route.stops);
    sortedStops.sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title:  Text(
          'All Stops',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme:  IconThemeData(color: Colors.grey[800]),
      ),
      body: Column(
        children: [
          // Route Header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              color: const Color(0xFFF9FAFB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.route,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        route.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${sortedStops.length} stops',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stops List
          Expanded(
            child: sortedStops.isEmpty
                ? _buildEmptyState()
                : _buildStopsList(context, sortedStops),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No stops found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This route currently has no stops assigned.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStopsList(BuildContext context, List<RouteStop> stops) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: stops.length,
      itemBuilder: (context, index) {
        final stop = stops[index];
        final studentsAtStop = _getStudentsAtStop(stop);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: const Color(0xFFF9FAFB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StopDetailsScreen(
                    stop: stop,
                    students: studentsAtStop,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Stop Order Badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.orange[300]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${stop.order}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Stop Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${studentsAtStop.length} student${studentsAtStop.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (stop.location != null) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.gps_fixed,
                                size: 14,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'GPS Available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (stop.description != null && stop.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            stop.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Student Count Badge and Arrow
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: studentsAtStop.isEmpty ? Colors.grey[100] : Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${studentsAtStop.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: studentsAtStop.isEmpty ? Colors.grey[600] : Colors.blue[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Student> _getStudentsAtStop(RouteStop stop) {
    return route.students.where((student) {
      return student.pickupLocation == stop.name || 
             student.dropoffLocation == stop.name;
    }).toList();
  }
}
