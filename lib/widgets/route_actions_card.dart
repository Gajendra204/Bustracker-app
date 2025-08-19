import 'package:flutter/material.dart';
import '../models/route_models.dart';

// Route Actions Card Widget
class RouteActionsCard extends StatelessWidget {
  final bool isGpsEnabled;
  final bool isTracking;
  final RouteStatus status;

  final VoidCallback? onOpenMap;
  final VoidCallback? onCompleteRoute;

  const RouteActionsCard({
    super.key,
    required this.isGpsEnabled,
    required this.isTracking,
    required this.status,

    this.onOpenMap,
    this.onCompleteRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      color: const Color(0xFFF9FAFB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.touch_app, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Navigation Button
            if (isGpsEnabled) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onOpenMap,
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: const Text(
                    'Start Route Navigation',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 1,
                    backgroundColor: Colors.blue[500],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Complete Route Button
            if (status == RouteStatus.inProgress) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCompleteRoute,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text(
                    'Complete Route',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    elevation: 1,
                    foregroundColor: Colors.green[600],
                    side: BorderSide(color: Colors.green[600]!),
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
            ],

            // Status Indicator
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor().withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(_getStatusIcon(), color: _getStatusColor(), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (!isGpsEnabled) return Colors.red;
    if (isTracking) return Colors.green;
    return Colors.orange;
  }

  IconData _getStatusIcon() {
    if (!isGpsEnabled) return Icons.gps_off;
    if (isTracking) return Icons.directions_bus;
    return Icons.pause_circle;
  }

  String _getStatusText() {
    if (!isGpsEnabled) return 'GPS is disabled. Enable GPS to start tracking.';
    if (isTracking) return 'Route is active. Location is being tracked.';
    return 'Ready to start. Tap "Start Route" to begin tracking.';
  }
}
