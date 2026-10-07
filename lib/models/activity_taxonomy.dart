/// Activity taxonomy — categories, sub-activities and default units.
///
/// Hardcoded for now (Flutter-side constants), but deliberately shaped the
/// way a future `activity_categories` / `activity_subtypes` master-table API
/// response would look — a flat list keyed by stable `code` values — so it
/// can be swapped for a live fetch later without touching call sites.
///
/// Codes are stable identifiers (never rename once shipped — historical
/// activity records reference them by code).
library;

/// The 12 top-level activity categories.
enum ActivityCategory {
  landPrep('LAND_PREP', 'Land preparation', 'भूमि तैयारी', '🚜'),
  nursery('NURSERY', 'Nursery', 'नर्सरी', '🌱'),
  sowing('SOWING', 'Sowing / planting', 'बुवाई / रोपाई', '🌾'),
  nutrient('NUTRIENT', 'Nutrient management', 'पोषण प्रबंधन', '🧪'),
  irrigation('IRRIGATION', 'Irrigation', 'सिंचाई', '💧'),
  weed('WEED', 'Weed management', 'खरपतवार नियंत्रण', '🌿'),
  plantProtect('PLANT_PROTECT', 'Pest & disease management', 'कीट व रोग नियंत्रण', '🛡️'),
  interculture('INTERCULTURE', 'Intercultural operations', 'अंतर-कृषि क्रिया', '🌻'),
  harvest('HARVEST', 'Harvest', 'कटाई', '🌾'),
  postHarvest('POST_HARVEST', 'Post-harvest', 'कटाई-उपरांत', '📦'),
  residue('RESIDUE', 'Residue management', 'अवशेष प्रबंधन', '🔥'),
  other('OTHER', 'Other', 'अन्य', '📋');

  const ActivityCategory(this.code, this.label, this.labelHi, this.emoji);

  final String code;
  final String label;
  final String labelHi;
  final String emoji;

  static ActivityCategory fromCode(String code) {
    return ActivityCategory.values.firstWhere(
      (c) => c.code == code,
      orElse: () => ActivityCategory.other,
    );
  }
}

/// A single sub-activity under a category (spec §4).
class ActivitySubtype {
  final String code;
  final String label;
  final String categoryCode;
  // TODO: add verified Hindi labels — the source spec's Hindi text arrived
  // corrupted (mojibake) and was not safe to copy verbatim.

  const ActivitySubtype(this.code, this.label, this.categoryCode);
}

/// Flat master list of all sub-activities, spec §4.
const List<ActivitySubtype> kActivitySubtypes = [
  // 1. LAND_PREP
  ActivitySubtype('LP_DEEP_PLOUGH', 'Deep ploughing', 'LAND_PREP'),
  ActivitySubtype('LP_MB_PLOUGH', 'MB plough', 'LAND_PREP'),
  ActivitySubtype('LP_CULTIVATOR', 'Cultivator / harrow', 'LAND_PREP'),
  ActivitySubtype('LP_ROTAVATOR', 'Rotavator', 'LAND_PREP'),
  ActivitySubtype('LP_DISC_HARROW', 'Disc harrow', 'LAND_PREP'),
  ActivitySubtype('LP_PUDDLING', 'Puddling (paddy)', 'LAND_PREP'),
  ActivitySubtype('LP_LEVELLING', 'Levelling / planking', 'LAND_PREP'),
  ActivitySubtype('LP_LASER_LEVEL', 'Laser levelling', 'LAND_PREP'),
  ActivitySubtype('LP_BUND_REPAIR', 'Bund making / repair', 'LAND_PREP'),
  ActivitySubtype('LP_RIDGE_FURROW', 'Ridge and furrow making', 'LAND_PREP'),
  ActivitySubtype('LP_BASAL_FYM', 'Basal FYM / compost spreading', 'LAND_PREP'),
  ActivitySubtype('LP_FIELD_CLEAN', 'Field clearing / stubble removal', 'LAND_PREP'),

  // 2. NURSERY
  ActivitySubtype('NR_BED_PREP', 'Nursery bed preparation', 'NURSERY'),
  ActivitySubtype('NR_SOWING', 'Nursery sowing', 'NURSERY'),
  ActivitySubtype('NR_IRRIGATION', 'Nursery irrigation', 'NURSERY'),
  ActivitySubtype('NR_NUTRIENT', 'Nursery fertiliser', 'NURSERY'),
  ActivitySubtype('NR_PLANT_PROTECT', 'Nursery plant protection', 'NURSERY'),
  ActivitySubtype('NR_UPROOTING', 'Seedling uprooting', 'NURSERY'),

  // 3. SOWING
  ActivitySubtype('SW_SEED_TREAT', 'Seed treatment', 'SOWING'),
  ActivitySubtype('SW_BROADCAST', 'Broadcasting', 'SOWING'),
  ActivitySubtype('SW_LINE_SOWING', 'Line sowing', 'SOWING'),
  ActivitySubtype('SW_SEED_DRILL', 'Seed drill', 'SOWING'),
  ActivitySubtype('SW_ZERO_TILL', 'Zero-till drill', 'SOWING'),
  ActivitySubtype('SW_DSR', 'Direct seeded rice', 'SOWING'),
  ActivitySubtype('SW_TRANSPLANT', 'Manual transplanting', 'SOWING'),
  ActivitySubtype('SW_MECH_TRANSPLANT', 'Machine transplanting', 'SOWING'),
  ActivitySubtype('SW_DIBBLING', 'Dibbling', 'SOWING'),
  ActivitySubtype('SW_SAPLING_PLANT', 'Sapling planting (perennial)', 'SOWING'),
  ActivitySubtype('SW_GAP_FILL', 'Gap filling / resowing', 'SOWING'),

  // 4. NUTRIENT
  ActivitySubtype('NU_BASAL', 'Basal dose', 'NUTRIENT'),
  ActivitySubtype('NU_TOPDRESS', 'Top dressing', 'NUTRIENT'),
  ActivitySubtype('NU_FYM', 'FYM / compost', 'NUTRIENT'),
  ActivitySubtype('NU_VERMICOMPOST', 'Vermicompost', 'NUTRIENT'),
  ActivitySubtype('NU_BIOCHAR', 'Biochar / biochar blend', 'NUTRIENT'),
  ActivitySubtype('NU_BIOFERT', 'Biofertiliser', 'NUTRIENT'),
  ActivitySubtype('NU_GREEN_MANURE', 'Green manuring', 'NUTRIENT'),
  ActivitySubtype('NU_MICRONUTRIENT', 'Micronutrient (Zn, Fe, B)', 'NUTRIENT'),
  ActivitySubtype('NU_FOLIAR', 'Foliar spray', 'NUTRIENT'),
  ActivitySubtype('NU_FERTIGATION', 'Fertigation through drip', 'NUTRIENT'),
  ActivitySubtype('NU_JEEVAMRIT', 'Jeevamrit / natural input', 'NUTRIENT'),

  // 5. IRRIGATION
  ActivitySubtype('IR_FLOOD', 'Flood irrigation', 'IRRIGATION'),
  ActivitySubtype('IR_FURROW', 'Furrow irrigation', 'IRRIGATION'),
  ActivitySubtype('IR_SPRINKLER', 'Sprinkler', 'IRRIGATION'),
  ActivitySubtype('IR_DRIP', 'Drip', 'IRRIGATION'),
  ActivitySubtype('IR_AWD', 'AWD cycle irrigation', 'IRRIGATION'),
  ActivitySubtype('IR_DRAINAGE', 'Drainage / water release', 'IRRIGATION'),
  ActivitySubtype('IR_SYSTEM_MAINT', 'System maintenance', 'IRRIGATION'),

  // 6. WEED
  ActivitySubtype('WD_MANUAL', 'Manual weeding', 'WEED'),
  ActivitySubtype('WD_KHURPI', 'Khurpi / hand hoe', 'WEED'),
  ActivitySubtype('WD_CONO_WEEDER', 'Cono weeder / rotary weeder', 'WEED'),
  ActivitySubtype('WD_MECH', 'Tractor / power weeder', 'WEED'),
  ActivitySubtype('WD_PRE_EMERGENCE', 'Pre-emergence herbicide', 'WEED'),
  ActivitySubtype('WD_POST_EMERGENCE', 'Post-emergence herbicide', 'WEED'),
  ActivitySubtype('WD_MULCHING', 'Mulching', 'WEED'),

  // 7. PLANT_PROTECT
  ActivitySubtype('PP_SCOUTING', 'Scouting / observation', 'PLANT_PROTECT'),
  ActivitySubtype('PP_INSECTICIDE', 'Insecticide spray', 'PLANT_PROTECT'),
  ActivitySubtype('PP_FUNGICIDE', 'Fungicide spray', 'PLANT_PROTECT'),
  ActivitySubtype('PP_BIO_PESTICIDE', 'Bio-pesticide / neem', 'PLANT_PROTECT'),
  ActivitySubtype('PP_TRAP', 'Pheromone / light / sticky trap', 'PLANT_PROTECT'),
  ActivitySubtype('PP_BIO_CONTROL', 'Biological control release', 'PLANT_PROTECT'),
  ActivitySubtype('PP_RODENT', 'Rodent control', 'PLANT_PROTECT'),
  ActivitySubtype('PP_GRANULAR', 'Granular application', 'PLANT_PROTECT'),
  ActivitySubtype('PP_SEED_DRESS', 'Seed dressing (protection)', 'PLANT_PROTECT'),

  // 8. INTERCULTURE
  ActivitySubtype('IC_EARTHING', 'Earthing up', 'INTERCULTURE'),
  ActivitySubtype('IC_THINNING', 'Thinning', 'INTERCULTURE'),
  ActivitySubtype('IC_PRUNING', 'Pruning', 'INTERCULTURE'),
  ActivitySubtype('IC_TRAINING', 'Training / staking', 'INTERCULTURE'),
  ActivitySubtype('IC_NIPPING', 'Nipping / topping', 'INTERCULTURE'),
  ActivitySubtype('IC_PROP_UP', 'Propping', 'INTERCULTURE'),

  // 9. HARVEST
  ActivitySubtype('HV_MANUAL', 'Manual harvesting', 'HARVEST'),
  ActivitySubtype('HV_REAPER', 'Reaper harvesting', 'HARVEST'),
  ActivitySubtype('HV_COMBINE', 'Combine harvester', 'HARVEST'),
  ActivitySubtype('HV_PICKING', 'Picking (multiple rounds)', 'HARVEST'),
  ActivitySubtype('HV_UPROOTING', 'Uprooting (groundnut etc.)', 'HARVEST'),
  ActivitySubtype('HV_CUTTING_FODDER', 'Fodder cutting', 'HARVEST'),

  // 10. POST_HARVEST
  ActivitySubtype('PH_THRESHING', 'Threshing', 'POST_HARVEST'),
  ActivitySubtype('PH_WINNOWING', 'Winnowing', 'POST_HARVEST'),
  ActivitySubtype('PH_DRYING', 'Drying', 'POST_HARVEST'),
  ActivitySubtype('PH_CLEANING', 'Cleaning / grading', 'POST_HARVEST'),
  ActivitySubtype('PH_PACKING', 'Bagging / packing', 'POST_HARVEST'),
  ActivitySubtype('PH_TRANSPORT', 'Transport to market / store', 'POST_HARVEST'),
  ActivitySubtype('PH_STORAGE', 'Storage', 'POST_HARVEST'),
  ActivitySubtype('PH_SALE', 'Sale / marketing', 'POST_HARVEST'),

  // 11. RESIDUE
  ActivitySubtype('RS_INCORPORATE', 'Incorporated into soil', 'RESIDUE'),
  ActivitySubtype('RS_FODDER', 'Removed as fodder', 'RESIDUE'),
  ActivitySubtype('RS_SOLD', 'Sold off-farm', 'RESIDUE'),
  ActivitySubtype('RS_MULCH', 'Left as mulch', 'RESIDUE'),
  ActivitySubtype('RS_COMPOST', 'Taken for composting', 'RESIDUE'),
  ActivitySubtype('RS_BURNT', 'Burnt in field', 'RESIDUE'),

  // 12. OTHER
  ActivitySubtype('OT_FENCING', 'Fencing / boundary work', 'OTHER'),
  ActivitySubtype('OT_BIRD_SCARE', 'Bird / animal scaring', 'OTHER'),
  ActivitySubtype('OT_SOIL_SAMPLE', 'Soil sampling', 'OTHER'),
  ActivitySubtype('OT_TRAINING', 'Training / demonstration attended', 'OTHER'),
  ActivitySubtype('OT_OTHER', 'Other (specify)', 'OTHER'),
];

/// Sub-activities belonging to a given category, in seed order.
List<ActivitySubtype> subtypesFor(ActivityCategory category) {
  return kActivitySubtypes
      .where((s) => s.categoryCode == category.code)
      .toList(growable: false);
}

/// Look up a subtype by its code, if it exists.
ActivitySubtype? subtypeByCode(String? code) {
  if (code == null) return null;
  for (final s in kActivitySubtypes) {
    if (s.code == code) return s;
  }
  return null;
}

/// Default unit choices offered on the cost/quantity step, per category.
/// A starting default, not a restriction — same spirit as spec §6.1.
const Map<ActivityCategory, List<String>> kUnitsByCategory = {
  ActivityCategory.landPrep: ['hours', 'acres', 'passes'],
  ActivityCategory.nursery: ['sq.m', 'kg', 'seedlings'],
  ActivityCategory.sowing: ['kg', 'packets', 'seedlings', 'acres'],
  ActivityCategory.nutrient: ['kg', 'bags', 'liters'],
  ActivityCategory.irrigation: ['liters', 'hours', 'mm'],
  ActivityCategory.weed: ['hours', 'laborers', 'liters'],
  ActivityCategory.plantProtect: ['ml', 'liters', 'grams'],
  ActivityCategory.interculture: ['hours', 'laborers'],
  ActivityCategory.harvest: ['kg', 'quintals', 'tons'],
  ActivityCategory.postHarvest: ['kg', 'quintals', 'bags'],
  ActivityCategory.residue: ['quintals', 'kg'],
  ActivityCategory.other: ['units'],
};
