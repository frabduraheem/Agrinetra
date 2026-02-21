import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/field_model.dart';
import '../services/field_service.dart';
import '../config/api_config.dart';

class AnalysisService {
  static final AnalysisService _instance = AnalysisService._internal();
  factory AnalysisService() => _instance;
  AnalysisService._internal();

  Future<Map<String, dynamic>?> analyzeField(Field field, {bool forceRefresh = false}) async {
    try {
      // Try to determine current crop if any
      String? cropName;
      if (field.crops != null && field.crops!.isNotEmpty) {
        cropName = field.crops!.first.name; 
      }

      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'analysis_${field.id}_$cropName';
      final String timeKey = 'analysis_time_${field.id}_$cropName';

      // Check Cache
      if (!forceRefresh) {
        final cachedData = prefs.getString(cacheKey);
        final cachedTimeStr = prefs.getString(timeKey);

        if (cachedData != null && cachedTimeStr != null) {
           final cachedTime = DateTime.parse(cachedTimeStr);
           // If cache is less than 24 hours old, return it
           if (DateTime.now().difference(cachedTime).inHours < 24) {
             return json.decode(cachedData);
           }
        }
      }

      // Cache miss or expired or forced refresh: Fetch from server
      final coordinates = field.boundary.map((latlng) => [latlng.longitude, latlng.latitude]).toList();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/analyze_plot'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "coordinates": coordinates,
          "crop_name": cropName,
        }),
      );

      if (response.statusCode == 200) {
         final data = json.decode(response.body);
         // Save to cache
         await prefs.setString(cacheKey, json.encode(data));
         await prefs.setString(timeKey, DateTime.now().toIso8601String());
         return data;
      } else {
         print("Failed to analyze field ${field.name}: ${response.statusCode} - ${response.body}");
         return null;
      }
    } catch (e) {
      print("Network error analyzing field ${field.name}: $e");
      return null;
    }
  }
}
