class RouteData {
  final String id;
  final String name;
  final String description;
  final List<RouteStop> stops;
  final Bus? bus;
  final List<Student> students;
  final int totalStudents;

  RouteData({
    required this.id,
    required this.name,
    required this.description,
    required this.stops,
    this.bus,
    required this.students,
    required this.totalStudents,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) {
    return RouteData(
      id: json['route']?['_id'] ?? '',
      name: json['route']?['name'] ?? '',
      description: json['route']?['description'] ?? '',
      stops:
          (json['route']?['stops'] as List<dynamic>?)
              ?.map((stop) => RouteStop.fromJson(stop))
              .toList() ??
          [],
      bus: json['bus'] != null ? Bus.fromJson(json['bus']) : null,
      students:
          (json['students'] as List<dynamic>?)
              ?.map((student) => Student.fromJson(student))
              .toList() ??
          [],
      totalStudents: json['totalStudents'] ?? 0,
    );
  }
}

class RouteStop {
  final String id;
  final String name;
  final String? description;
  final int order;
  final Location? location;

  RouteStop({
    required this.id,
    required this.name,
    this.description,
    required this.order,
    this.location,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      order: json['order'] ?? 0,
      location: json['location'] != null
          ? Location.fromJson(json['location'])
          : null,
    );
  }
}

class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }
}

class Bus {
  final String id;
  final String busNumber;
  final String name;
  final int capacity;

  Bus({
    required this.id,
    required this.busNumber,
    required this.name,
    required this.capacity,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['_id'] ?? '',
      busNumber: json['busNumber'] ?? '',
      name: json['name'] ?? '',
      capacity: json['capacity'] ?? 0,
    );
  }
}

class Student {
  final String id;
  final String name;
  final String? class_;
  final String? parentName;
  final String? parentPhone;
  final String? pickupLocation;
  final String? dropoffLocation;

  Student({
    required this.id,
    required this.name,
    this.class_,
    this.parentName,
    this.parentPhone,
    this.pickupLocation,
    this.dropoffLocation,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      class_: json['class']?.toString(),
      parentName: json['parentName']?.toString(),
      parentPhone: json['parentPhone']?.toString(),
      pickupLocation: json['pickupLocation']?.toString(),
      dropoffLocation: json['dropoffLocation']?.toString(),
    );
  }
}

// Enum for route status
enum RouteStatus { notStarted, inProgress, completed, paused }

extension RouteStatusExtension on RouteStatus {
  String get displayName {
    switch (this) {
      case RouteStatus.notStarted:
        return 'Not Started';
      case RouteStatus.inProgress:
        return 'In Progress';
      case RouteStatus.completed:
        return 'Completed';
      case RouteStatus.paused:
        return 'Paused';
    }
  }

  String get emoji {
    switch (this) {
      case RouteStatus.notStarted:
        return '⏸️';
      case RouteStatus.inProgress:
        return '🚌';
      case RouteStatus.completed:
        return '✅';
      case RouteStatus.paused:
        return '⏸️';
    }
  }
}
