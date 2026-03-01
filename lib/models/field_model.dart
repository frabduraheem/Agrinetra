import 'package:latlong2/latlong.dart';

class Crop {
  String name;
  DateTime plantingDateStart;
  DateTime plantingDateEnd;

  Crop({
    required this.name,
    required this.plantingDateStart,
    required this.plantingDateEnd,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'plantingDateStart': plantingDateStart.toIso8601String(),
      'plantingDateEnd': plantingDateEnd.toIso8601String(),
    };
  }

  factory Crop.fromJson(Map<String, dynamic> json) {
    // Fallback logic for backward compatibility with old local storage dates
    DateTime pStart = json.containsKey('plantingDateStart') 
        ? DateTime.parse(json['plantingDateStart']) 
        : DateTime.parse(json['plantingDate']);
    DateTime pEnd = json.containsKey('plantingDateEnd') 
        ? DateTime.parse(json['plantingDateEnd']) 
        : DateTime.parse(json['plantingDate']);
    
    return Crop(
      name: json['name'],
      plantingDateStart: pStart,
      plantingDateEnd: pEnd,
    );
  }
}

class Field {
  String id;
  String name;
  List<LatLng> boundary;
  List<Crop> crops;

  bool isCultivated;

  Field({
    required this.id,
    required this.name,
    required this.boundary,
    required this.crops,
    this.isCultivated = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'boundary': boundary.map((point) => {'lat': point.latitude, 'lng': point.longitude}).toList(),
      'crops': crops.map((crop) => crop.toJson()).toList(),
      'isCultivated': isCultivated,
    };
  }

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'],
      name: json['name'],
      boundary: (json['boundary'] as List)
          .map((point) => LatLng(point['lat'], point['lng']))
          .toList(),
      crops: (json['crops'] as List)
          .map((cropJson) => Crop.fromJson(cropJson))
          .toList(),
      isCultivated: json['isCultivated'] ?? false,
    );
  }
}
