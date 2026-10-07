/// Conditional per-category attribute fields (spec §5).
///
/// Hardcoded for now — same "shaped like a future master-table API response"
/// spirit as [ActivitySubtype]. Every field here is optional; nothing in
/// this module is validation-blocking (spec §1: never block a save because
/// a field is empty).
library;

import 'activity_taxonomy.dart';

enum ActivityFieldType { text, number, dropdown, boolean, date }

class ActivityFieldDef {
  final String key;
  final String label;
  final ActivityFieldType type;
  final List<String>? options; // for dropdown
  final String? unitSuffix; // e.g. 'cm', '%', 'HP'

  const ActivityFieldDef(
    this.key,
    this.label,
    this.type, {
    this.options,
    this.unitSuffix,
  });
}

/// Extra fields per category, beyond the generic date/area/notes/cost/qty/unit.
///
/// NUTRIENT, WEED and PLANT_PROTECT are handled by bespoke widgets on the
/// screen (multi-row product list, multi-select species/pests) and are not
/// listed here. OTHER has no extra fields — Notes already covers "free text
/// description".
const Map<ActivityCategory, List<ActivityFieldDef>> kCategoryFields = {
  ActivityCategory.landPrep: [
    ActivityFieldDef('implementUsed', 'Implement used', ActivityFieldType.text),
    ActivityFieldDef('numberOfPasses', 'Number of passes', ActivityFieldType.number),
    ActivityFieldDef('depth', 'Depth', ActivityFieldType.number, unitSuffix: 'cm'),
    ActivityFieldDef(
      'soilMoisture',
      'Soil moisture condition',
      ActivityFieldType.dropdown,
      options: ['Dry', 'Optimum', 'Wet'],
    ),
  ],
  ActivityCategory.nursery: [
    ActivityFieldDef('nurseryArea', 'Nursery area', ActivityFieldType.number, unitSuffix: 'sq.m'),
    ActivityFieldDef('seedQuantity', 'Seed quantity', ActivityFieldType.number, unitSuffix: 'kg'),
    ActivityFieldDef('expectedTransplantDate', 'Expected transplant date', ActivityFieldType.date),
  ],
  ActivityCategory.sowing: [
    ActivityFieldDef('crop', 'Crop', ActivityFieldType.text),
    ActivityFieldDef('variety', 'Variety', ActivityFieldType.text),
    ActivityFieldDef(
      'seedSource',
      'Seed source',
      ActivityFieldType.dropdown,
      options: ['Own', 'Purchased', 'Government'],
    ),
    ActivityFieldDef('seedRate', 'Seed rate', ActivityFieldType.number, unitSuffix: 'kg/acre'),
    ActivityFieldDef('rowSpacing', 'Row spacing', ActivityFieldType.number, unitSuffix: 'cm'),
    ActivityFieldDef('plantSpacing', 'Plant spacing', ActivityFieldType.number, unitSuffix: 'cm'),
    ActivityFieldDef('sowingDepth', 'Sowing depth', ActivityFieldType.number, unitSuffix: 'cm'),
    ActivityFieldDef('method', 'Method', ActivityFieldType.text),
    ActivityFieldDef('seedTreated', 'Seed treated', ActivityFieldType.boolean),
    ActivityFieldDef('seedTreatmentProduct', 'Seed treatment product', ActivityFieldType.text),
  ],
  ActivityCategory.irrigation: [
    ActivityFieldDef(
      'waterSource',
      'Water source',
      ActivityFieldType.dropdown,
      options: ['Canal', 'Borewell', 'Open well', 'Tank', 'Rain'],
    ),
    ActivityFieldDef(
      'irrigationMethod',
      'Method',
      ActivityFieldType.dropdown,
      options: ['Flood', 'Furrow', 'Sprinkler', 'Drip', 'AWD'],
    ),
    ActivityFieldDef('duration', 'Duration', ActivityFieldType.number, unitSuffix: 'hours'),
    ActivityFieldDef('pumpTypeHp', 'Pump type and HP', ActivityFieldType.text),
    ActivityFieldDef('depthApplied', 'Estimated depth applied', ActivityFieldType.number, unitSuffix: 'mm'),
    ActivityFieldDef(
      'powerSource',
      'Electricity or diesel used',
      ActivityFieldType.dropdown,
      options: ['Electricity', 'Diesel', 'None'],
    ),
  ],
  ActivityCategory.interculture: [
    ActivityFieldDef('operationType', 'Operation type', ActivityFieldType.text),
    ActivityFieldDef('plantsCovered', 'Plants covered', ActivityFieldType.number),
  ],
  ActivityCategory.harvest: [
    ActivityFieldDef('quantityHarvested', 'Quantity harvested', ActivityFieldType.number, unitSuffix: 'kg'),
    ActivityFieldDef('moistureContent', 'Moisture content', ActivityFieldType.number, unitSuffix: '%'),
    ActivityFieldDef('grade', 'Grade', ActivityFieldType.text),
    ActivityFieldDef('numberOfPickings', 'Number of pickings', ActivityFieldType.number),
    ActivityFieldDef('harvestMethod', 'Method', ActivityFieldType.text),
  ],
  ActivityCategory.postHarvest: [
    ActivityFieldDef('operationType', 'Operation type', ActivityFieldType.text),
    ActivityFieldDef('quantityHandled', 'Quantity handled', ActivityFieldType.number, unitSuffix: 'kg'),
    ActivityFieldDef('moistureIn', 'Moisture in', ActivityFieldType.number, unitSuffix: '%'),
    ActivityFieldDef('moistureOut', 'Moisture out', ActivityFieldType.number, unitSuffix: '%'),
    ActivityFieldDef('storageType', 'Storage type', ActivityFieldType.text),
    ActivityFieldDef('transportDistance', 'Transport distance', ActivityFieldType.number, unitSuffix: 'km'),
    ActivityFieldDef('buyer', 'Buyer', ActivityFieldType.text),
    ActivityFieldDef('price', 'Price', ActivityFieldType.number, unitSuffix: '₹'),
  ],
  ActivityCategory.residue: [
    ActivityFieldDef('residueQuantity', 'Residue quantity', ActivityFieldType.number, unitSuffix: 'quintals'),
    ActivityFieldDef(
      'disposalMethod',
      'Disposal method',
      ActivityFieldType.dropdown,
      options: ['Incorporated', 'Fodder', 'Sold', 'Mulch', 'Composting', 'Burnt'],
    ),
    ActivityFieldDef('buyer', 'Buyer (if sold)', ActivityFieldType.text),
    ActivityFieldDef('priceReceived', 'Price received (if sold)', ActivityFieldType.number, unitSuffix: '₹'),
  ],
};
