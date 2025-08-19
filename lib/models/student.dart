class Student {
  final String id;
  final String name;
  final int studentClass;
  final String routeId;
  final String parentName;
  final String parentPhone;
  final String pickupLocation;
  final String dropoffLocation;

  Student({
    required this.id,
    required this.name,
    required this.studentClass,
    required this.routeId,
    required this.parentName,
    required this.parentPhone,
    required this.pickupLocation,
    required this.dropoffLocation,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      studentClass: _parseInt(json['class']),
      routeId: json['routeId']?.toString() ?? '',
      parentName: json['parentName']?.toString() ?? '',
      parentPhone: json['parentPhone']?.toString() ?? '',
      pickupLocation: json['pickupLocation']?.toString() ?? '',
      dropoffLocation: json['dropoffLocation']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'class': studentClass,
      'routeId': routeId,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
    };
  }
}
