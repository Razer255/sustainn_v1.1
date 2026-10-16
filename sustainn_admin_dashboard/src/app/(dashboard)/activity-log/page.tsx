import { getActivityLog } from '@/lib/backend';
import ActivityLog from './ActivityLog';

export default async function ActivityLogPage() {
  const entries = await getActivityLog();

  return (
    <div>
      <h1 className="mb-1 text-2xl font-semibold text-gray-900">Activity Log</h1>
      <p className="mb-6 text-sm text-gray-500">
        Every farming activity logged across all farmers, most recent first.
      </p>
      <ActivityLog entries={entries} />
    </div>
  );
}
