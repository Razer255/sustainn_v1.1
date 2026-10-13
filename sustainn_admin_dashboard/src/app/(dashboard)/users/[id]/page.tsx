import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getUserDetail } from '@/lib/backend';

const healthColor: Record<string, string> = {
  good: 'bg-green-100 text-green-700',
  moderate: 'bg-yellow-100 text-yellow-700',
  poor: 'bg-red-100 text-red-700',
};

export default async function UserDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  let detail;
  try {
    detail = await getUserDetail(id);
  } catch {
    notFound();
  }

  const { user, fields, crops, activities, financials } = detail;

  return (
    <div>
      <Link href="/users" className="mb-4 inline-block text-sm text-gray-500 hover:text-gray-900">
        ← Back to Users
      </Link>

      <div className="mb-6 rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
        <h1 className="text-2xl font-semibold text-gray-900">{user.name}</h1>
        <p className="mt-1 text-sm text-gray-500">
          {user.phone} · {user.guardianName ? `${user.guardianName} · ` : ''}
          {user.region}
        </p>
        <p className="mt-1 text-xs text-gray-400">
          Language: {user.language} · Joined {new Date(user.createdAt).toLocaleDateString()}
        </p>
      </div>

      <div className="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
        {[
          { label: 'Fields', value: fields.length },
          { label: 'Crops', value: crops.length },
          { label: 'Activities', value: activities.length },
          {
            label: 'Total input cost',
            value: `₹${financials.reduce((sum, f) => sum + f.inputCost, 0).toLocaleString()}`,
          },
        ].map((card) => (
          <div key={card.label} className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
            <p className="text-xs text-gray-500">{card.label}</p>
            <p className="mt-1 text-xl font-semibold text-gray-900">{card.value}</p>
          </div>
        ))}
      </div>

      <h2 className="mb-3 text-lg font-semibold text-gray-900">Fields</h2>
      {fields.length === 0 ? (
        <p className="mb-6 text-sm text-gray-500">No fields added yet.</p>
      ) : (
        <div className="mb-8 space-y-4">
          {fields.map((field) => {
            const fieldCrops = crops.filter((c) => c.fieldId === field.id);
            return (
              <div key={field.id} className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
                <div className="mb-3 flex items-start justify-between">
                  <div>
                    <p className="font-medium text-gray-900">{field.name}</p>
                    <p className="text-xs text-gray-500">
                      {field.area} acres · {field.soilType}
                      {field.latitude && field.longitude && (
                        <>
                          {' · '}
                          <a
                            href={`https://www.google.com/maps?q=${field.latitude},${field.longitude}`}
                            target="_blank"
                            rel="noreferrer"
                            className="text-blue-600 hover:underline"
                          >
                            View on map
                          </a>
                        </>
                      )}
                    </p>
                  </div>
                  <span
                    className={`rounded-full px-2 py-1 text-xs font-medium ${
                      healthColor[field.healthStatus] ?? 'bg-gray-100 text-gray-700'
                    }`}
                  >
                    {field.healthStatus}
                  </span>
                </div>

                {fieldCrops.length === 0 ? (
                  <p className="text-xs text-gray-400">No crops on this field.</p>
                ) : (
                  <div className="space-y-3 border-t border-gray-100 pt-3">
                    {fieldCrops.map((crop) => {
                      const cropActivities = activities.filter((a) => a.cropId === crop.id);
                      const cropFinancial = financials.find((f) => f.cropId === crop.id);
                      return (
                        <div key={crop.id} className="rounded-lg bg-gray-50 p-3">
                          <div className="mb-2 flex items-start justify-between">
                            <div>
                              <p className="text-sm font-medium text-gray-900">
                                {crop.cropName} <span className="text-gray-400">· {crop.variety}</span>
                              </p>
                              <p className="text-xs text-gray-500">
                                {crop.season} · sown {new Date(crop.sownDate).toLocaleDateString()}
                                {crop.expectedHarvestDate &&
                                  ` · harvest ${new Date(crop.expectedHarvestDate).toLocaleDateString()}`}
                              </p>
                            </div>
                            <span
                              className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                                healthColor[crop.healthStatus] ?? 'bg-gray-100 text-gray-700'
                              }`}
                            >
                              {crop.status}
                            </span>
                          </div>

                          {cropFinancial && (
                            <p className="mb-2 text-xs text-gray-600">
                              Input cost: ₹{cropFinancial.inputCost.toLocaleString()} · Expected
                              revenue: ₹{cropFinancial.expectedRevenue.toLocaleString()}
                            </p>
                          )}

                          {cropActivities.length === 0 ? (
                            <p className="text-xs text-gray-400">No activities logged.</p>
                          ) : (
                            <ul className="space-y-1">
                              {cropActivities.map((a) => (
                                <li key={a.id} className="flex justify-between text-xs text-gray-600">
                                  <span>
                                    {a.type}
                                    {a.subtype ? ` · ${a.subtype}` : ''}
                                    {a.notes ? ` — ${a.notes}` : ''}
                                  </span>
                                  <span className="shrink-0 text-gray-400">
                                    {new Date(a.date).toLocaleDateString()}
                                    {a.cost ? ` · ₹${a.cost.toLocaleString()}` : ''}
                                  </span>
                                </li>
                              ))}
                            </ul>
                          )}
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
