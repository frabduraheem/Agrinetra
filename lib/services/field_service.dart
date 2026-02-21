import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turf/turf.dart' as turf;
import 'package:latlong2/latlong.dart';
import '../models/field_model.dart';
import 'package:turf/helpers.dart';
import 'package:clipper2/clipper2.dart';
import '../config/api_config.dart';

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
    // Fetch latest from backend
    await fetchFieldsFromBackend();
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
    
    // 1. Check overlap locally first
    if (checkOverlap(field.boundary)) {
      final adjusted = adjustBoundary(field.boundary);
      if (adjusted != null && adjusted.isNotEmpty) {
        field.boundary = adjusted; 
      } else {
         return "New field completely overlaps with existing fields.";
      }
    }

    // 2. Sync to Backend FIRST
    String? backendError = await syncFieldToFlask(field);
    if (backendError != null) {
      return "Server Error: $backendError";
    }

    // 3. Update Local State only if backend success
    _fields.add(field);
    await saveFields();
    
    return null; // Success
  }

  Future<String?> updateField(Field updatedField) async {
    await loadFields();

    // Find existing field to compare
    int index = _fields.indexWhere((f) => f.id == updatedField.id);
    if (index == -1) return "Field not found locally.";
    Field oldField = _fields[index];

    bool nameChanged = oldField.name != updatedField.name;
    bool boundaryChanged = !_areBoundariesEqual(oldField.boundary, updatedField.boundary);

    if (boundaryChanged) {
      if (checkOverlap(updatedField.boundary, excludeFieldId: updatedField.id)) {
        final adjusted = adjustBoundary(updatedField.boundary, excludeFieldId: updatedField.id);
        if (adjusted != null && adjusted.isNotEmpty) {
          updatedField.boundary = adjusted;
        } else {
          return "Updated boundary completely overlaps with existing fields.";
        }
      }
    }

    // 2. Update Backend ONLY if necessary
    if (nameChanged || boundaryChanged) {
      String? backendError = await updateFieldInBackend(updatedField);
      if (backendError != null) {
          return "Server Error: $backendError";
      }
    }

    // 3. Update Local State (Always, to persist crop changes etc.)
    _fields[index] = updatedField;
    await saveFields();
    return null;
  }

  bool _areBoundariesEqual(List<LatLng> b1, List<LatLng> b2) {
    if (b1.length != b2.length) return false;
    for (int i = 0; i < b1.length; i++) {
      if (b1[i].latitude != b2[i].latitude || b1[i].longitude != b2[i].longitude) {
        return false;
      }
    }
    return true;
  }

  Future<String?> deleteField(String id) async {
     // 1. Delete from Backend FIRST
     String? backendError = await deleteFieldFromBackend(id);
     if (backendError != null) {
         return "Server Error: $backendError";
     }

     // 2. Update Local State
     _fields.removeWhere((f) => f.id == id);
     await saveFields();
     return null;
  }

  // Helper: Returns null on success, error message string on failure
  Future<String?> syncFieldToFlask(Field field) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "User not logged in";

    try {
        final plotData = {
          "pid": field.id,
          "uid": user.uid,
          "plotname": field.name,
          "boundaries": field.boundary.map((p) => {"lat": p.latitude, "lng": p.longitude}).toList(),
        };

        await FirebaseFirestore.instance
            .collection('plots')
            .doc(field.id)
            .set(plotData);

        return null;
    } catch (e) {
      return "Firestore Error: $e";
    }
  }

  Future<String?> updateFieldInBackend(Field field) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "User not logged in";

    try {
      final docRef = FirebaseFirestore.instance.collection('plots').doc(field.id);
      final docSnap = await docRef.get();
      
      if (!docSnap.exists) return "Plot not found in database";
      if (docSnap.data()!['uid'] != user.uid) return "Unauthorized to edit this plot";

      await docRef.update({
        "plotname": field.name,
        "boundaries": field.boundary.map((p) => {"lat": p.latitude, "lng": p.longitude}).toList(),
      });

      return null;
    } catch (e) {
      return "Firestore Error: $e";
    }
  }

  Future<String?> deleteFieldFromBackend(String plotId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "User not logged in";

    try {
      final docRef = FirebaseFirestore.instance.collection('plots').doc(plotId);
      final docSnap = await docRef.get();
      
      if (!docSnap.exists) return "Plot already deleted";
      if (docSnap.data()!['uid'] != user.uid) return "Unauthorized to delete this plot";

      // Note: Firestore doesn't automatically cascade delete subcollections. 
      // We must manually delete the crops subcollection fields first.
      final cropsSnap = await docRef.collection('crops').get();
      for (var crop in cropsSnap.docs) {
         await crop.reference.delete();
      }

      await docRef.delete();
      return null;
    } catch (e) {
      return "Firestore Error: $e";
    }
  }

  Future<List<String>> fetchAvailableCrops() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/available_crops'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> crops = data['crops'];
        return crops.map<String>((c) => c['name'] as String).toList();
      }
    } catch (e) {
      print("Error fetching available crops: $e");
    }
    return [];
  }

  Future<String?> addCropToBackend(String plotId, Crop crop) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "User not logged in";

    try {
      final plotRef = FirebaseFirestore.instance.collection('plots').doc(plotId);
      final plotSnap = await plotRef.get();
      
      if (!plotSnap.exists) return "Parent plot does not exist";
      if (plotSnap.data()!['uid'] != user.uid) return "Unauthorized to add crop to this plot";

      await plotRef.collection('crops').add({
        "pid": plotId,
        "cropname": crop.name,
        "plantingdate": crop.plantingDate.toIso8601String().split('T')[0],
        "harvestdate": crop.harvestDate.toIso8601String().split('T')[0],
      });

      return null;
    } catch (e) {
      return "Firestore Error: $e";
    }
  }

  Future<String?> editCropInBackend(String plotId, String oldCropName, Crop updatedCrop) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "User not logged in";

    try {
      final plotRef = FirebaseFirestore.instance.collection('plots').doc(plotId);
      final plotSnap = await plotRef.get();
      
      if (!plotSnap.exists) return "Parent plot does not exist";
      if (plotSnap.data()!['uid'] != user.uid) return "Unauthorized to edit crops in this plot";

      // Find the specific crop by old name
      final cropsSnap = await plotRef.collection('crops')
          .where('cropname', isEqualTo: oldCropName)
          .get();

      if (cropsSnap.docs.isNotEmpty) {
        // Technically there should only be one active crop matching the string name, update the first match
        await cropsSnap.docs.first.reference.update({
          "cropname": updatedCrop.name,
          "plantingdate": updatedCrop.plantingDate.toIso8601String().split('T')[0],
          "harvestdate": updatedCrop.harvestDate.toIso8601String().split('T')[0],
        });
        return null;
      } else {
        return "Crop not found";
      }
    } catch (e) {
      return "Firestore Error: $e";
    }
  }

  Future<String?> deleteCropFromBackend(String plotId, String cropName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "User not logged in";

    try {
      final plotRef = FirebaseFirestore.instance.collection('plots').doc(plotId);
      final plotSnap = await plotRef.get();
      
      if (!plotSnap.exists) return "Parent plot does not exist";
      if (plotSnap.data()!['uid'] != user.uid) return "Unauthorized to delete crops from this plot";

      // Find the specific crop by name and delete it
      final cropsSnap = await plotRef.collection('crops')
          .where('cropname', isEqualTo: cropName)
          .get();

      if (cropsSnap.docs.isNotEmpty) {
        await cropsSnap.docs.first.reference.delete();
        return null;
      } else {
        return "Crop not found";
      }
    } catch (e) {
      return "Firestore Error: $e";
    }
  }

  Future<List<Crop>> fetchCropsForField(String plotId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      // Add a security check: ensures user is only fetching crops for plots they actually own
      final plotRef = FirebaseFirestore.instance.collection('plots').doc(plotId);
      final plotSnap = await plotRef.get();
      
      if (!plotSnap.exists || plotSnap.data()!['uid'] != user.uid) {
         return [];
      }

      final cropsSnap = await plotRef.collection('crops').get();

      return cropsSnap.docs.map((doc) {
        final c = doc.data();
        return Crop(
          name: c['cropname'],
          plantingDate: DateTime.parse(c['plantingdate']),
          harvestDate: DateTime.parse(c['harvestdate']),
        );
      }).toList();
      
    } catch (e) {
      print("Firestore Error fetching crops for plot $plotId: $e");
    }
    return [];
  }

  Future<bool> fetchFieldsFromBackend() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userPlotsSnap = await FirebaseFirestore.instance
          .collection('plots')
          .where('uid', isEqualTo: user.uid)
          .get();

      List<Field> remoteFields = [];
      
      for (var doc in userPlotsSnap.docs) {
         final p = doc.data();
         List<LatLng> boundary = [];
         
         if (p['boundaries'] != null) {
            var bounds = p['boundaries'];
            if (bounds is String) {
               try {
                  bounds = json.decode(bounds);
               } catch (e) {
                  print("Error decoding boundary string: $e");
               }
            }
            if (bounds is List) {
               boundary = bounds.map<LatLng>((b) => LatLng(b['lat'], b['lng'])).toList();
            }
         }
         
         String pid = p['pid'] ?? doc.id;
         List<Crop> crops = await fetchCropsForField(pid);

         remoteFields.add(Field(
           id: pid,
           name: p['plotname'] ?? 'Unknown Field',
           boundary: boundary, 
           crops: crops, 
           isCultivated: crops.isNotEmpty
         ));
      }
      
      _fields = remoteFields;
      await saveFields();
      return true;
      
    } catch (e) {
      print("Firestore Error fetching fields: $e");
      return false;
    }
  }
}
