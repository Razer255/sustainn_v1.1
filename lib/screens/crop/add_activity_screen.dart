import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../models/activity_field_defs.dart';
import '../../models/activity_model.dart';
import '../../models/activity_taxonomy.dart';
import '../../models/financial_model.dart';
import '../../models/input_catalogue.dart';
import '../../services/api_service.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';

/// Add Activity screen — quick-log form for farming activities.
///
/// Category, sub-activity and unit are picked via three cascading
/// dropdowns (Category → Sub-activity → Unit), backed by the
/// [ActivityCategory] / [ActivitySubtype] taxonomy (spec §4). Below that,
/// the screen renders category-specific fields (spec §5) — a generic set
/// driven by [kCategoryFields] for most categories, plus bespoke widgets
/// for NUTRIENT (multi-product rows + live NPK summary), WEED and
/// PLANT_PROTECT (multi-select species/pests).
///
/// Also collects: date, area covered, notes, cost, quantity.
/// Includes voice input placeholder button for low-literacy users.
class AddActivityScreen extends StatefulWidget {
  final String cropId;

  const AddActivityScreen({super.key, required this.cropId});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

/// One row in the NUTRIENT product list.
class _ProductLine {
  String? itemCode;
  double? quantity;
}

const List<String> _kAreaUnits = ['acre', 'hectare', 'bigha'];
const double _kAcresPerHectare = 2.471;

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _costController = TextEditingController();
  final _quantityController = TextEditingController();
  final _areaController = TextEditingController();

  ActivityCategory _selectedCategory = ActivityCategory.irrigation;
  late ActivitySubtype _selectedSubtype;
  DateTime _activityDate = DateTime.now();
  String? _selectedUnit;
  String _areaUnit = _kAreaUnits.first;
  bool _isLoading = false;

  // Generic category fields, keyed by ActivityFieldDef.key.
  final Map<String, dynamic> _attributeValues = {};

  // Bespoke NUTRIENT product rows.
  final List<_ProductLine> _productLines = [];

  // Bespoke WEED / PLANT_PROTECT multi-selects.
  final Set<String> _weedSpecies = {};
  final Set<String> _pestsDiseases = {};

  @override
  void initState() {
    super.initState();
    _selectedSubtype = subtypesFor(_selectedCategory).first;
    _selectedUnit = kUnitsByCategory[_selectedCategory]?.first;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _costController.dispose();
    _quantityController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(ActivityCategory? category) {
    if (category == null) return;
    setState(() {
      _selectedCategory = category;
      _selectedSubtype = subtypesFor(category).first;
      _selectedUnit = kUnitsByCategory[category]?.first;
      _attributeValues.clear();
      _productLines.clear();
      _weedSpecies.clear();
      _pestsDiseases.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtypes = subtypesFor(_selectedCategory);
    final units = kUnitsByCategory[_selectedCategory] ?? const [];

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
              // ── Activity Category dropdown ──
              _buildLabel('Activity Category'),
              const SizedBox(height: 8),
              _buildDropdown<ActivityCategory>(
                value: _selectedCategory,
                items: ActivityCategory.values,
                onChanged: _onCategoryChanged,
                itemBuilder: (category) => Row(
                  children: [
                    Text(category.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${category.label}  ·  ${category.labelHi}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Sub-activity dropdown (filtered by category) ──
              _buildLabel('Sub-activity'),
              const SizedBox(height: 8),
              _buildDropdown<ActivitySubtype>(
                value: _selectedSubtype,
                items: subtypes,
                onChanged: (subtype) {
                  if (subtype != null) {
                    setState(() => _selectedSubtype = subtype);
                  }
                },
                itemBuilder: (subtype) => Text(
                  subtype.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 20),

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

              // ── Area covered ──
              _buildLabel('Area covered'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _areaController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        hintText: '0',
                        prefixIcon: Icon(Icons.crop_square, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown<String>(
                      value: _areaUnit,
                      items: _kAreaUnits,
                      onChanged: (unit) {
                        if (unit != null) setState(() => _areaUnit = unit);
                      },
                      itemBuilder: (unit) => Text(unit),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Category-specific fields (spec §5) ──
              ..._buildCategoryFields(),

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

              // ── Unit dropdown (defaulted by category) ──
              if (units.isNotEmpty) ...[
                _buildLabel('Unit'),
                const SizedBox(height: 8),
                _buildDropdown<String>(
                  value: _selectedUnit ?? units.first,
                  items: units,
                  onChanged: (unit) {
                    if (unit != null) {
                      setState(() => _selectedUnit = unit);
                    }
                  },
                  itemBuilder: (unit) => Text(unit),
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

  // ─── Category-specific field rendering ──────────────────────────

  List<Widget> _buildCategoryFields() {
    switch (_selectedCategory) {
      case ActivityCategory.nutrient:
        return [..._buildNutrientFields(), const SizedBox(height: 24)];
      case ActivityCategory.weed:
        return [
          ..._buildGenericFields(kCategoryFields[_selectedCategory] ?? const []),
          ..._buildMultiSelect(
            label: 'Dominant weed species',
            options: kWeedSpecies,
            selected: _weedSpecies,
          ),
          const SizedBox(height: 24),
        ];
      case ActivityCategory.plantProtect:
        return [
          ..._buildGenericFields(kCategoryFields[_selectedCategory] ?? const []),
          ..._buildMultiSelect(
            label: 'Pest or disease observed',
            options: kPestsDiseases,
            selected: _pestsDiseases,
          ),
          const SizedBox(height: 24),
        ];
      default:
        final fields = kCategoryFields[_selectedCategory];
        if (fields == null || fields.isEmpty) return [];
        return [..._buildGenericFields(fields), const SizedBox(height: 24)];
    }
  }

  List<Widget> _buildGenericFields(List<ActivityFieldDef> fields) {
    final widgets = <Widget>[];
    for (final field in fields) {
      widgets.add(_buildLabel(field.label + (field.unitSuffix != null ? ' (${field.unitSuffix})' : '')));
      widgets.add(const SizedBox(height: 8));
      switch (field.type) {
        case ActivityFieldType.text:
          widgets.add(TextFormField(
            initialValue: _attributeValues[field.key] as String?,
            onChanged: (v) => _attributeValues[field.key] = v,
            decoration: const InputDecoration(hintText: 'Enter value'),
          ));
          break;
        case ActivityFieldType.number:
          widgets.add(TextFormField(
            initialValue: _attributeValues[field.key]?.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
            ],
            onChanged: (v) => _attributeValues[field.key] = double.tryParse(v),
            decoration: const InputDecoration(hintText: '0'),
          ));
          break;
        case ActivityFieldType.boolean:
          widgets.add(_buildDropdown<bool>(
            value: (_attributeValues[field.key] as bool?) ?? false,
            items: const [false, true],
            onChanged: (v) => setState(() => _attributeValues[field.key] = v),
            itemBuilder: (v) => Text(v ? 'Yes' : 'No'),
          ));
          break;
        case ActivityFieldType.date:
          widgets.add(_buildDateField(field.key));
          break;
        case ActivityFieldType.dropdown:
          final options = field.options ?? const [];
          widgets.add(_buildDropdown<String>(
            value: (_attributeValues[field.key] as String?) ?? options.first,
            items: options,
            onChanged: (v) => setState(() => _attributeValues[field.key] = v),
            itemBuilder: (v) => Text(v),
          ));
          break;
      }
      widgets.add(const SizedBox(height: 20));
    }
    return widgets;
  }

  Widget _buildDateField(String key) {
    final value = _attributeValues[key] as DateTime?;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? _activityDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) {
          setState(() => _attributeValues[key] = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              value == null
                  ? 'Select date'
                  : '${value.day}/${value.month}/${value.year}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMultiSelect({
    required String label,
    required List<String> options,
    required Set<String> selected,
  }) {
    return [
      _buildLabel(label),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          final isSelected = selected.contains(option);
          return FilterChip(
            label: Text(option),
            selected: isSelected,
            selectedColor: AppColors.primaryLight,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            onSelected: (value) {
              setState(() {
                if (value) {
                  selected.add(option);
                } else {
                  selected.remove(option);
                }
              });
            },
          );
        }).toList(),
      ),
      const SizedBox(height: 20),
    ];
  }

  // ─── NUTRIENT: multi-product rows + live NPK summary ────────────

  List<Widget> _buildNutrientFields() {
    final widgets = <Widget>[
      ..._buildGenericFields(kCategoryFields[ActivityCategory.nutrient] ?? const []),
      _buildLabel('Products applied'),
      const SizedBox(height: 8),
    ];

    for (var i = 0; i < _productLines.length; i++) {
      widgets.add(_buildProductLineRow(i));
      widgets.add(const SizedBox(height: 10));
    }

    widgets.add(
      OutlinedButton.icon(
        onPressed: () => setState(() => _productLines.add(_ProductLine())),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add product'),
      ),
    );

    widgets.add(const SizedBox(height: 16));
    widgets.add(_buildNpkSummary());

    return widgets;
  }

  Widget _buildProductLineRow(int index) {
    final line = _productLines[index];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: _buildDropdown<String?>(
            value: line.itemCode,
            items: [null, ...kInputItems.map((item) => item.code)],
            onChanged: (code) => setState(() => line.itemCode = code),
            itemBuilder: (code) => Text(
              code == null ? 'Select product' : inputItemByCode(code)!.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            initialValue: line.quantity?.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
            ],
            onChanged: (v) => line.quantity = double.tryParse(v),
            decoration: const InputDecoration(hintText: 'kg'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18, color: AppColors.textHint),
          onPressed: () => setState(() => _productLines.removeAt(index)),
        ),
      ],
    );
  }

  Widget _buildNpkSummary() {
    double totalN = 0, totalP = 0, totalK = 0;
    for (final line in _productLines) {
      final item = inputItemByCode(line.itemCode);
      final qty = line.quantity;
      if (item == null || qty == null) continue;
      totalN += qty * item.nPct / 100;
      totalP += qty * item.p2o5Pct / 100;
      totalK += qty * item.k2oPct / 100;
    }

    final areaValue = double.tryParse(_areaController.text);
    double? areaInAcres;
    if (areaValue != null && areaValue > 0) {
      areaInAcres = switch (_areaUnit) {
        'hectare' => areaValue * _kAcresPerHectare,
        _ => areaValue, // acre and bigha treated as acre for this estimate
      };
    }

    final perAcre = areaInAcres != null && areaInAcres > 0;
    final n = perAcre ? totalN / areaInAcres : totalN;
    final p = perAcre ? totalP / areaInAcres : totalP;
    final k = perAcre ? totalK / areaInAcres : totalK;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Total applied: ${n.toStringAsFixed(1)} kg N, '
        '${p.toStringAsFixed(1)} kg P₂O₅, '
        '${k.toStringAsFixed(1)} kg K₂O'
        '${perAcre ? ' per acre' : ''}',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  // ─── Shared small widgets ────────────────────────────────────────

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

  /// A dropdown styled to match the other input containers on this screen
  /// (Date field etc.) rather than the default Material underline look.
  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required Widget Function(T item) itemBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textHint),
          borderRadius: BorderRadius.circular(12),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: itemBuilder(item),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final costVal = double.tryParse(_costController.text);
    final qtyVal = double.tryParse(_quantityController.text);
    final areaVal = double.tryParse(_areaController.text);

    final attributes = Map<String, dynamic>.from(_attributeValues);
    // Serialize DateTime attribute values to ISO strings for the wire format.
    for (final entry in attributes.entries.toList()) {
      if (entry.value is DateTime) {
        attributes[entry.key] = (entry.value as DateTime).toIso8601String();
      }
    }
    if (_selectedCategory == ActivityCategory.nutrient) {
      attributes['productLines'] = _productLines
          .where((l) => l.itemCode != null)
          .map((l) => {'itemCode': l.itemCode, 'quantity': l.quantity})
          .toList();
    }
    if (_selectedCategory == ActivityCategory.weed) {
      attributes['weedSpecies'] = _weedSpecies.toList();
    }
    if (_selectedCategory == ActivityCategory.plantProtect) {
      attributes['pestsDiseases'] = _pestsDiseases.toList();
    }

    final newActivity = ActivityModel(
      id: const Uuid().v4(),
      cropId: widget.cropId,
      category: _selectedCategory,
      subtypeCode: _selectedSubtype.code,
      date: _activityDate,
      areaCovered: areaVal,
      areaUnit: areaVal != null ? _areaUnit : null,
      notes: _notesController.text.trim(),
      cost: costVal,
      quantity: qtyVal,
      unit: _selectedUnit,
      createdBy: MockData.currentUser.id,
      attributes: attributes,
    );

    try {
      // Save to MongoDB backend
      await ApiService().addActivity(newActivity.toMap()..['id'] = newActivity.id);

      // Update crop activity count locally
      final cropIndex = MockData.crops.indexWhere((c) => c.id == widget.cropId);
      if (cropIndex != -1) {
        final c = MockData.crops[cropIndex];
        MockData.crops[cropIndex] = c.copyWith(activityCount: c.activityCount + 1);
      }

      // Update financial cost locally
      if (costVal != null && costVal > 0) {
        final finIndex = MockData.financials.indexWhere((f) => f.cropId == widget.cropId);
        if (finIndex != -1) {
          final f = MockData.financials[finIndex];
          MockData.financials[finIndex] = f.copyWith(
            inputCost: f.inputCost + costVal,
            updatedAt: DateTime.now(),
          );
        } else {
          MockData.financials.add(FinancialModel(
            id: const Uuid().v4(),
            cropId: widget.cropId,
            inputCost: costVal,
            expectedRevenue: 0,
            actualRevenue: 0,
            updatedAt: DateTime.now(),
          ));
        }
      }

      // Append locally so UI updates instantly
      MockData.activities.add(newActivity);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_selectedCategory.emoji} ${_selectedSubtype.label} logged successfully!'),
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
            content: Text('Error saving activity to backend: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
