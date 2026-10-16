import Link from 'next/link';
import { getFields, getUsers } from '@/lib/backend';

const healthColor: Record<string, string> = {
  good: 'bg-green-100 text-green-700',
  moderate: 'bg-yellow-100 text-yellow-700',
  poor: 'bg-red-100 text-red-700',
};

export default async function FieldsPage() {
  const [fields, users] = await Promise.all([getFields(), getUsers()]);
  const userById = new Map(users.map((u) => [u.id, u]));

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-gray-900">Fields ({fields.length})</h1>
      <div className="overflow-x-auto rounded-xl border border-gray-200 bg-white shadow-sm">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-gray-200 bg-gray-50 text-xs uppercase text-gray-500">
            <tr>
              <th className="px-4 py-3">Name</th>
              <th className="px-4 py-3">Owner</th>
              <th className="px-4 py-3">Area (acres)</th>
              <th className="px-4 py-3">Soil</th>
              <th className="px-4 py-3">Health</th>
              <th className="px-4 py-3">Active crops</th>
              <th className="px-4 py-3">Pending actions</th>
              <th className="px-4 py-3">Location</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {fields.map((f) => {
              const owner = userById.get(f.ownerId);
              return (
              <tr key={f.id}>
                <td className="px-4 py-3 font-medium text-gray-900">{f.name}</td>
                <td className="px-4 py-3 text-gray-600">
                  {owner ? (
                    <Link href={`/users/${f.ownerId}`} className="text-blue-600 hover:underline">
                      {owner.name}
                    </Link>
                  ) : (
                    <span className="text-gray-400">Unknown owner</span>
                  )}
                </td>
                <td className="px-4 py-3 text-gray-600">{f.area}</td>
                <td className="px-4 py-3 text-gray-600">{f.soilType}</td>
                <td className="px-4 py-3">
                  <span
                    className={`rounded-full px-2 py-1 text-xs font-medium ${
                      healthColor[f.healthStatus] ?? 'bg-gray-100 text-gray-700'
                    }`}
                  >
                    {f.healthStatus}
                  </span>
                </td>
                <td className="px-4 py-3 text-gray-600">{f.activeCrops}</td>
                <td className="px-4 py-3 text-gray-600">{f.pendingActions}</td>
                <td className="px-4 py-3 text-gray-600">
                  {f.latitude && f.longitude ? (
                    <a
                      href={`https://www.google.com/maps?q=${f.latitude},${f.longitude}`}
                      target="_blank"
                      rel="noreferrer"
                      className="text-blue-600 hover:underline"
                    >
                      View on map
                    </a>
                  ) : (
                    '—'
                  )}
                </td>
              </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
