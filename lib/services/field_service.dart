import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turf/turf.dart' as turf;
import 'package:latlong2/latlong.dart';
import '../models/field_model.dart';
import 'package:turf/helpers.dart';
import 'package:clipper2/clipper2.dart';

class FieldService {
  static final FieldService _instance = FieldService._internal();
  factory FieldService() => _instance;
  FieldService._internal();

  List<Field> _fields = [];
  final double _scale = 10000000.0; // Scale for Clipper precision (1e7)

  Future<void> loadFields() async {
    final prefs = await SharedPreferences.getInstance();
    final String? fieldsJson = prefs.getString('fields');
    if (fieldsJson != null) {
      final List<dynamic> decodedList = json.decode(fieldsJson);
      _fields = decodedList.map((item) => Field.fromJson(item)).toList();
    }
  }

  Future<void> saveFields() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = json.encode(_fields.map((f) => f.toJson()).toList());
    await prefs.setString('fields', encodedList);
  }

  List<Field> getFields() => _fields;

  // Check if a new polygon overlaps with existing fields
  bool checkOverlap(List<LatLng> newBoundary, {String? excludeFieldId}) {
     if (newBoundary.length < 3) return false;

    // Convert LatLng list to Turf Position lists
    List<Position> newPositions = newBoundary.map((p) => Position(p.longitude, p.latitude)).toList();
    // Close the polygon if not already closed
    if (newPositions.first != newPositions.last) {
      newPositions.add(newPositions.first);
    }
    
    var newPolygon = Polygon(coordinates: [newPositions]);

    for (var field in _fields) {
      if (excludeFieldId != null && field.id == excludeFieldId) continue;

      List<Position> existingPositions = field.boundary.map((p) => Position(p.longitude, p.latitude)).toList();
       if (existingPositions.first != existingPositions.last) {
        existingPositions.add(existingPositions.first);
      }
      var existingPolygon = Polygon(coordinates: [existingPositions]);

      // Check for intersection
      try {
         if (turf.booleanIntersects(newPolygon, existingPolygon)) {
            return true;
         }
      } catch (e) {
        print("Error checking overlap: $e");
      }
    }
    return false;
  }

  // Auto-adjust boundary by subtracting existing fields
  List<LatLng>? adjustBoundary(List<LatLng> newBoundary, {String? excludeFieldId}) {
    if (newBoundary.length < 3) return null;

    // 1. Prepare Subject (New Field)
    // defined as List<List<Point64>> usually, or Paths
    final subject = <List<Point64>>[];
    final subjectPath = <Point64>[];
    for (var p in newBoundary) {
      subjectPath.add(Point64((p.latitude * _scale).round(), (p.longitude * _scale).round()));
    }
    subject.add(subjectPath);

    // 2. Prepare Clip (Existing Fields)
    final clip = <List<Point64>>[];
    for (var field in _fields) {
      if (excludeFieldId != null && field.id == excludeFieldId) continue;
      
      final clipPath = <Point64>[];
      for (var p in field.boundary) {
        clipPath.add(Point64((p.latitude * _scale).round(), (p.longitude * _scale).round()));
      }
      clip.add(clipPath);
    }

    // 3. Execute Difference
    // Using simple Clipper.difference if available, or try PolyTree approach if needed.
    // Assuming 'clipper2' package follows standard naming now (camelCase) or static methods.
    // If 'Clipper.Difference' failed, maybe it's purely generic 'difference' function?
    // Or maybe 'Clipper64'?
    // I will try 'Clipper.difference' (lowercase).
    
    // Note: If Clipper class doesn't have difference, we might need:
    // var c = Clipper64(); c.AddPath(...); c.Execute(...)
    // But let's try the static logic first which is common in Dart ports.
    
    // Let's assume the package exposes `Difference` as a top level function or on `Clipper` class.
    // Error said 'Clipper.Difference' not found.
    // I will try `Clipper.difference`. 
    
    // 3. Execute Difference
    // Trying named arguments based on error hint `difference({`
    final result = Clipper.difference(subject: subject, clip: clip, fillRule: FillRule.nonZero);

    // 4. Process Result
    if (result.isEmpty) return null; 

    List<Point64>? largestPath;
    double maxArea = 0;

    for (var path in result) {
      double area = _calculateArea(path).abs();
      if (area > maxArea) {
        maxArea = area;
        largestPath = path;
      }
    }

    if (largestPath == null || largestPath.length < 3) return null;

    return largestPath.map((p) => LatLng(p.x / _scale, p.y / _scale)).toList();
  }

  double _calculateArea(List<Point64> path) {
    double area = 0.0;
    for (int i = 0; i < path.length; i++) {
      int j = (i + 1) % path.length;
      area += path[i].x * path[j].y;
      area -= path[j].x * path[i].y;
    }
    return area / 2.0;
  }


  Future<String?> addField(Field field) async {
    await loadFields(); 
    
    if (checkOverlap(field.boundary)) {
      // Try to auto-adjust
      final adjusted = adjustBoundary(field.boundary);
      if (adjusted != null && adjusted.isNotEmpty) {
        field.boundary = adjusted; // Automatically update to the non-overlapping part
        // We could return a warning here instead of silent update, but user asked for automatic.
      } else {
         return "New field completely overlaps with existing fields or result is invalid.";
      }
    }

    _fields.add(field);
    await saveFields();
    return null; // Success
  }

  Future<String?> updateField(Field updatedField) async {
    await loadFields();

    if (checkOverlap(updatedField.boundary, excludeFieldId: updatedField.id)) {
      final adjusted = adjustBoundary(updatedField.boundary, excludeFieldId: updatedField.id);
      if (adjusted != null && adjusted.isNotEmpty) {
        updatedField.boundary = adjusted;
      } else {
        return "Updated boundary completely overlaps with existing fields.";
      }
    }

    int index = _fields.indexWhere((f) => f.id == updatedField.id);
    if (index != -1) {
      _fields[index] = updatedField;
      await saveFields();
      return null;
    }
    return "Field not found.";
  }

  Future<void> deleteField(String id) async {
     _fields.removeWhere((f) => f.id == id);
     await saveFields();
  }
}
