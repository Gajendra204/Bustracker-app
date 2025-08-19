import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapView extends StatelessWidget {
  final MapController mapController;
  final LatLng? currentLocation;
  final Map<String, dynamic> routeData;
  final LatLng? nextStopLocation;

  const MapView({
    super.key,
    required this.mapController,
    required this.currentLocation,
    required this.routeData,
    this.nextStopLocation,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        center: currentLocation ?? const LatLng(0, 0),
        zoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.driver_app',
        ),
        MarkerLayer(
          markers: [
            if (currentLocation != null)
              Marker(
                point: currentLocation!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.directions_bus, color: Colors.white),
                ),
              ),
            ...routeData['route']['stops'].asMap().entries.where((entry) => entry.value['location'] != null).map((entry) {
              int index = entry.key;
              var stop = entry.value;
              LatLng stopLocation = LatLng(
                stop['location']['lat'].toDouble(),
                stop['location']['lng'].toDouble(),
              );
              
              bool isNextStop = nextStopLocation != null && 
                               stopLocation.latitude == nextStopLocation!.latitude &&
                               stopLocation.longitude == nextStopLocation!.longitude;
              
              return Marker(
                point: stopLocation,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: isNextStop ? Colors.red : Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }
}