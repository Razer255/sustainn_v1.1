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

export type AdminActivity = {
  id: string;
  cropId: string;
  type: string;
  subtype?: string;
  date: string;
  areaCovered?: number;
  areaUnit?: string;
  notes?: string;
  cost?: number;
  quantity?: number;
  unit?: string;
  createdBy: string;
};

export type AdminActivityLogEntry = {
  id: string;
  cropId: string;
  type: string;
  subtype?: string;
  date: string;
  areaCovered?: number;
  areaUnit?: string;
  notes?: string;
  cost?: number;
  quantity?: number;
  unit?: string;
  createdBy: string;
  attributes?: Record<string, unknown>;
  cropName: string | null;
  cropVariety: string | null;
  cropSeason: string | null;
  fieldId: string | null;
  fieldName: string | null;
  fieldArea: number | null;
  fieldSoilType: string | null;
  ownerId: string | null;
  ownerName: string | null;
  ownerPhone: string | null;
  cropInputCost: number | null;
  cropExpectedRevenue: number | null;
  cropActualRevenue: number | null;
};

export type AdminFinancial = {
  id: string;
  cropId: string;
  inputCost: number;
  expectedRevenue: number;
  actualRevenue: number;
  updatedAt: string;
};

export type AdminUserDetail = {
  user: AdminUser;
  fields: AdminField[];
  crops: AdminCrop[];
  activities: AdminActivity[];
  financials: AdminFinancial[];
};

export type AdminStats = {
  userCount: number;
  fieldCount: number;
  cropCount: number;
  activityCount: number;
  openActionPointCount: number;
  openIssueReportCount: number;
};

export type IssueReport = {
  id: string;
  userId: string;
  userName: string;
  userPhone: string;
  message: string;
  status: 'open' | 'resolved';
  createdAt: string;
};

async function fetchFromBackend<T>(path: string, init?: RequestInit): Promise<T> {
  if (!BACKEND_URL || !ADMIN_API_KEY) {
    throw new Error('BACKEND_URL or ADMIN_API_KEY is not configured');
  }
  const res = await fetch(`${BACKEND_URL}${path}`, {
    ...init,
    headers: { 'x-admin-key': ADMIN_API_KEY, ...(init?.headers ?? {}) },
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
export const getActivityLog = () =>
  fetchFromBackend<AdminActivityLogEntry[]>('/api/admin/activities');
export const getUserDetail = (userId: string) =>
  fetchFromBackend<AdminUserDetail>(`/api/admin/users/${userId}/detail`);
export const getIssueReports = () => fetchFromBackend<IssueReport[]>('/api/admin/issue-reports');

export const resolveIssueReport = (id: string) =>
  fetchFromBackend(`/api/admin/issue-reports/${id}/resolve`, { method: 'PUT' });

export const deleteIssueReport = (id: string) =>
  fetchFromBackend(`/api/admin/issue-reports/${id}`, { method: 'DELETE' });

export type NewActionPoint = {
  scope: 'farmer' | 'field' | 'crop';
  refId: string;
  message: string;
  priority: 'high' | 'medium' | 'low';
  dueDate?: string;
  category?: string;
};

export const createActionPoint = (data: NewActionPoint) =>
  fetchFromBackend<{ id: string }>('/api/admin/action-points', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });

export type AdminActionPoint = {
  id: string;
  scope: 'farmer' | 'field' | 'crop';
  refId: string;
  message: string;
  priority: string;
  dueDate: string | null;
  category?: string;
  resolved: boolean;
  createdAt: string;
  ownerId: string | null;
  ownerName: string | null;
  fieldName: string | null;
  cropName: string | null;
};

export const getActionPoints = () =>
  fetchFromBackend<AdminActionPoint[]>('/api/admin/action-points');
