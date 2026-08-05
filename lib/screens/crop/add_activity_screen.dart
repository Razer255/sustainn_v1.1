import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/activity_model.dart';
import '../../theme/app_colors.dart';

/// Add Activity screen — quick-log form for farming activities.
/// Collects: activity type, date, notes, cost, quantity.
/// Includes voice input placeholder button for low-literacy users.
class AddActivityScreen extends StatefulWidget {
  final String cropId;

  const AddActivityScreen({super.key, required this.cropId});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _costController = TextEditingController();
  final _quantityController = TextEditingController();

  ActivityType _selectedType = ActivityType.irrigation;
  DateTime _activityDate = DateTime.now();
  String? _selectedUnit;
  bool _isLoading = false;

  final _unitsByType = {
    ActivityType.irrigation: ['liters', 'mm', 'hours'],
    ActivityType.fertilizer: ['kg', 'bags', 'liters'],
    ActivityType.pesticide: ['ml', 'liters', 'grams'],
    ActivityType.harvest: ['kg', 'quintals', 'tons'],
    ActivityType.sowing: ['kg', 'packets', 'seedlings'],
    ActivityType.weeding: ['hours', 'laborers'],
    ActivityType.soilTesting: ['samples'],
    ActivityType.other: ['units'],
  };

  @override
  void initState() {
    super.initState();
    _selectedUnit = _unitsByType[_selectedType]?.first;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _costController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Activity'),
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
              // ── Activity Type Selector ──
              _buildLabel('Activity Type'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ActivityType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = type;
                        _selectedUnit = _unitsByType[type]?.first;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            type.emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ── Date ──
              _buildLabel('Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${_activityDate.day}/${_activityDate.month}/${_activityDate.year}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit, size: 16, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Notes (with voice input) ──
              _buildLabel('Notes'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Describe the activity...',
                  alignLabelWithHint: true,
                  suffixIcon: IconButton(
                    onPressed: _startVoiceInput,
                    icon: const Icon(Icons.mic, color: AppColors.primary),
                    tooltip: 'Voice input',
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Cost & Quantity row ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cost
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Cost (₹)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _costController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d*')),
                          ],
                          decoration: const InputDecoration(
                            hintText: '0',
                            prefixIcon: Icon(Icons.currency_rupee, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Quantity
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Quantity'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d*')),
                          ],
                          decoration: const InputDecoration(
                            hintText: '0',
                            prefixIcon: Icon(Icons.straighten, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Unit selector
              if (_unitsByType[_selectedType] != null &&
                  _unitsByType[_selectedType]!.isNotEmpty) ...[
                _buildLabel('Unit'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _unitsByType[_selectedType]!.map((unit) {
                    final isSelected = _selectedUnit == unit;
                    return ChoiceChip(
                      label: Text(unit),
                      selected: isSelected,
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedUnit = unit),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 40),

              // ── Save button ──
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveActivity,
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
                  label: Text(_isLoading ? 'Saving...' : 'Log Activity'),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _activityDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _activityDate = picked);
    }
  }

  void _startVoiceInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice input coming in Phase 2 🎤'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _saveActivity() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_selectedType.emoji} ${_selectedType.label} logged successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }
}
