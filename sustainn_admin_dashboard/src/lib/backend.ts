const BACKEND_URL = process.env.BACKEND_URL;
const ADMIN_API_KEY = process.env.ADMIN_API_KEY;

export type AdminUser = {
  id: string;
  phone: string;
  name: string;
  guardianName?: string;
  language: string;
  region: string;
  createdAt: string;
};

export type AdminField = {
  id: string;
  ownerId: string;
  name: string;
  area: number;
  latitude?: number;
  longitude?: number;
  boundaryPoints: { lat: number; lng: number }[];
  soilType: string;
  healthStatus: string;
  activeCrops: number;
  pendingActions: number;
  createdAt: string;
};

export type AdminCrop = {
  id: string;
  fieldId: string;
  season: string;
  cropName: string;
  variety: string;
  sownDate: string;
  expectedHarvestDate: string | null;
  status: string;
  isIntercrop: boolean;
  areaCovered?: number;
  healthStatus: string;
  activityCount: number;
};

export type AdminStats = {
  userCount: number;
  fieldCount: number;
  cropCount: number;
  activityCount: number;
  openActionPointCount: number;
};

async function fetchFromBackend<T>(path: string): Promise<T> {
  if (!BACKEND_URL || !ADMIN_API_KEY) {
    throw new Error('BACKEND_URL or ADMIN_API_KEY is not configured');
  }
  const res = await fetch(`${BACKEND_URL}${path}`, {
    headers: { 'x-admin-key': ADMIN_API_KEY },
    cache: 'no-store',
  });
  if (!res.ok) {
    throw new Error(`Backend request failed (${res.status}): ${path}`);
  }
  return res.json();
}

export const getStats = () => fetchFromBackend<AdminStats>('/api/admin/stats');
export const getUsers = () => fetchFromBackend<AdminUser[]>('/api/admin/users');
export const getFields = () => fetchFromBackend<AdminField[]>('/api/admin/fields');
export const getCrops = () => fetchFromBackend<AdminCrop[]>('/api/admin/crops');
