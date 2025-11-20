class City {
  final String id;
  final String name;
  final String? region;
  final String country;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  City({
    required this.id,
    required this.name,
    this.region,
    required this.country,
    this.latitude,
    this.longitude,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  }) {
    // Constructor validation
    if (id.trim().isEmpty) {
      throw ArgumentError('City ID cannot be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('City name cannot be empty');
    }
    if (country.trim().isEmpty) {
      throw ArgumentError('Country cannot be empty');
    }
    if (latitude != null && (latitude! < -90 || latitude! > 90)) {
      throw ArgumentError('Latitude must be between -90 and 90');
    }
    if (longitude != null && (longitude! < -180 || longitude! > 180)) {
      throw ArgumentError('Longitude must be between -180 and 180');
    }
  }

  factory City.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    final id = json['id'];
    if (id == null) {
      throw const FormatException('City ID is required');
    }
    final idStr = id.toString();
    if (idStr.trim().isEmpty) {
      throw const FormatException('City ID cannot be empty');
    }

    final name = json['name'];
    if (name == null || name.toString().trim().isEmpty) {
      throw const FormatException('City name is required and cannot be empty');
    }

    final country = json['country']?.toString() ?? 'Morocco';
    if (country.trim().isEmpty) {
      throw const FormatException('Country cannot be empty');
    }

    // Parse and validate latitude if provided
    double? latitude;
    if (json['latitude'] != null) {
      try {
        latitude = (json['latitude'] as num).toDouble();
        if (latitude < -90 || latitude > 90) {
          throw const FormatException('Latitude must be between -90 and 90');
        }
      } catch (e) {
        throw FormatException('Invalid latitude format: $e');
      }
    }

    // Parse and validate longitude if provided
    double? longitude;
    if (json['longitude'] != null) {
      try {
        longitude = (json['longitude'] as num).toDouble();
        if (longitude < -180 || longitude > 180) {
          throw const FormatException('Longitude must be between -180 and 180');
        }
      } catch (e) {
        throw FormatException('Invalid longitude format: $e');
      }
    }

    // Parse and validate createdAt
    DateTime createdAt;
    try {
      final createdAtStr = json['created_at'];
      if (createdAtStr != null && createdAtStr.toString().isNotEmpty) {
        createdAt = DateTime.parse(createdAtStr.toString());
      } else {
        throw const FormatException('Created date is required');
      }
    } catch (e) {
      throw FormatException('Invalid created_at format: $e');
    }

    // Parse and validate updatedAt
    DateTime updatedAt;
    try {
      final updatedAtStr = json['updated_at'];
      if (updatedAtStr != null && updatedAtStr.toString().isNotEmpty) {
        updatedAt = DateTime.parse(updatedAtStr.toString());
      } else {
        updatedAt = DateTime.now();
      }
    } catch (e) {
      throw FormatException('Invalid updated_at format: $e');
    }

    return City(
      id: idStr,
      name: name.toString().trim(),
      region: json['region']?.toString(),
      country: country.trim(),
      latitude: latitude,
      longitude: longitude,
      isActive: json['is_active'] == true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  City copyWith({
    String? id,
    String? name,
    String? region,
    String? country,
    double? latitude,
    double? longitude,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return City(
      id: id ?? this.id,
      name: name ?? this.name,
      region: region ?? this.region,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return name;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is City && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
