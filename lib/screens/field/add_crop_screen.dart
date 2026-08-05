import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Add Crop screen — form to add a new crop to a field.
/// Collects: crop name (searchable), variety, sowing date.
class AddCropScreen extends StatefulWidget {
  final String fieldId;

  const AddCropScreen({super.key, required this.fieldId});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _varietyController = TextEditingController();
  final _searchController = TextEditingController();
  String? _selectedCrop;
  DateTime _sownDate = DateTime.now();
  DateTime? _expectedHarvest;
  bool _isLoading = false;
  bool _showCropSearch = false;

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
  void dispose() {
    _varietyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Crop'),
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
                  label: Text(_isLoading ? 'Saving...' : 'Add Crop'),
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

  Future<void> _saveCrop() async {
    if (_selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crop added successfully! 🌱'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
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
