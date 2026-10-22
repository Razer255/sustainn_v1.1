import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../models/crop_model.dart';
import '../../services/api_service.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';

/// Add Crop screen — form to add a new crop to a field.
/// Collects: crop name (searchable), variety, sowing date.
///
/// When [existingCrop] is set, the screen edits that crop in place
/// instead of creating a new one.
class AddCropScreen extends StatefulWidget {
  final String fieldId;
  final CropModel? existingCrop;

  const AddCropScreen({super.key, required this.fieldId, this.existingCrop});

  bool get isEditing => existingCrop != null;

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _varietyController = TextEditingController();
  final _searchController = TextEditingController();
  final _areaController = TextEditingController();
  String? _selectedCrop;
  DateTime _sownDate = DateTime.now();
  DateTime? _expectedHarvest;
  bool _isLoading = false;
  bool _showCropSearch = false;
  bool _isIntercrop = false;

  final _cropList = [
    'Rice (Paddy)',
    'Wheat',
    'Cotton',
    'Soybean',
    'Sugarcane',
    'Maize (Corn)',
    'Jowar (Sorghum)',
    'Bajra (Pearl Millet)',
    'Groundnut',
    'Sunflower',
    'Turmeric',
    'Onion',
    'Tomato',
    'Chilli',
    'Potato',
    'Brinjal (Eggplant)',
    'Okra (Lady Finger)',
    'Chickpea (Chana)',
    'Pigeon Pea (Tur Dal)',
    'Mustard',
    'Banana',
    'Mango',
    'Grapes',
    'Pomegranate',
  ];

  List<String> get _filteredCrops {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _cropList;
    return _cropList
        .where((c) => c.toLowerCase().contains(query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existingCrop;
    if (existing != null) {
      _selectedCrop = existing.cropName;
      _varietyController.text = existing.variety;
      _areaController.text = existing.areaCovered.toString();
      _isIntercrop = existing.isIntercrop;
      _sownDate = existing.sownDate;
      _expectedHarvest = existing.expectedHarvestDate;
    }
  }

  @override
  void dispose() {
    _varietyController.dispose();
    _searchController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Crop' : 'Add Crop'),
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
              // Crop Name (searchable)
              _buildLabel('Crop Name'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _showCropSearch = true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedCrop != null
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.grass, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedCrop ?? 'Select a crop',
                          style: TextStyle(
                            fontSize: 15,
                            color: _selectedCrop != null
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                            fontWeight: _selectedCrop != null
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.textHint),
                    ],
                  ),
                ),
              ),

              // Searchable crop list (shown when tapped)
              if (_showCropSearch) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search crops...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filteredCrops.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final crop = _filteredCrops[i];
                      return ListTile(
                        title: Text(crop, style: const TextStyle(fontSize: 14)),
                        dense: true,
                        selected: _selectedCrop == crop,
                        selectedTileColor: AppColors.primaryLight,
                        onTap: () {
                          setState(() {
                            _selectedCrop = crop;
                            _showCropSearch = false;
                            _searchController.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // Variety
              _buildLabel('Variety / Hybrid'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _varietyController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g., Basmati 1121, Bt Cotton',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the variety';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 22),

              // Area Covered
              _buildLabel('Area Covered (acres)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _areaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                ],
                decoration: const InputDecoration(
                  hintText: '0.0',
                  prefixIcon: Icon(Icons.crop_square),
                ),
                validator: (val) {
                  final area = double.tryParse(val ?? '');
                  if (area == null || area <= 0) {
                    return 'Please enter the area covered by this crop';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}), // refresh capacity helper text
              ),
              const SizedBox(height: 6),
              _buildCapacityHelperText(),

              const SizedBox(height: 14),

              // Intercrop checkbox
              CheckboxListTile(
                value: _isIntercrop,
                onChanged: (val) => setState(() => _isIntercrop = val ?? false),
                title: const Text(
                  'This is an intercrop',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Grown alongside another crop on the same land',
                  style: TextStyle(fontSize: 12),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
              ),

              const SizedBox(height: 6),

              // Sowing Date
              _buildLabel('Sowing Date'),
              const SizedBox(height: 8),
              _DatePickerField(
                date: _sownDate,
                label: 'Select sowing date',
                icon: Icons.calendar_today,
                onDateSelected: (d) => setState(() => _sownDate = d),
              ),

              const SizedBox(height: 22),

              // Expected Harvest Date
              _buildLabel('Expected Harvest Date (Optional)'),
              const SizedBox(height: 8),
              _DatePickerField(
                date: _expectedHarvest,
                label: 'Select expected harvest date',
                icon: Icons.event,
                onDateSelected: (d) =>
                    setState(() => _expectedHarvest = d),
              ),

              const SizedBox(height: 40),

              // Save button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveCrop,
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
                  label: Text(_isLoading
                      ? 'Saving...'
                      : (widget.isEditing ? 'Update Crop' : 'Add Crop')),
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

  /// Occupied area on the field if this crop were saved with [newArea],
  /// given the occupancy rule: sum(non-intercrop areas) + max(intercrop
  /// areas). When editing, the crop being edited is excluded from the
  /// "existing" totals so it isn't double-counted against itself.
  /// A non-intercrop crop always adds on top. An intercrop crop only
  /// raises the total if it's larger than any other intercrop crop on
  /// the field (since intercrops share the same patch of land).
  double _projectedOccupiedArea(double newArea) {
    final cropsForField = MockData.getCropsForField(widget.fieldId)
        .where((c) => c.id != widget.existingCrop?.id);
    final nonIntercropSum = cropsForField
        .where((c) => !c.isIntercrop)
        .fold<double>(0, (sum, c) => sum + c.areaCovered);
    final existingMaxIntercrop = cropsForField
        .where((c) => c.isIntercrop)
        .fold<double>(0, (max, c) => c.areaCovered > max ? c.areaCovered : max);

    if (_isIntercrop) {
      final maxIntercrop = newArea > existingMaxIntercrop ? newArea : existingMaxIntercrop;
      return nonIntercropSum + maxIntercrop;
    }
    return nonIntercropSum + newArea + existingMaxIntercrop;
  }

  /// Live "X of Y acres available" hint under the area field, accounting
  /// for the field's current occupancy: sum(non-intercrop areas) +
  /// max(intercrop areas) — since intercrop crops share the same patch
  /// of land simultaneously rather than each claiming their own.
  Widget _buildCapacityHelperText() {
    final field = MockData.fields.firstWhere((f) => f.id == widget.fieldId);
    final occupied = MockData.getOccupiedAreaForField(
      widget.fieldId,
      excludeCropId: widget.existingCrop?.id,
    );
    final available = field.area - occupied;
    final entered = double.tryParse(_areaController.text) ?? 0;

    final wouldOverflow = _projectedOccupiedArea(entered) > field.area;

    return Text(
      wouldOverflow
          ? 'Only ${available.toStringAsFixed(1)} of ${field.area.toStringAsFixed(1)} acres available on ${field.name}'
          : '${available.toStringAsFixed(1)} of ${field.area.toStringAsFixed(1)} acres available on ${field.name}',
      style: TextStyle(
        fontSize: 12,
        color: wouldOverflow ? AppColors.warning : AppColors.textSecondary,
        fontWeight: wouldOverflow ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  /// Soft warning, always overridable — matches the app's "the farmer knows
  /// his field" philosophy used elsewhere (e.g. activity logging).
  Future<bool?> _confirmOverAllocation({
    required String fieldName,
    required double available,
    required double fieldArea,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Area exceeds field capacity'),
        content: Text(
          'This exceeds $fieldName\'s remaining area '
          '(${available.toStringAsFixed(1)} of ${fieldArea.toStringAsFixed(1)} acres available). '
          'Save anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCrop() async {
    if (_selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final area = double.parse(_areaController.text);
    final field = MockData.fields.firstWhere((f) => f.id == widget.fieldId);

    // Warn but allow — occupancy rule: sum(non-intercrop areas) +
    // max(intercrop areas), since intercrop crops share the same patch
    // of land simultaneously rather than each claiming their own.
    final isEditing = widget.isEditing;
    final projectedOccupied = _projectedOccupiedArea(area);
    if (projectedOccupied > field.area) {
      final available = field.area -
          MockData.getOccupiedAreaForField(
            widget.fieldId,
            excludeCropId: widget.existingCrop?.id,
          );
      final proceed = await _confirmOverAllocation(
        fieldName: field.name,
        available: available,
        fieldArea: field.area,
      );
      if (proceed != true) return;
    }

    setState(() => _isLoading = true);

    final crop = CropModel(
      id: isEditing ? widget.existingCrop!.id : const Uuid().v4(),
      fieldId: widget.fieldId,
      season: isEditing ? widget.existingCrop!.season : 'Kharif 2026',
      cropName: _selectedCrop!,
      variety: _varietyController.text.trim(),
      sownDate: _sownDate,
      expectedHarvestDate: _expectedHarvest,
      status: isEditing ? widget.existingCrop!.status : CropStatus.active,
      isIntercrop: _isIntercrop,
      areaCovered: area,
      healthStatus: isEditing ? widget.existingCrop!.healthStatus : 'good',
      activityCount: isEditing ? widget.existingCrop!.activityCount : 0,
    );

    try {
      if (isEditing) {
        await ApiService().updateCrop(crop.id, crop.toMap());

        final index = MockData.crops.indexWhere((c) => c.id == crop.id);
        if (index != -1) {
          MockData.crops[index] = crop;
        }
      } else {
        // Save to MongoDB backend
        await ApiService().addCrop(crop.toMap()..['id'] = crop.id);

        // Update field active crops count locally
        final fieldIndex = MockData.fields.indexWhere((f) => f.id == widget.fieldId);
        if (fieldIndex != -1) {
          final f = MockData.fields[fieldIndex];
          MockData.fields[fieldIndex] = f.copyWith(activeCrops: f.activeCrops + 1);
        }

        // Append locally so UI updates instantly
        MockData.crops.add(crop);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'Crop updated successfully! 🌱'
                : 'Crop added successfully! 🌱'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving crop to backend: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Reusable date picker field.
class _DatePickerField extends StatelessWidget {
  final DateTime? date;
  final String label;
  final IconData icon;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerField({
    required this.date,
    required this.label,
    required this.icon,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: date != null
                    ? AppColors.primary
                    : AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              date != null
                  ? '${date!.day}/${date!.month}/${date!.year}'
                  : label,
              style: TextStyle(
                fontSize: 14,
                color:
                    date != null ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
