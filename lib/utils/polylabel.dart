import 'dart:math';
import 'package:latlong2/latlong.dart';

// Port of Mapbox's polylabel algorithm
// Finds the pole of inaccessibility (the most distant point from the polygon outline)

class _Cell {
  final double x;
  final double y;
  final double h;
  final double d;
  final double max;

  _Cell(this.x, this.y, this.h, this.d) : max = d + h * sqrt2;
}

LatLng getPolylabel(List<LatLng> polygon, {double precision = 1.0, bool debug = false}) {
  if (polygon.isEmpty) return const LatLng(0, 0);

  // Convert LatLng to simple x,y for calculation (using simplified equirectangular projection approximation for small distances)
  // For a perfect implementation one might need projection, but for field scale, direct lat/lng mapping is usually sufficient for relative "center" finding.
  // We will map lat->y, lng->x
  
  double minX = polygon[0].longitude;
  double minY = polygon[0].latitude;
  double maxX = polygon[0].longitude;
  double maxY = polygon[0].latitude;

  for (var p in polygon) {
    if (p.longitude < minX) minX = p.longitude;
    if (p.latitude < minY) minY = p.latitude;
    if (p.longitude > maxX) maxX = p.longitude;
    if (p.latitude > maxY) maxY = p.latitude;
  }

  double width = maxX - minX;
  double height = maxY - minY;
  double cellSize = min(width, height);
  double h = cellSize / 2;

  if (cellSize == 0) return polygon[0];

  final List<_Cell> cellQueue = [];

  // Cover polygon with initial cells
  for (double x = minX; x < maxX; x += cellSize) {
    for (double y = minY; y < maxY; y += cellSize) {
      cellQueue.add(_Cell(x + h, y + h, h, _pointToPolygonDist(x + h, y + h, polygon)));
    }
  }

  // Sort by max potential distance
  cellQueue.sort((a, b) => b.max.compareTo(a.max));

  _Cell bestCell = _Cell(0, 0, 0, double.negativeInfinity);
  // Initial best guess: centroid
  // (Skipping centroid calculation for brevity, starting with first cell)
  
  while (cellQueue.isNotEmpty) {
    _Cell cell = cellQueue.removeAt(0);

    if (cell.d > bestCell.d) {
      bestCell = cell;
    }

    if (cell.max - bestCell.d <= precision * 0.00001) continue; // Precision scaling for latlng

    h = cell.h / 2;
    cellQueue.add(_Cell(cell.x - h, cell.y - h, h, _pointToPolygonDist(cell.x - h, cell.y - h, polygon)));
    cellQueue.add(_Cell(cell.x + h, cell.y - h, h, _pointToPolygonDist(cell.x + h, cell.y - h, polygon)));
    cellQueue.add(_Cell(cell.x - h, cell.y + h, h, _pointToPolygonDist(cell.x - h, cell.y + h, polygon)));
    cellQueue.add(_Cell(cell.x + h, cell.y + h, h, _pointToPolygonDist(cell.x + h, cell.y + h, polygon)));
    
    cellQueue.sort((a, b) => b.max.compareTo(a.max));
  }

  return LatLng(bestCell.y, bestCell.x);
}

double _pointToPolygonDist(double x, double y, List<LatLng> polygon) {
  bool inside = false;
  double minDistSq = double.infinity;

  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    double xi = polygon[i].longitude;
    double yi = polygon[i].latitude;
    double xj = polygon[j].longitude;
    double yj = polygon[j].latitude;

    if ((yi > y) != (yj > y) &&
        (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }

    // Squared distance to segment
    // ... approximation for simplicity, using simple euclidean on latlng degrees
    // For "pole of inaccessibility", we need distance to closest edge.
    
    double dx = xi - x;
    double dy = yi - y;
    double d2 = dx*dx + dy*dy;
    // (Optimization: distance to infinite line, then clamped to segment)
    // For now, using vertex distance is a rough approximation, 
    // BUT true polylabel needs distance to SEGMENT.
    
    // Segment projection
    /*
    double len2 = (xj - xi)*(xj - xi) + (yj - yi)*(yj - yi);
    if (len2 > 0) {
      double t = ((x - xi) * (xj - xi) + (y - yi) * (yj - yi)) / len2;
      t = max(0, min(1, t));
      dx = x - (xi + t * (xj - xi));
      dy = y - (yi + t * (yj - yi));
      d2 = dx * dx + dy * dy;
    }
    */
    // Implementing segment distance correctly:
    double segmentLenSq = (xj - xi) * (xj - xi) + (yj - yi) * (yj - yi);
    if (segmentLenSq == 0) {
       d2 = (x - xi) * (x - xi) + (y - yi) * (y - yi);
    } else {
       double t = ((x - xi) * (xj - xi) + (y - yi) * (yj - yi)) / segmentLenSq;
       t = max(0.0, min(1.0, t));
       double projX = xi + t * (xj - xi);
       double projY = yi + t * (yj - yi);
       d2 = (x - projX) * (x - projX) + (y - projY) * (y - projY);
    }

    if (d2 < minDistSq) minDistSq = d2;
  }

  return inside ? sqrt(minDistSq) : -sqrt(minDistSq);
}
