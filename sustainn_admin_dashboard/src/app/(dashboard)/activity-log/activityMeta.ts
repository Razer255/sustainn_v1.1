// Mirrors lib/models/activity_taxonomy.dart's ActivityCategory so the admin
// dashboard renders the same emoji/labels/colors as the farmer app.
export const activityMeta: Record<string, { label: string; emoji: string; color: string }> = {
  LAND_PREP: { label: 'Land preparation', emoji: '🚜', color: '#8d6e63' },
  NURSERY: { label: 'Nursery', emoji: '🌱', color: '#689f38' },
  SOWING: { label: 'Sowing / planting', emoji: '🌾', color: '#00897b' },
  NUTRIENT: { label: 'Nutrient management', emoji: '🧪', color: '#1cba6f' },
  IRRIGATION: { label: 'Irrigation', emoji: '💧', color: '#1e88e5' },
  WEED: { label: 'Weed management', emoji: '🌿', color: '#388e3c' },
  PLANT_PROTECT: { label: 'Pest & disease management', emoji: '🛡️', color: '#fb8c00' },
  INTERCULTURE: { label: 'Intercultural operations', emoji: '🌻', color: '#3949ab' },
  HARVEST: { label: 'Harvest', emoji: '🌾', color: '#ffa000' },
  POST_HARVEST: { label: 'Post-harvest', emoji: '📦', color: '#e64a19' },
  RESIDUE: { label: 'Residue management', emoji: '🔥', color: '#a1887f' },
  OTHER: { label: 'Other', emoji: '📋', color: '#757575' },
};

export function metaFor(type: string) {
  return activityMeta[type] ?? { label: type, emoji: '📋', color: '#757575' };
}
