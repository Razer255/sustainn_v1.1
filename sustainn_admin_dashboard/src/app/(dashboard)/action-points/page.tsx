import { getUsers, getActionPoints } from '@/lib/backend';
import NewActionPointForm from './NewActionPointForm';
import ActionPointsList from './ActionPointsList';

export default async function ActionPointsPage() {
  const [users, actionPoints] = await Promise.all([getUsers(), getActionPoints()]);

  return (
    <div>
      <h1 className="mb-1 text-2xl font-semibold text-gray-900">Action Points</h1>
      <p className="mb-6 text-sm text-gray-500">
        Every action point sent so far, and whether the farmer has marked it
        resolved. New ones are still created by hand below — automatic
        computation (weather alerts, due-date reminders, etc.) isn&apos;t built yet.
      </p>
      <ActionPointsList actionPoints={actionPoints} />
      <h2 className="mb-3 text-lg font-semibold text-gray-900">Create new</h2>
      <NewActionPointForm users={users} />
    </div>
  );
}
