import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../models/field_model.dart';
import '../../services/api_service.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/geo_utils.dart';
import 'mark_field_boundary_screen.dart';

/// Add Field screen — form to create a new agricultural field.
/// Collects: name, area, GPS location, soil type.
class AddFieldScreen extends StatefulWidget {
  const AddFieldScreen({super.key});

  @override
  State<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  String _selectedSoilType = 'Black Cotton';
  String _areaUnit = 'Acres';
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  List<FieldBoundaryPoint> _boundaryPoints = [];

  final _soilTypes = [
    'Black Cotton',
    'Alluvial',
    'Red Laterite',
    'Sandy Loam',
    'Clay',
    'Sandy',
    'Loamy',
    'Saline',
    'Peaty',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Field'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.primaryDark, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Add your field details to start tracking crops and activities.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Field Name
              _buildLabel('Field Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g., North Field, Riverside Plot',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a field name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 22),

              // Area
              _buildLabel('Field Area'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _areaController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Enter area',
                        prefixIcon: Icon(Icons.square_foot),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(val) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _areaUnit,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: ['Acres', 'Hectares', 'Bigha', 'Guntha']
                            .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u,
                                      style: const TextStyle(fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _areaUnit = v ?? 'Acres'),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Field Boundary
              _buildLabel('Field Boundary'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _markBoundary,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _boundaryPoints.isNotEmpty
                        ? AppColors.successLight
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _boundaryPoints.isNotEmpty
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _boundaryPoints.isNotEmpty
                            ? Icons.check_circle
                            : Icons.map_outlined,
                        color: _boundaryPoints.isNotEmpty
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _boundaryPoints.isNotEmpty
                                  ? '${_boundaryPoints.length} points marked'
                                  : 'Tap to mark field boundary on map',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _boundaryPoints.isNotEmpty
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (_boundaryPoints.isNotEmpty && _latitude != null)
                              Text(
                                '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_boundaryPoints.isNotEmpty)
                        TextButton(
                          onPressed: _markBoundary,
                          child: const Text('Redraw'),
                        )
                      else
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Soil Type
              _buildLabel('Soil Type'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedSoilType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.terrain),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  items: _soilTypes
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s,
                                style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedSoilType = v ?? 'Black Cotton'),
                ),
              ),

              const SizedBox(height: 40),

              // Save button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveField,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isLoading ? 'Saving...' : 'Save Field'),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Future<void> _markBoundary() async {
    final points = await Navigator.push<List<LatLng>>(
      context,
      MaterialPageRoute(builder: (_) => const MarkFieldBoundaryScreen()),
    );
    if (points == null || points.length != 4) return;

    final centroid = centroidOf(points);
    final areaAcres = polygonAreaInAcres(points);

    setState(() {
      _boundaryPoints = points
          .map((p) => FieldBoundaryPoint(lat: p.latitude, lng: p.longitude))
          .toList();
      _latitude = centroid.latitude;
      _longitude = centroid.longitude;
      _areaController.text = areaAcres.toStringAsFixed(2);
      _areaUnit = 'Acres';
    });
  }

  Future<void> _saveField() async {
    if (!_formKey.currentState!.validate()) return;
    if (_boundaryPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please mark the field boundary on the map')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final newField = FieldModel(
      id: const Uuid().v4(),
      ownerId: MockData.currentUser.id,
      name: _nameController.text.trim(),
      area: double.parse(_areaController.text),
      latitude: _latitude,
      longitude: _longitude,
      boundaryPoints: _boundaryPoints,
      soilType: _selectedSoilType,
      createdAt: DateTime.now(),
      healthStatus: 'good',
      activeCrops: 0,
      pendingActions: 0,
    );

    try {
      // Save to MongoDB backend
      await ApiService().addField(newField.toMap()..['id'] = newField.id);
      
      // Append locally so UI updates instantly
      MockData.fields.add(newField);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Field added successfully! 🌾'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving field to backend: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
