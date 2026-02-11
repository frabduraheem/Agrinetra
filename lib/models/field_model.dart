import 'package:latlong2/latlong.dart';

class Crop {
  String name;
  DateTime plantingDate;
  DateTime harvestDate;

  Crop({
    required this.name,
    required this.plantingDate,
    required this.harvestDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'plantingDate': plantingDate.toIso8601String(),
      'harvestDate': harvestDate.toIso8601String(),
    };
  }

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      name: json['name'],
      plantingDate: DateTime.parse(json['plantingDate']),
      harvestDate: DateTime.parse(json['harvestDate']),
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
