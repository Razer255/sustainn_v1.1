/// Small master lists supporting the conditional-fields UI (spec §7).
/// Hardcoded seed sets for now — a subset of what a real `input_items`
/// master table (spec §7.2) would hold, enough to drive the NUTRIENT
/// product-row picker and its live NPK summary.
library;

/// A fertiliser/organic input item with nutrient content (spec §7.2).
class InputItem {
  final String code;
  final String name;
  final String defaultUnit;
  final double nPct;
  final double p2o5Pct;
  final double k2oPct;

  const InputItem(
    this.code,
    this.name,
    this.defaultUnit, {
    this.nPct = 0,
    this.p2o5Pct = 0,
    this.k2oPct = 0,
  });
}

/// Minimum seed set from spec §7.2.
const List<InputItem> kInputItems = [
  InputItem('UREA', 'Urea (46-0-0)', 'kg', nPct: 46),
  InputItem('DAP', 'DAP (18-46-0)', 'kg', nPct: 18, p2o5Pct: 46),
  InputItem('MOP', 'MOP (0-0-60)', 'kg', k2oPct: 60),
  InputItem('SSP', 'SSP (0-16-0)', 'kg', p2o5Pct: 16),
  InputItem('NPK_12_32_16', 'NPK 12:32:16', 'kg', nPct: 12, p2o5Pct: 32, k2oPct: 16),
  InputItem('NPK_10_26_26', 'NPK 10:26:26', 'kg', nPct: 10, p2o5Pct: 26, k2oPct: 26),
  InputItem('AMMONIUM_SULPHATE', 'Ammonium sulphate (21-0-0)', 'kg', nPct: 21),
  InputItem('ZINC_SULPHATE', 'Zinc sulphate', 'kg'),
  InputItem('FERROUS_SULPHATE', 'Ferrous sulphate', 'kg'),
  InputItem('BORAX', 'Borax', 'kg'),
  InputItem('FYM', 'FYM', 'kg'),
  InputItem('VERMICOMPOST', 'Vermicompost', 'kg'),
];

InputItem? inputItemByCode(String? code) {
  if (code == null) return null;
  for (final item in kInputItems) {
    if (item.code == code) return item;
  }
  return null;
}

/// Local weed names for the WEED category's multi-select (spec §7.4).
const List<String> kWeedSpecies = [
  'Motha',
  'Doob',
  'Bathua',
  'Chaulai',
  'Jangli chaulai',
  'Kaans',
];

/// Common pest/disease names for the PLANT_PROTECT category's multi-select
/// (spec §7.4). Not yet crop-filtered — see plan notes.
const List<String> kPestsDiseases = [
  'Stem borer',
  'Leaf folder',
  'Aphid',
  'Whitefly',
  'Bollworm',
  'Blast',
  'Blight',
  'Rust',
  'Wilt',
  'Powdery mildew',
];
