import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapDrawingScreen extends StatefulWidget {
  final String title;
  final List<LatLng> initialPoints;

  const MapDrawingScreen({
    super.key,
    required this.title,
    this.initialPoints = const [],
  });

  @override
  State<MapDrawingScreen> createState() => _MapDrawingScreenState();
}

class _MapDrawingScreenState extends State<MapDrawingScreen> {
  List<LatLng> _polygonPoints = [];
  LatLng? _selectedPoint;
  bool _hasChanges = false;
  bool _hasSelection = false;
  // Default camera position (e.g., a reasonable starting point)
  static final LatLng _initialCenter = LatLng(
    10.8505,
    76.2711,
  ); // Example: Kerala, India
  Future<void> _searchAddress(String query) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'AgrinetraProject'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          _mapController.move(LatLng(lat, lon), 15); // Move map to location
        }
      }
    } catch (e) {
      print("Search error: $e");
    }
  }

  final MapController _mapController = MapController();
  @override
  void initState() {
    super.initState();
    _polygonPoints = List.from(widget.initialPoints);
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    if (_selectedPoint != null) {
      setState(() {
        _hasChanges = true;
        // Find the index of the selected point and replace it with the new location
        final index = _polygonPoints.indexOf(_selectedPoint!);
        if (index != -1) {
          _polygonPoints[index] = point;
          _selectedPoint = point; // Update selected point reference
        }
      });
      _selectedPoint = null;
    } else {
      setState(() {
        _hasChanges = true;

        // 1. Check if the tap is near an existing marker to select it
        // Simple distance check logic:
        bool foundSelection = false;
        for (var existingPoint in _polygonPoints) {
          final distance = const Distance().as(
            LengthUnit.Meter,
            point,
            existingPoint,
          );
          // If tap is within 5 meters (adjust this tolerance as needed)
          if (distance < 10) {
            _selectedPoint = existingPoint;
            foundSelection = true;
            _hasSelection = true;
            break;
          }
        }
        // 2. If no existing point was tapped, add a new point
        if (!foundSelection) {
          if (_hasSelection) {
            _hasSelection = false;
          } else {
            _polygonPoints.add(point);
          }
          _selectedPoint = null; // Deselect any previous point
        }
      });
    }
  }

  // Function to move a pin to a different position in the sequence
  // This effectively changes which pins are "connected" to each other
  void _reorderPin(int oldIndex, int newIndex) {
    setState(() {
      _hasChanges = true;
      if (newIndex > oldIndex) newIndex -= 1;
      final LatLng item = _polygonPoints.removeAt(oldIndex);
      _polygonPoints.insert(newIndex, item);
    });
  }

  void _handleLongPress(TapPosition tapPosition, LatLng point) {
    if (_selectedPoint != null) {
      setState(() {
        _hasChanges = true;
        // Find the index of the selected point and replace it with the new location
        final index = _polygonPoints.indexOf(_selectedPoint!);
        if (index != -1) {
          _polygonPoints[index] = point;
          _selectedPoint = point; // Update selected point reference
        }
      });
    }
  }

  Future<bool> _showSaveConfirmationDialog() async {
    if (!_hasChanges) {
      return true; // No changes, allow pop
    }

    final saveBoundary = _polygonPoints.length >= 3;

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text(
                'Do you want to save your drawn boundary before leaving?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(true), // Discard changes
                  child: const Text('DISCARD'),
                ),
                if (saveBoundary)
                  ElevatedButton(
                    onPressed: () {
                      // Save and then pop
                      Navigator.of(
                        context,
                      ).pop(false); // Don't allow WillPopScope to proceed
                      _saveAndExit();
                    },
                    child: const Text('SAVE'),
                  ),
              ],
            );
          },
        ) ??
        false; // Default to not allowing back unless confirmed
  }

  void _saveAndExit() {
    if (_polygonPoints.length >= 3) {
      Navigator.pop(context, _polygonPoints);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Boundary must have at least 3 points to save.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Determine if we can save (must have at least 3 points) ---
    final bool canSave = _polygonPoints.length >= 3;

    return PopScope(
      // PopScope replaces WillPopScope in modern Flutter
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldPop = await _showSaveConfirmationDialog();
        if (shouldPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            // Current Location Button
            IconButton(
              icon: const Icon(Icons.location_on),
              onPressed: () {
                // Placeholder for actual geolocation logic
              },
            ),
            // Clear Button
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _polygonPoints = [];
                  _selectedPoint = null;
                  _hasChanges = true;
                });
              },
            ),
            // Save button is now ALWAYS VISIBLE
            TextButton(
              onPressed: canSave
                  ? _saveAndExit
                  : null, // Disabled if can't save
              child: Text(
                'SAVE',
                style: TextStyle(
                  color: canSave ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Card(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search location (e.g. Farm Road, Thodupuzha)",
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onSubmitted: (value) => _searchAddress(value),
                ),
              ),
            ),
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                // --- FIX 1: Enable Zoom Out ---
                initialCenter: widget.initialPoints.isNotEmpty
                    ? widget.initialPoints.first
                    : _initialCenter,
                initialZoom: 10,
                // Ensure all zoom levels are allowed
                minZoom: 1,
                maxZoom: 18,

                // --- End Fix 1 ---
                onTap: _handleTap,
                onLongPress: _handleLongPress,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),

                // Polygon Layer
                PolygonLayer(
                  polygons: [
                    if (_polygonPoints.length >= 3)
                      Polygon(
                        points: _polygonPoints,
                        color: Colors.blue.withOpacity(0.5),
                        borderColor: Colors.blue.shade700,
                        borderStrokeWidth:
                            4, // Thicker border for better visibility
                        isFilled: true,
                      ),
                  ],
                ),

                // Marker Layer
                MarkerLayer(
                  markers: _polygonPoints.asMap().entries.map((entry) {
                    int index = entry.key;
                    LatLng point = entry.value;

                    final bool isSelected = point == _selectedPoint;

                    return Marker(
                      width: 40.0, // Larger tap target
                      height: 40.0,
                      point: point,
                      child: GestureDetector(
                        onTap: () {
                          // Allow explicit pin selection by tapping the marker
                          setState(() {
                            _selectedPoint = point;
                          });
                        },
                        child: Icon(
                          Icons.location_pin,
                          // Highlight the selected pin
                          color: isSelected
                              ? Colors.amber.shade700
                              : Colors.green.shade700,
                          size: isSelected ? 40 : 35,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Floating UI for Selection/Action
            if (_selectedPoint != null)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pin Selected. Tap map to move or:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _polygonPoints.remove(_selectedPoint);
                              _selectedPoint = null;
                              _hasChanges = true;
                            });
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
