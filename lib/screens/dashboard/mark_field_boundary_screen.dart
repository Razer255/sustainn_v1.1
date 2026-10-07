import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_colors.dart';
import '../../utils/geo_utils.dart';

const int _kBoundaryPointCount = 4;

/// Full-screen map for marking a field's 4-corner boundary.
/// Tap up to 4 points → live polygon preview + area readout → Confirm
/// returns the 4 [LatLng] points to the caller (Add Field).
class MarkFieldBoundaryScreen extends StatefulWidget {
  const MarkFieldBoundaryScreen({super.key});

  @override
  State<MarkFieldBoundaryScreen> createState() => _MarkFieldBoundaryScreenState();
}

class _MarkFieldBoundaryScreenState extends State<MarkFieldBoundaryScreen> {
  final _mapController = MapController();
  final List<LatLng> _points = [];
  bool _isLocating = false;
  bool _isSatellite = false;

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_points.length >= _kBoundaryPointCount) return;
    setState(() => _points.add(point));
  }

  void _undoLast() {
    if (_points.isEmpty) return;
    setState(() => _points.removeLast());
  }

  void _clearAll() {
    setState(() => _points.clear());
  }

  Future<void> _useMyLocation() async {
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled');
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      _mapController.move(LatLng(position.latitude, position.longitude), 17);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't get your location: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _confirm() {
    if (_points.length != _kBoundaryPointCount) return;
    Navigator.pop(context, List<LatLng>.from(_points));
  }

  @override
  Widget build(BuildContext context) {
    final areaAcres = _points.length >= 3 ? polygonAreaInAcres(_points) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Field Boundary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo last point',
            onPressed: _points.isEmpty ? null : _undoLast,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear all',
            onPressed: _points.isEmpty ? null : _clearAll,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(18.5204, 73.8567), // Pune fallback
              initialZoom: 16,
              onTap: _onMapTap,
            ),
            children: [
              if (_isSatellite)
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.sustainn.farmer_app',
                )
              else
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sustainn.farmer_app',
                ),
              if (_points.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _points,
                      color: AppColors.primary.withOpacity(0.25),
                      borderColor: AppColors.primary,
                      borderStrokeWidth: 2,
                    ),
                  ],
                )
              else if (_points.length == 2)
                PolylineLayer(
                  polylines: [
                    Polyline(points: _points, color: AppColors.primary, strokeWidth: 2),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (var i = 0; i < _points.length; i++)
                    Marker(
                      point: _points[i],
                      width: 32,
                      height: 32,
                      child: _NumberedPin(number: i + 1),
                    ),
                ],
              ),
            ],
          ),

          // Instructions / status banner
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
                ],
              ),
              child: Text(
                _points.length < _kBoundaryPointCount
                    ? 'Tap ${_kBoundaryPointCount - _points.length} more corner${_kBoundaryPointCount - _points.length == 1 ? '' : 's'} of the field'
                    : 'All 4 corners marked${areaAcres > 0 ? ' · ${areaAcres.toStringAsFixed(2)} acres' : ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),

          // Satellite / street toggle FAB
          Positioned(
            bottom: 164,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'toggle_satellite',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              tooltip: _isSatellite ? 'Switch to street view' : 'Switch to satellite view',
              onPressed: () => setState(() => _isSatellite = !_isSatellite),
              child: Icon(_isSatellite ? Icons.map_outlined : Icons.satellite_alt),
            ),
          ),

          // Use my location FAB
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'use_my_location',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              onPressed: _isLocating ? null : _useMyLocation,
              child: _isLocating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _points.length == _kBoundaryPointCount ? _confirm : null,
              icon: const Icon(Icons.check),
              label: Text(
                _points.length == _kBoundaryPointCount
                    ? 'Confirm Boundary'
                    : '${_points.length} / $_kBoundaryPointCount points marked',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberedPin extends StatelessWidget {
  final int number;

  const _NumberedPin({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
        ],
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
