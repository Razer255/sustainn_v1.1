import { getUsers } from '@/lib/backend';
import NewActionPointForm from './NewActionPointForm';

export default async function ActionPointsPage() {
  const users = await getUsers();

  return (
    <div>
      <h1 className="mb-1 text-2xl font-semibold text-gray-900">Action Points</h1>
      <p className="mb-6 text-sm text-gray-500">
        Manually create an action point for a farmer, field, or crop. Automatic
        computation (weather alerts, due-date reminders, etc.) isn&apos;t built yet —
        this is the static, by-hand path for now.
      </p>
      <NewActionPointForm users={users} />
    </div>
  );
}
