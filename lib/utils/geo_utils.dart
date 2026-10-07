/// Small geo-math helpers for the field-boundary map (§ Add Field).
/// Good enough accuracy at farm-plot scale (a few acres) — not survey-grade.
library;

import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

const double _earthRadiusMeters = 6371000;
const double _squareMetersPerAcre = 4046.86;

/// Area of a polygon on the earth's surface, in acres.
///
/// Projects lat/lng to a local flat approximation (equirectangular,
/// scaled by the polygon's mean latitude) and applies the standard
/// shoelace formula — accurate enough for a farm field's few acres.
double polygonAreaInAcres(List<LatLng> points) {
  if (points.length < 3) return 0;

  final meanLatRad = points.map((p) => p.latitudeInRad).reduce((a, b) => a + b) / points.length;
  final cosMeanLat = math.cos(meanLatRad);

  double toX(LatLng p) => p.longitudeInRad * _earthRadiusMeters * cosMeanLat;
  double toY(LatLng p) => p.latitudeInRad * _earthRadiusMeters;

  double areaSum = 0;
  for (var i = 0; i < points.length; i++) {
    final p1 = points[i];
    final p2 = points[(i + 1) % points.length];
    areaSum += toX(p1) * toY(p2) - toX(p2) * toY(p1);
  }

  final areaSqMeters = areaSum.abs() / 2;
  return areaSqMeters / _squareMetersPerAcre;
}

/// Simple average of a list of points — used as the field's stored
/// single-point latitude/longitude.
LatLng centroidOf(List<LatLng> points) {
  final lat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
  final lng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
  return LatLng(lat, lng);
}
