import 'package:flutter/material.dart';
import '../models/route_models.dart';

class RouteHeaderCard extends StatelessWidget {
  final RouteData route;
  final RouteStatus status;

  const RouteHeaderCard({super.key, required this.route, required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue[500]!, Colors.blue[700]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // route name and status with bus icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                        Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                      const SizedBox(width: 12),
                      Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (route.bus != null)
                          Text(
                            'Bus #${route.bus!.busNumber}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  _buildStatusChip(),
                ],
              ),
              
              
              const SizedBox(height: 16),
              
              // Stats row
              Row(
                children: [
                  _buildInfoItem(
                    icon: Icons.location_on_outlined,
                    value: '${route.stops.length}',
                    label: 'Stops',
                  ),
                  const SizedBox(width: 24),
                  _buildInfoItem(
                    icon: Icons.people_outlined,
                    value: '${route.totalStudents}',
                    label: 'Students',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    
    switch (status) {
      case RouteStatus.notStarted:
        backgroundColor = Colors.orange;
        break;
      case RouteStatus.inProgress:
        backgroundColor = Colors.green;
        break;
      case RouteStatus.completed:
        backgroundColor = const Color.fromARGB(255, 230, 230, 230);
        break;
      case RouteStatus.paused:
        backgroundColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: backgroundColor),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: backgroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}