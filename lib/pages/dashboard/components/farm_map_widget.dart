import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/field_model.dart';
import '../../../services/field_service.dart';
import '../../../utils/polylabel.dart';

class FarmMapWidget extends StatefulWidget {
  const FarmMapWidget({super.key});

  @override
  State<FarmMapWidget> createState() => _FarmMapWidgetState();
}

class _FarmMapWidgetState extends State<FarmMapWidget> {
  final FieldService _fieldService = FieldService();
  final MapController _mapController = MapController();
  List<Field> _fields = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    // Ensure fields are loaded. If FieldService caches them, getFields() is unrelated to async fetch.
    // But we might want to refresh from backend or ensuring local cache is ready.
    // For now, we assume DashboardPage (parent) might have triggered a load or we just read local.
    // FieldService.getFields returns sync list.
    setState(() {
      _fields = _fieldService.getFields();
      _isLoading = false;
    });
  }

  LatLng _getCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    double lat = 0;
    double lng = 0;
    for (var p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_fields.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F1E8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'No fields added yet.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF5F7D5F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Determine center of map based on first field or default
    LatLng center = _fields.first.boundary.isNotEmpty 
        ? _getCentroid(_fields.first.boundary) 
        : const LatLng(10.8505, 76.2711);

    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
            minZoom: 1,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            PolygonLayer(
              polygons: _fields.map((field) => Polygon(
                points: field.boundary,
                color: field.isCultivated 
                    ? Colors.green.withOpacity(0.4) 
                    : Colors.brown.withOpacity(0.4),
                isFilled: true,
              )).toList(),
            ),
            MarkerLayer(
              markers: _fields.map((field) {
                // Use polylabel to find visual center (best for concave polygons)
                LatLng labelPosition = field.boundary.isNotEmpty 
                    ? getPolylabel(field.boundary) 
                    : const LatLng(0, 0);

                return Marker(
                  point: labelPosition,
                  width: 100,
                  height: 40,
                  child: Center(
                    child: Text(
                      field.name,
                      style: const TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.bold,
                        // No shadow for cleaner "native" look, or slight halo if needed
                        shadows: [Shadow(offset: Offset(0,0), blurRadius: 3, color: Colors.white)],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
